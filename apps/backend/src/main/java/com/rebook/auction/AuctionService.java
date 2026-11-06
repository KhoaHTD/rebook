package com.rebook.auction;

import com.rebook.auction.AuctionDtos.LotDetail;
import com.rebook.auction.AuctionDtos.LotPublic;
import com.rebook.auction.AuctionDtos.LotResult;
import com.rebook.auction.AuctionDtos.RegistrationResponse;
import com.rebook.auction.AuctionDtos.SessionDetail;
import com.rebook.auction.AuctionDtos.SessionState;
import com.rebook.auction.AuctionDtos.SessionSummary;
import com.rebook.catalog.BookRepository;
import com.rebook.catalog.CatalogDtos.BookResponse;
import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.consignment.Consignment;
import com.rebook.consignment.ConsignmentRepository;
import com.rebook.consignment.Inspection;
import com.rebook.consignment.InspectionRepository;
import com.rebook.system.SystemConfigService;
import com.rebook.user.User;
import com.rebook.user.UserService;
import com.rebook.wallet.DebtService;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Phía người mua / khách: lịch phiên, catalogue, đăng ký + cọc, phòng đấu giá, theo dõi lô. */
@Service
@RequiredArgsConstructor
public class AuctionService {

    private final AuctionSessionRepository sessionRepository;
    private final LotRepository lotRepository;
    private final AuctionRegistrationRepository registrationRepository;
    private final LotWatcherRepository watcherRepository;
    private final SessionWatcherRepository sessionWatcherRepository;
    private final ConsignmentRepository consignmentRepository;
    private final InspectionRepository inspectionRepository;
    private final BookRepository bookRepository;
    private final BidService bidService;
    private final UserService userService;
    private final WalletService walletService;
    private final SystemConfigService config;
    private final AuctionViews views;
    private final ProxyBidRepository proxyRepository;
    private final DebtService debts;
    private final AuditLog audit;

    // ---- Xem ----

    @Transactional(readOnly = true)
    public PageResponse<SessionSummary> sessions(SessionStatus status, int page, int size) {
        Set<SessionStatus> statuses = status == null ? SessionStatus.PUBLIC
                : (SessionStatus.PUBLIC.contains(status) ? Set.of(status) : Set.of());
        if (statuses.isEmpty()) {
            return new PageResponse<>(List.of(), page, size, 0, 0);
        }
        return PageResponse.of(sessionRepository.findByStatusInOrderByStartAtAsc(statuses, PageRequest.of(page, size)), views::summary);
    }

    @Transactional(readOnly = true)
    public SessionDetail session(Long sessionId, Long viewerId) {
        AuctionSession s = publicSession(sessionId);
        List<Lot> lots = lotRepository.findBySessionIdOrderByLotNumberAsc(sessionId);
        Map<Long, String> paddles = views.paddles(sessionId);
        Set<Long> watched = watched(viewerId, lots);
        RegistrationResponse mine = viewerId == null ? null
                : registrationRepository.findBySessionIdAndUserId(sessionId, viewerId)
                .map(r -> views.registration(r, currentLot(s))).orElse(null);
        return new SessionDetail(views.summary(s), s.getLotDurationSec(), s.getSoftCloseSec(),
                lots.stream().map(l -> views.lotPublic(l, paddles, watched)).toList(), mine);
    }

    @Transactional(readOnly = true)
    public LotDetail lot(Long lotId, Long viewerId) {
        Lot lot = lotRepository.findById(lotId).orElseThrow(() -> ApiException.notFound("lô"));
        if (lot.getSessionId() == null) {
            throw ApiException.notFound("lô");
        }
        AuctionSession s = publicSession(lot.getSessionId());
        Consignment c = consignmentRepository.findById(lot.getConsignmentId()).orElseThrow();
        Inspection insp = inspectionRepository.findByConsignmentId(c.getId()).orElse(null);
        LotPublic pub = views.lotPublic(lot, views.paddles(s.getId()), watched(viewerId, List.of(lot)));
        return new LotDetail(pub, BookResponse.of(bookRepository.findById(lot.getBookId()).orElseThrow()),
                insp == null ? null : insp.getConditionReport(), insp == null ? null : insp.getChecklist(),
                c.getProvenance(), views.summary(s));
    }

    /** Ảnh chụp trạng thái phòng đấu giá — gọi khi vào phòng / kết nối lại. */
    @Transactional(readOnly = true)
    public SessionState state(Long sessionId, Long viewerId) {
        AuctionSession s = publicSession(sessionId);
        Lot current = currentLot(s);
        long remaining = lotRepository.findBySessionIdOrderByLotNumberAsc(sessionId).stream()
                .filter(l -> l.getStatus() == LotStatus.SCHEDULED).count();
        RegistrationResponse me = null;
        BigDecimal myProxy = null;
        if (viewerId != null) {
            me = registrationRepository.findBySessionIdAndUserId(sessionId, viewerId)
                    .map(r -> views.registration(r, current)).orElse(null);
            if (current != null) {
                myProxy = bidService.myProxy(viewerId, current.getId()).orElse(null);
            }
        }
        return new SessionState(Instant.now(), sessionId, s.getStatus(), views.lotLive(current, views.paddles(sessionId)),
                s.getNextLotAt(), remaining, s.getPausedRemainingMs(), me, myProxy);
    }

    /** Bảng kết quả: số bài + giá, không hiện tên thật. */
    @Transactional(readOnly = true)
    public List<LotResult> results(Long sessionId) {
        AuctionSession s = publicSession(sessionId);
        Map<Long, String> paddles = views.paddles(s.getId());
        return lotRepository.findBySessionIdOrderByLotNumberAsc(sessionId).stream()
                .filter(l -> l.getCloseResult() != null)
                .map(l -> {
                    boolean sold = l.getCloseResult() == Lot.CloseResult.SOLD;
                    return new LotResult(l.getLotNumber(), l.getId(), bookRepository.findById(l.getBookId()).orElseThrow().getTitle(),
                            l.getCloseResult(), sold ? l.getHammerPrice() : null, sold ? paddles.get(l.getWinnerId()) : null);
                }).toList();
    }

    // ---- Đăng ký tham gia + đặt cọc ----

    /**
     * Đăng ký: đã xác thực SĐT, đồng ý quy chế, khoá tiền cọc trong ví (DEPOSIT_HOLD).
     * Hệ thống cấp số bài ẩn danh. Hạn mức trả giá = cọc × 10.
     */
    @Transactional
    public RegistrationResponse register(Long userId, Long sessionId, boolean agreeRules) {
        AuctionSession s = sessionRepository.lockById(sessionId).orElseThrow(() -> ApiException.notFound("phiên đấu giá"));
        if (s.getStatus() != SessionStatus.PUBLISHED || !s.getRegistrationDeadline().isAfter(Instant.now())) {
            throw ApiException.conflict("REGISTRATION_CLOSED", "Phiên không còn nhận đăng ký");
        }
        User user = userService.getUser(userId);
        if (user.isPlatformOperator()) {
            throw ApiException.forbidden("STAFF_CANNOT_BID", "Tài khoản nhân viên sàn không được tham gia đấu giá");
        }
        if (!user.isPhoneVerified()) {
            throw ApiException.forbidden("Cần xác thực số điện thoại trước khi tham gia đấu giá");
        }
        if (user.isAuctionBanned()) {
            throw ApiException.forbidden("AUCTION_BANNED", "Tài khoản đang bị cấm tham gia đấu giá đến " + user.getAuctionBannedUntil());
        }
        debts.collect(userId);
        if (debts.hasOpenDebt(userId)) {
            throw ApiException.conflict("DEBT_OPEN", "Bạn còn khoản nợ phạt hoặc phí kho chưa thanh toán, hãy thanh toán trước khi đăng ký");
        }
        if (!agreeRules) {
            throw ApiException.badRequest("RULES_REQUIRED", "Cần đồng ý quy chế phiên đấu giá");
        }
        AuctionRegistration existing = registrationRepository.findBySessionIdAndUserId(sessionId, userId).orElse(null);
        if (existing != null && existing.getStatus() != AuctionRegistration.Status.CANCELLED) {
            throw ApiException.conflict("ALREADY_REGISTERED", "Bạn đã đăng ký phiên này (số bài " + existing.paddle() + ")");
        }
        // Đăng ký lại sau khi đã huỷ: dùng lại dòng cũ và số bài cũ
        AuctionRegistration reg = existing != null ? existing : new AuctionRegistration();
        if (existing == null) {
            reg.setSessionId(sessionId);
            reg.setUserId(userId);
            reg.setPaddleNumber(registrationRepository.maxPaddle(sessionId) + 1);
        }
        reg.setDepositAmount(s.getDepositAmount());
        reg.setBidLimit(s.getDepositAmount().multiply(bidLimitMultiplier(s)));
        reg = registrationRepository.saveAndFlush(reg);
        walletService.hold(userId, WalletTxType.DEPOSIT_HOLD, s.getDepositAmount(), "REGISTRATION", reg.getId(),
                "Đặt cọc phiên " + s.getTitle());
        reg.setStatus(reg.getStatus().moveTo(AuctionRegistration.Status.APPROVED));
        return views.registration(reg, null);
    }

    /** Huỷ đăng ký trước hạn đăng ký: hoàn toàn bộ cọc, huỷ giá tối đa tự động, không tính vào số người đăng ký. */
    @Transactional
    public RegistrationResponse cancelRegistration(Long userId, Long sessionId) {
        AuctionSession s = sessionRepository.lockById(sessionId).orElseThrow(() -> ApiException.notFound("phiên đấu giá"));
        boolean open = s.getStatus() == SessionStatus.PUBLISHED || s.getStatus() == SessionStatus.POSTPONED;
        if (!open || !s.getRegistrationDeadline().isAfter(Instant.now())) {
            throw ApiException.conflict("REGISTRATION_CLOSED", "Đã hết hạn đăng ký, không huỷ được nữa");
        }
        AuctionRegistration reg = registrationRepository.lockBySessionIdAndUserId(sessionId, userId)
                .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                .orElseThrow(() -> ApiException.notFound("lượt đăng ký"));
        walletService.release(userId, WalletTxType.DEPOSIT_RELEASE, reg.getDepositAmount(), "REGISTRATION", reg.getId(),
                "Hoàn cọc do huỷ đăng ký phiên " + s.getTitle());
        reg.setStatus(reg.getStatus().moveTo(AuctionRegistration.Status.CANCELLED));
        int proxies = proxyRepository.deactivateForUserInSession(userId, sessionId);
        audit.record(EventCode.AUCTION_REGISTRATION_CANCELLED, "SESSION", sessionId, null, "Huỷ đăng ký, hoàn cọc",
                "deposit", reg.getDepositAmount(), "paddle", reg.paddle(), "proxiesCancelled", proxies);
        return views.registration(reg, null);
    }

    /** Cọc thêm để nâng hạn mức (được làm cả khi phiên đang chạy). */
    @Transactional
    public RegistrationResponse addDeposit(Long userId, Long sessionId, BigDecimal amount) {
        AuctionRegistration reg = registrationRepository.lockBySessionIdAndUserId(sessionId, userId)
                .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                .orElseThrow(() -> ApiException.forbidden("Bạn chưa đăng ký phiên này"));
        AuctionSession s = sessionRepository.findById(sessionId).orElseThrow();
        if (s.getStatus() == SessionStatus.ENDED || s.getStatus() == SessionStatus.CANCELLED) {
            throw ApiException.conflict("SESSION_CLOSED", "Phiên đã kết thúc");
        }
        walletService.hold(userId, WalletTxType.DEPOSIT_HOLD, amount, "REGISTRATION", reg.getId(), "Cọc thêm phiên " + s.getTitle());
        reg.setDepositAmount(reg.getDepositAmount().add(amount));
        reg.setBidLimit(reg.getDepositAmount().multiply(bidLimitMultiplier(s)));
        return views.registration(reg, currentLot(s));
    }

    @Transactional(readOnly = true)
    public List<RegistrationResponse> myRegistrations(Long userId) {
        return registrationRepository.findByUserIdOrderByIdDesc(userId).stream()
                .map(r -> views.registration(r, null)).toList();
    }

    // ---- Theo dõi lô ----

    @Transactional
    public boolean watch(Long userId, Long lotId, boolean on) {
        Lot lot = lotRepository.findById(lotId).orElseThrow(() -> ApiException.notFound("lô"));
        if (on) {
            if (!watcherRepository.existsByUserIdAndLotId(userId, lot.getId())) {
                watcherRepository.save(new LotWatcher(userId, lot.getId()));
            }
        } else {
            watcherRepository.deleteById(new LotWatcher.Key(userId, lotId));
        }
        return on;
    }

    @Transactional(readOnly = true)
    public List<LotPublic> watchedLots(Long userId) {
        List<Long> ids = watcherRepository.findByUserIdOrderByCreatedAtDesc(userId).stream().map(LotWatcher::getLotId).toList();
        Set<Long> all = new HashSet<>(ids);
        return lotRepository.findAllById(ids).stream()
                .map(l -> views.lotPublic(l, views.paddles(l.getSessionId()), all)).toList();
    }

    /** Theo dõi / bỏ theo dõi cả phiên (phiên yêu thích). */
    @Transactional
    public boolean watchSession(Long userId, Long sessionId, boolean on) {
        AuctionSession s = publicSession(sessionId);
        if (on) {
            if (!sessionWatcherRepository.existsById(new SessionWatcher.Key(userId, s.getId()))) {
                sessionWatcherRepository.save(new SessionWatcher(userId, s.getId()));
            }
        } else {
            sessionWatcherRepository.deleteById(new SessionWatcher.Key(userId, sessionId));
        }
        return on;
    }

    /** Các phiên tôi theo dõi, theo dõi gần nhất trước. Phiên đã ẩn (nháp / huỷ) thì bỏ qua. */
    @Transactional(readOnly = true)
    public List<SessionSummary> watchedSessions(Long userId) {
        List<Long> ids = sessionWatcherRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(SessionWatcher::getSessionId).toList();
        Map<Long, AuctionSession> byId = new HashMap<>();
        sessionRepository.findAllById(ids).forEach(s -> byId.put(s.getId(), s));
        return ids.stream().map(byId::get)
                .filter(s -> s != null && SessionStatus.PUBLIC.contains(s.getStatus()))
                .map(views::summary).toList();
    }

    // ---- Nội bộ ----

    /** Hệ số hạn mức đã chốt lúc công bố phiên (BR-5.3). */
    private BigDecimal bidLimitMultiplier(AuctionSession s) {
        return s.getBidLimitMultiplier() != null ? BigDecimal.valueOf(s.getBidLimitMultiplier())
                : config.decimal(SystemConfigService.BID_LIMIT_MULTIPLIER);
    }

    private AuctionSession publicSession(Long id) {
        AuctionSession s = sessionRepository.findById(id).orElseThrow(() -> ApiException.notFound("phiên đấu giá"));
        if (!SessionStatus.PUBLIC.contains(s.getStatus())) {
            throw ApiException.notFound("phiên đấu giá");
        }
        return s;
    }

    private Lot currentLot(AuctionSession s) {
        return s.getCurrentLotId() == null ? null : lotRepository.findById(s.getCurrentLotId()).orElse(null);
    }

    private Set<Long> watched(Long viewerId, List<Lot> lots) {
        if (viewerId == null || lots.isEmpty()) {
            return Set.of();
        }
        return new HashSet<>(watcherRepository.findWatchedLotIds(viewerId, lots.stream().map(Lot::getId).toList()));
    }
}
