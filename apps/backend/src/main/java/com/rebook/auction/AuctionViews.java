package com.rebook.auction;

import com.rebook.auction.AuctionDtos.AuctionEvent;
import com.rebook.auction.AuctionDtos.BidView;
import com.rebook.auction.AuctionDtos.LotLive;
import com.rebook.auction.AuctionDtos.LotPublic;
import com.rebook.auction.AuctionDtos.RegistrationResponse;
import com.rebook.auction.AuctionDtos.SessionSummary;
import com.rebook.catalog.Book;
import com.rebook.catalog.BookRepository;
import com.rebook.notification.RealtimeHub;
import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/** Dựng DTO đấu giá và phát sự kiện realtime. Không bao giờ để lộ reservePrice hay tên thật người trả giá. */
@Component
@RequiredArgsConstructor
public class AuctionViews {

    private static final Set<AuctionRegistration.Status> COUNTED = EnumSet.of(AuctionRegistration.Status.APPROVED,
            AuctionRegistration.Status.APPLIED, AuctionRegistration.Status.FORFEITED);

    private final LotRepository lotRepository;
    private final AuctionRegistrationRepository registrationRepository;
    private final BidRepository bidRepository;
    private final BookRepository bookRepository;
    private final SystemConfigService config;
    private final RealtimeHub hub;

    public SessionSummary summary(AuctionSession s) {
        return new SessionSummary(s.getId(), s.getTitle(), s.getDescription(), s.getCoverUrl(), s.getStartAt(),
                s.getRegistrationDeadline(), s.getMinParticipants(), s.getDepositAmount(), s.getStatus(),
                lotRepository.countBySessionId(s.getId()),
                registrationRepository.countBySessionIdAndStatusIn(s.getId(), COUNTED), s.getEndedAt());
    }

    /** userId → số bài "#007" của phiên. */
    public Map<Long, String> paddles(Long sessionId) {
        if (sessionId == null) {
            return new java.util.HashMap<>();
        }
        return registrationRepository.findBySessionId(sessionId).stream()
                .collect(Collectors.toMap(AuctionRegistration::getUserId, AuctionRegistration::paddle));
    }

    public BigDecimal increment(BigDecimal price) {
        return config.bidIncrement(price == null ? BigDecimal.ZERO : price);
    }

    /** Giá tối thiểu cho lượt kế tiếp = giá hiện tại + bước giá (hoặc giá khởi điểm nếu chưa ai trả). */
    public BigDecimal nextMinBid(Lot l) {
        return l.getCurrentPrice() == null ? l.getStartPrice() : l.getCurrentPrice().add(increment(l.getCurrentPrice()));
    }

    public LotPublic lotPublic(Lot l, Map<Long, String> paddles, Set<Long> watched) {
        Book b = bookRepository.findById(l.getBookId()).orElseThrow();
        boolean revealResult = l.getCloseResult() == Lot.CloseResult.SOLD;
        return new LotPublic(l.getId(), l.getSessionId(), l.getLotNumber(), l.getStatus(), l.getCloseResult(),
                b.getTitle(), b.getAuthor(), b.coverUrl(), b.getConditionGrade(), l.getEstimateLow(), l.getEstimateHigh(),
                l.getStartPrice(), l.getCurrentPrice(), l.getBidCount(), l.getEndsAt(),
                revealResult ? l.getHammerPrice() : null,
                revealResult ? paddles.get(l.getWinnerId()) : null,
                watched.contains(l.getId()));
    }

    public LotLive lotLive(Lot l, Map<Long, String> paddles) {
        if (l == null) {
            return null;
        }
        Book b = bookRepository.findById(l.getBookId()).orElseThrow();
        List<BidView> recent = l.getOpenedAt() == null ? List.of()
                : bidRepository.findRecent(l.getId(), l.getOpenedAt(), PageRequest.of(0, 10)).stream()
                .map(x -> new BidView(paddles.getOrDefault(x.getUserId(), "#???"), x.getAmount(), x.isAuto(), x.getCreatedAt()))
                .toList();
        boolean open = l.getStatus() == LotStatus.OPEN;
        boolean sold = l.getCloseResult() == Lot.CloseResult.SOLD;
        return new LotLive(l.getId(), l.getLotNumber(), b.getTitle(), b.coverUrl(), l.getStatus(), l.getStartPrice(),
                l.getCurrentPrice(), open ? nextMinBid(l) : null, open ? increment(l.getCurrentPrice()) : null,
                l.getBidCount(), l.getEndsAt(), paddles.get(l.getCurrentWinnerId()), recent, l.getCloseResult(),
                sold ? l.getHammerPrice() : null);
    }

    /** Tổng tiền người dùng đang "giữ" trong phiên: lô đã thắng + lô đang dẫn đầu. */
    public BigDecimal committed(Long sessionId, Long userId, Lot openLot) {
        BigDecimal won = lotRepository.sumWonInSession(sessionId, userId);
        if (openLot != null && openLot.getStatus() == LotStatus.OPEN && userId.equals(openLot.getCurrentWinnerId())) {
            won = won.add(openLot.getCurrentPrice());
        }
        return won;
    }

    public RegistrationResponse registration(AuctionRegistration r, Lot openLot) {
        if (r == null) {
            return null;
        }
        BigDecimal committed = committed(r.getSessionId(), r.getUserId(), openLot);
        return new RegistrationResponse(r.getId(), r.getSessionId(), r.paddle(), r.getDepositAmount(), r.getBidLimit(),
                committed, r.getBidLimit().subtract(committed).max(BigDecimal.ZERO), r.getStatus(), r.getCreatedAt());
    }

    public void broadcast(AuctionSession s, String type, Lot lot, String message) {
        LotLive live = lot == null ? null : lotLive(lot, paddles(s.getId()));
        hub.publish(RealtimeHub.sessionChannel(s.getId()),
                new AuctionEvent(type, s.getId(), Instant.now(), s.getStatus(), live, s.getNextLotAt(), message));
    }
}
