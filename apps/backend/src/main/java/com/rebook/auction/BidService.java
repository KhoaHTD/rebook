package com.rebook.auction;

import com.rebook.auction.AuctionDtos.BidResponse;
import com.rebook.common.ApiException;
import com.rebook.consignment.ConsignmentRepository;
import com.rebook.notification.NotificationService;
import com.rebook.user.User;
import com.rebook.user.UserService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * Xử lý lượt trả giá. Đồng hồ và giá luôn do server quyết định.
 * <p>
 * Kiểm tra (mục 6.5): đã đăng ký + cọc hợp lệ; lô đang mở; giá ≥ giá hiện tại + bước giá;
 * không tự đẩy giá của mình; tổng giá đang giữ + lượt này ≤ hạn mức. Hai người cùng bấm một mức giá
 * thì ai tới server trước thắng (UPDATE ... WHERE version = :v), người sau nhận lỗi "Giá đã thay đổi".
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BidService {

    private final LotRepository lotRepository;
    private final AuctionSessionRepository sessionRepository;
    private final AuctionRegistrationRepository registrationRepository;
    private final BidRepository bidRepository;
    private final ProxyBidRepository proxyRepository;
    private final ConsignmentRepository consignmentRepository;
    private final UserService userService;
    private final AuctionViews views;
    private final NotificationService notifications;
    private final EntityManager em;

    @Transactional
    public BidResponse placeBid(Long userId, Long lotId, BigDecimal amount) {
        Lot lot = lotRepository.findById(lotId).orElseThrow(() -> ApiException.notFound("lô"));
        AuctionSession session = requireLiveSession(lot);
        AuctionRegistration reg = requireBidder(userId, lot, session);
        Instant now = Instant.now();
        if (lot.getStatus() != LotStatus.OPEN || lot.getEndsAt() == null || !lot.getEndsAt().isAfter(now)) {
            throw ApiException.conflict("LOT_NOT_OPEN", "Lô không còn nhận trả giá");
        }
        if (userId.equals(lot.getCurrentWinnerId())) {
            throw ApiException.conflict("ALREADY_LEADING", "Bạn đang giữ giá cao nhất");
        }
        BigDecimal min = views.nextMinBid(lot);
        if (amount.compareTo(min) < 0) {
            throw ApiException.conflict("PRICE_CHANGED", "Giá đã thay đổi, mức tối thiểu hiện tại là " + min.toPlainString() + "đ");
        }
        checkLimit(reg, amount);

        Long previousWinner = lot.getCurrentWinnerId();
        Instant softEnd = now.plus(Duration.ofSeconds(session.getSoftCloseSec()));
        int updated = lotRepository.applyBid(lotId, lot.getVersion(), amount, userId, softEnd, now);
        if (updated == 0) {
            throw ApiException.conflict("PRICE_CHANGED", "Giá đã thay đổi, vui lòng thử lại");
        }
        saveBid(lotId, userId, reg.getId(), amount, false);

        // Đọc lại lô (đã đổi bằng câu UPDATE) và khoá để chạy trả giá uỷ quyền
        em.refresh(lot, LockModeType.PESSIMISTIC_WRITE);
        Set<Long> outbid = new HashSet<>();
        if (previousWinner != null) {
            outbid.add(previousWinner);
        }
        resolveProxies(lot, session, outbid);
        afterPriceChange(lot, session, outbid);
        return new BidResponse(views.lotLive(lot, views.paddles(session.getId())),
                userId.equals(lot.getCurrentWinnerId()), views.registration(reg, lot));
    }

    /** Đặt / sửa giá tối đa (proxy). Đặt trước khi lô mở = trả giá vắng mặt (absentee). */
    @Transactional
    public BigDecimal setProxy(Long userId, Long lotId, BigDecimal maxAmount) {
        Lot lot = lotRepository.lockById(lotId).orElseThrow(() -> ApiException.notFound("lô"));
        if (lot.getStatus() != LotStatus.SCHEDULED && lot.getStatus() != LotStatus.OPEN) {
            throw ApiException.conflict("LOT_NOT_OPEN", "Lô không nhận đặt giá tối đa");
        }
        AuctionSession session = sessionRepository.findById(lot.getSessionId()).orElseThrow();
        if (session.getStatus() == SessionStatus.DRAFT || session.getStatus() == SessionStatus.ENDED
                || session.getStatus() == SessionStatus.CANCELLED) {
            throw ApiException.conflict("SESSION_NOT_ACTIVE", "Phiên không còn hoạt động");
        }
        AuctionRegistration reg = requireBidder(userId, lot, session);
        BigDecimal min = views.nextMinBid(lot);
        if (maxAmount.compareTo(min) < 0) {
            throw ApiException.badRequest("PROXY_TOO_LOW", "Giá tối đa phải từ " + min.toPlainString() + "đ");
        }
        checkLimit(reg, maxAmount);

        ProxyBid proxy = proxyRepository.findByLotIdAndUserId(lotId, userId).orElseGet(() -> {
            ProxyBid p = new ProxyBid();
            p.setLotId(lotId);
            p.setUserId(userId);
            return p;
        });
        proxy.setMaxAmount(maxAmount);
        proxy.setActive(true);
        proxyRepository.saveAndFlush(proxy);

        if (lot.getStatus() == LotStatus.OPEN && session.getStatus() == SessionStatus.LIVE) {
            Set<Long> outbid = new HashSet<>();
            Long before = lot.getCurrentWinnerId();
            if (before != null) {
                outbid.add(before);
            }
            int bidsBefore = lot.getBidCount();
            resolveProxies(lot, session, outbid);
            if (lot.getBidCount() != bidsBefore) {
                afterPriceChange(lot, session, outbid);
            }
        }
        return maxAmount;
    }

    @Transactional
    public void cancelProxy(Long userId, Long lotId) {
        proxyRepository.findByLotIdAndUserId(lotId, userId).ifPresent(p -> p.setActive(false));
    }

    public Optional<BigDecimal> myProxy(Long userId, Long lotId) {
        return proxyRepository.findByLotIdAndUserId(lotId, userId).filter(ProxyBid::isActive).map(ProxyBid::getMaxAmount);
    }

    /**
     * Trả giá uỷ quyền: lặp cho tới khi không còn proxy nào vượt được người đang dẫn.
     * Hai proxy cạnh tranh thì nhảy thẳng tới mức "giá tối đa của bên thua + 1 bước" thay vì tăng từng bước.
     * Bằng giá tối đa thì người đang dẫn (đặt trước) giữ giá.
     *
     * @param lot đã được khoá FOR UPDATE và là entity đang quản lý
     */
    public void resolveProxies(Lot lot, AuctionSession session, Set<Long> outbid) {
        for (int guard = 0; guard < 50; guard++) {
            List<ProxyBid> proxies = proxyRepository.findByLotIdAndActiveTrueOrderByMaxAmountDescCreatedAtAsc(lot.getId());
            Long winner = lot.getCurrentWinnerId();
            BigDecimal nextMin = views.nextMinBid(lot);

            ProxyBid challenger = null;
            BigDecimal cMax = null;
            for (ProxyBid p : proxies) {
                if (p.getUserId().equals(winner)) {
                    continue;
                }
                BigDecimal eff = effectiveMax(p, lot, session);
                if (eff.compareTo(nextMin) >= 0) {
                    challenger = p;
                    cMax = eff;
                    break;
                }
                p.setActive(false); // không còn vượt được mức tối thiểu → hết hiệu lực
            }
            if (challenger == null) {
                return;
            }
            ProxyBid winnerProxy = winner == null ? null
                    : proxies.stream().filter(p -> p.getUserId().equals(winner)).findFirst().orElse(null);
            BigDecimal price = lot.getCurrentPrice() == null ? BigDecimal.ZERO : lot.getCurrentPrice();
            BigDecimal wMax = winnerProxy == null ? price : effectiveMax(winnerProxy, lot, session).max(price);

            if (winner != null && wMax.compareTo(cMax) >= 0) {
                // Người đang dẫn giữ giá; proxy thách đấu cạn ở cMax
                if (wMax.compareTo(cMax) == 0) {
                    autoBid(lot, session, winner, cMax, true); // bằng giá tối đa: người đặt trước giữ giá ở mức này
                } else {
                    autoBid(lot, session, challenger.getUserId(), cMax);
                    BigDecimal answer = cMax.add(views.increment(cMax)).min(wMax);
                    autoBid(lot, session, winner, answer, true);
                }
                outbid.add(challenger.getUserId());
                challenger.setActive(false);
            } else {
                // Proxy thách đấu vượt lên
                if (winnerProxy != null && wMax.compareTo(price) > 0 && wMax.compareTo(nextMin) >= 0) {
                    autoBid(lot, session, winner, wMax);
                }
                if (winnerProxy != null) {
                    winnerProxy.setActive(false);
                }
                BigDecimal target = winner == null ? nextMin
                        : wMax.add(views.increment(wMax)).min(cMax).max(views.nextMinBid(lot));
                if (target.compareTo(cMax) > 0) {
                    target = cMax;
                }
                if (winner != null) {
                    outbid.add(winner);
                }
                autoBid(lot, session, challenger.getUserId(), target);
            }
        }
        log.warn("Proxy resolution dừng sau 50 vòng ở lô {}", lot.getId());
    }

    /** Giá tối đa thực tế của proxy, không vượt hạn mức còn lại của người dùng. */
    private BigDecimal effectiveMax(ProxyBid p, Lot lot, AuctionSession session) {
        return registrationRepository.findBySessionIdAndUserId(session.getId(), p.getUserId())
                .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                .map(r -> p.getMaxAmount().min(r.getBidLimit().subtract(lotRepository.sumWonInSession(session.getId(), p.getUserId()))))
                .orElse(BigDecimal.ZERO);
    }

    private void autoBid(Lot lot, AuctionSession session, Long userId, BigDecimal amount) {
        autoBid(lot, session, userId, amount, false);
    }

    /** force = true: cho phép mức thấp hơn 1 bước giá khi đó là giá tối đa của proxy đang giữ giá. */
    private void autoBid(Lot lot, AuctionSession session, Long userId, BigDecimal amount, boolean force) {
        BigDecimal floor = force && lot.getCurrentPrice() != null ? lot.getCurrentPrice().add(BigDecimal.ONE) : views.nextMinBid(lot);
        if (amount.compareTo(floor) < 0 || (!force && userId.equals(lot.getCurrentWinnerId()))) {
            return;
        }
        Instant now = Instant.now();
        lot.setCurrentPrice(amount);
        lot.setCurrentWinnerId(userId);
        lot.setBidCount(lot.getBidCount() + 1);
        Instant softEnd = now.plus(Duration.ofSeconds(session.getSoftCloseSec()));
        if (lot.getEndsAt() != null && lot.getEndsAt().isBefore(softEnd)) {
            lot.setEndsAt(softEnd);
        }
        Long regId = registrationRepository.findBySessionIdAndUserId(session.getId(), userId).orElseThrow().getId();
        saveBid(lot.getId(), userId, regId, amount, true);
    }

    private void saveBid(Long lotId, Long userId, Long regId, BigDecimal amount, boolean auto) {
        Bid bid = new Bid();
        bid.setLotId(lotId);
        bid.setUserId(userId);
        bid.setRegistrationId(regId);
        bid.setAmount(amount);
        bid.setAuto(auto);
        bidRepository.save(bid);
    }

    /** Phát BID_PLACED cho cả phòng, báo "bị trả giá cao hơn" cho người vừa mất vị trí dẫn đầu. */
    private void afterPriceChange(Lot lot, AuctionSession session, Set<Long> outbid) {
        lotRepository.flush();
        views.broadcast(session, "BID_PLACED", lot, null);
        Map<Long, String> paddles = views.paddles(session.getId());
        for (Long u : outbid) {
            if (!Objects.equals(u, lot.getCurrentWinnerId())) {
                notifications.notify(u, NotificationService.AUCTION_OUTBID, "Bạn đã bị trả giá cao hơn",
                        "Lô " + lot.getLotNumber() + " hiện ở mức " + lot.getCurrentPrice().toPlainString() + "đ ("
                                + paddles.getOrDefault(lot.getCurrentWinnerId(), "") + ")",
                        Map.of("sessionId", session.getId(), "lotId", lot.getId()));
            }
        }
    }

    private AuctionSession requireLiveSession(Lot lot) {
        if (lot.getSessionId() == null) {
            throw ApiException.conflict("LOT_NOT_OPEN", "Lô chưa được xếp phiên");
        }
        AuctionSession s = sessionRepository.findById(lot.getSessionId()).orElseThrow();
        if (s.getStatus() != SessionStatus.LIVE) {
            throw ApiException.conflict("SESSION_NOT_LIVE", s.getStatus() == SessionStatus.PAUSED
                    ? "Phiên đang tạm dừng" : "Phiên chưa diễn ra hoặc đã kết thúc");
        }
        return s;
    }

    private AuctionRegistration requireBidder(Long userId, Lot lot, AuctionSession session) {
        User user = userService.getUser(userId);
        if (user.isAuctionBanned()) {
            throw ApiException.forbidden("Tài khoản đang bị cấm tham gia đấu giá đến " + user.getAuctionBannedUntil());
        }
        AuctionRegistration reg = registrationRepository.findBySessionIdAndUserId(session.getId(), userId)
                .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                .orElseThrow(() -> ApiException.forbidden("Bạn chưa đăng ký và đặt cọc cho phiên này"));
        Long sellerId = consignmentRepository.findById(lot.getConsignmentId()).orElseThrow().getSellerId();
        if (sellerId.equals(userId)) {
            throw ApiException.forbidden("Không thể trả giá lô do chính bạn ký gửi");
        }
        return reg;
    }

    private void checkLimit(AuctionRegistration reg, BigDecimal amount) {
        BigDecimal won = lotRepository.sumWonInSession(reg.getSessionId(), reg.getUserId());
        if (won.add(amount).compareTo(reg.getBidLimit()) > 0) {
            throw ApiException.badRequest("BID_LIMIT_EXCEEDED", "Vượt hạn mức trả giá (" + reg.getBidLimit().toPlainString()
                    + "đ). Hãy đặt cọc thêm để nâng hạn mức");
        }
    }

    static final Set<LotStatus> CLOSED = EnumSet.of(LotStatus.SOLD, LotStatus.UNSOLD, LotStatus.CANCELLED);
}
