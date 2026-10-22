package com.rebook.auction;

import com.rebook.common.ApiException;
import com.rebook.notification.NotificationService;
import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Các bước của bộ máy chạy phiên. Mỗi phương thức là một transaction riêng, khoá dòng phiên
 * (FOR UPDATE) để job và thao tác của Staff không giẫm lên nhau.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuctionRunner {

    private final AuctionSessionRepository sessionRepository;
    private final LotRepository lotRepository;
    private final AuctionRegistrationRepository registrationRepository;
    private final ProxyBidRepository proxyRepository;
    private final LotWatcherRepository watcherRepository;
    private final BidService bidService;
    private final AuctionSettlement settlement;
    private final AuctionViews views;
    private final SystemConfigService config;
    private final NotificationService notifications;

    // ---- Giai đoạn D: hết hạn đăng ký → đủ người? ----

    @Transactional
    public void checkQuorum(Long sessionId) {
        AuctionSession s = lock(sessionId);
        if (s.getStatus() != SessionStatus.PUBLISHED) {
            return;
        }
        List<AuctionRegistration> regs = registrationRepository.findBySessionIdAndStatus(sessionId, AuctionRegistration.Status.APPROVED);
        if (regs.size() >= s.getMinParticipants()) {
            s.setStatus(s.getStatus().moveTo(SessionStatus.CONFIRMED));
            Set<Long> audience = new HashSet<>(regs.stream().map(AuctionRegistration::getUserId).toList());
            audience.addAll(sellerIds(sessionId));
            notifications.notifyAll(audience, NotificationService.AUCTION_REMINDER, "Phiên đấu giá đã được xác nhận",
                    "Phiên \"" + s.getTitle() + "\" sẽ diễn ra lúc " + s.getStartAt(), Map.of("sessionId", sessionId));
            log.info("Phiên {} đủ {} người → CONFIRMED", sessionId, regs.size());
        } else if (s.getPostponeCount() == 0) {
            // Dời lịch một lần, mở lại đăng ký
            Duration delay = config.days(SystemConfigService.POSTPONE_DAYS);
            s.setStatus(s.getStatus().moveTo(SessionStatus.POSTPONED));
            s.setPostponeCount(1);
            s.setStartAt(s.getStartAt().plus(delay));
            s.setRegistrationDeadline(s.getRegistrationDeadline().plus(delay));
            s.setStatus(s.getStatus().moveTo(SessionStatus.PUBLISHED));
            notifications.notifyAll(regs.stream().map(AuctionRegistration::getUserId).toList(), NotificationService.AUCTION,
                    "Phiên đấu giá dời lịch", "Phiên \"" + s.getTitle() + "\" chưa đủ người, dời sang " + s.getStartAt(),
                    Map.of("sessionId", sessionId));
            log.info("Phiên {} thiếu người ({}/{}) → dời lịch", sessionId, regs.size(), s.getMinParticipants());
        } else {
            cancel(s, "Không đủ người tham gia");
        }
    }

    // ---- Nhắc trước giờ mở (phòng chờ mở trước 15 phút) ----

    @Transactional
    public void sendReminder(Long sessionId) {
        AuctionSession s = lock(sessionId);
        if (s.isReminderSent() || s.getStatus() != SessionStatus.CONFIRMED) {
            return;
        }
        s.setReminderSent(true);
        Set<Long> audience = new HashSet<>(registrationRepository.findBySessionIdAndStatus(sessionId,
                AuctionRegistration.Status.APPROVED).stream().map(AuctionRegistration::getUserId).toList());
        List<Long> lotIds = lotRepository.findBySessionIdOrderByLotNumberAsc(sessionId).stream().map(Lot::getId).toList();
        if (!lotIds.isEmpty()) {
            audience.addAll(watcherRepository.findUserIdsByLotIds(lotIds));
        }
        notifications.notifyAll(audience, NotificationService.AUCTION_REMINDER, "Sắp tới phiên đấu giá",
                "Phiên \"" + s.getTitle() + "\" bắt đầu lúc " + s.getStartAt() + ". Phòng chờ đã mở!",
                Map.of("sessionId", sessionId));
    }

    // ---- Giai đoạn E: phiên trực tiếp ----

    @Transactional
    public void start(Long sessionId) {
        AuctionSession s = lock(sessionId);
        if (s.getStatus() != SessionStatus.CONFIRMED) {
            return;
        }
        s.setStatus(s.getStatus().moveTo(SessionStatus.LIVE));
        s.setStartedAt(Instant.now());
        s.setNextLotAt(Instant.now());
        views.broadcast(s, "SESSION_STARTED", null, "Phiên đấu giá bắt đầu");
        log.info("Phiên {} LIVE", sessionId);
    }

    /** Một nhịp của phiên đang chạy: chốt lô hết giờ, mở lô kế tiếp, hoặc đóng phiên. */
    @Transactional
    public void tick(Long sessionId) {
        AuctionSession s = lock(sessionId);
        if (s.getStatus() != SessionStatus.LIVE) {
            return;
        }
        Instant now = Instant.now();
        Lot current = s.getCurrentLotId() == null ? null : lotRepository.lockById(s.getCurrentLotId()).orElse(null);

        if (current != null && current.getStatus() == LotStatus.OPEN) {
            if (!current.getEndsAt().isAfter(now)) {
                closeLot(s, current, now);
            }
            return;
        }
        if (s.getNextLotAt() != null && s.getNextLotAt().isAfter(now)) {
            return; // đang nghỉ giữa các lô
        }
        lotRepository.findFirstBySessionIdAndStatusOrderByLotNumberAsc(sessionId, LotStatus.SCHEDULED)
                .ifPresentOrElse(next -> openLot(s, next, now), () -> end(s, now));
    }

    private void openLot(AuctionSession s, Lot lot, Instant now) {
        lot.setStatus(lot.getStatus().moveTo(LotStatus.OPEN));
        lot.setOpenedAt(now);
        lot.setEndsAt(now.plus(Duration.ofSeconds(s.getLotDurationSec())));
        lot.setCurrentPrice(null);
        lot.setCurrentWinnerId(null);
        lot.setBidCount(0);
        s.setCurrentLotId(lot.getId());
        s.setNextLotAt(null);
        lotRepository.flush();
        // Giá tối đa đặt trước (absentee) được trả hộ ngay khi lô mở
        bidService.resolveProxies(lot, s, new HashSet<>());
        views.broadcast(s, "LOT_OPENED", lot, "Lô " + lot.getLotNumber() + " bắt đầu");
    }

    private void closeLot(AuctionSession s, Lot lot, Instant now) {
        lot.setClosedAt(now);
        if (lot.getBidCount() == 0 || lot.getCurrentWinnerId() == null) {
            lot.setStatus(lot.getStatus().moveTo(LotStatus.UNSOLD));
            lot.setCloseResult(Lot.CloseResult.NO_BIDS);
        } else if (lot.getCurrentPrice().compareTo(lot.getReservePrice()) >= 0) {
            lot.setStatus(lot.getStatus().moveTo(LotStatus.SOLD));
            lot.setCloseResult(Lot.CloseResult.SOLD);
            lot.setHammerPrice(lot.getCurrentPrice());
            lot.setWinnerId(lot.getCurrentWinnerId());
        } else {
            // Không tiết lộ giá sàn
            lot.setStatus(lot.getStatus().moveTo(LotStatus.UNSOLD));
            lot.setCloseResult(Lot.CloseResult.RESERVE_NOT_MET);
        }
        proxyRepository.deactivateAll(lot.getId());
        s.setNextLotAt(now.plus(Duration.ofSeconds(s.getLotGapSec())));
        String msg = switch (lot.getCloseResult()) {
            case SOLD -> "Bán! Lô " + lot.getLotNumber() + " – " + lot.getHammerPrice().toPlainString() + "đ";
            case RESERVE_NOT_MET -> "Lô " + lot.getLotNumber() + " không đạt giá";
            default -> "Lô " + lot.getLotNumber() + " không có người trả giá";
        };
        views.broadcast(s, "LOT_CLOSED", lot, msg);
    }

    private void end(AuctionSession s, Instant now) {
        s.setStatus(s.getStatus().moveTo(SessionStatus.ENDED));
        s.setEndedAt(now);
        s.setNextLotAt(null);
        settlement.afterSessionEnded(s);
        views.broadcast(s, "SESSION_ENDED", null, "Phiên đã kết thúc");
        log.info("Phiên {} ENDED", s.getId());
    }

    // ---- Staff can thiệp khi có sự cố ----

    @Transactional
    public AuctionSession pause(Long sessionId) {
        AuctionSession s = lock(sessionId);
        s.setStatus(s.getStatus().moveTo(SessionStatus.PAUSED));
        Instant now = Instant.now();
        Lot current = s.getCurrentLotId() == null ? null : lotRepository.findById(s.getCurrentLotId()).orElse(null);
        if (current != null && current.getStatus() == LotStatus.OPEN) {
            s.setPausedRemainingMs(Math.max(0, Duration.between(now, current.getEndsAt()).toMillis()));
        } else if (s.getNextLotAt() != null) {
            s.setPausedRemainingMs(Math.max(0, Duration.between(now, s.getNextLotAt()).toMillis()));
        }
        views.broadcast(s, "SESSION_PAUSED", current, "Phiên tạm dừng do sự cố kỹ thuật");
        return s;
    }

    @Transactional
    public AuctionSession resume(Long sessionId) {
        AuctionSession s = lock(sessionId);
        s.setStatus(s.getStatus().moveTo(SessionStatus.LIVE));
        Instant now = Instant.now();
        long remaining = s.getPausedRemainingMs() == null ? 0 : s.getPausedRemainingMs();
        Lot current = s.getCurrentLotId() == null ? null : lotRepository.lockById(s.getCurrentLotId()).orElse(null);
        if (current != null && current.getStatus() == LotStatus.OPEN) {
            // Trả lại ít nhất thời gian soft close để mọi người kịp vào lại
            long min = s.getSoftCloseSec() * 1000L;
            current.setEndsAt(now.plusMillis(Math.max(remaining, min)));
        } else if (s.getNextLotAt() != null) {
            s.setNextLotAt(now.plusMillis(remaining));
        }
        s.setPausedRemainingMs(null);
        views.broadcast(s, "SESSION_RESUMED", current, "Phiên tiếp tục");
        return s;
    }

    /** Huỷ một lô (đang mở hoặc chưa tới lượt) khi có sự cố. Lượt trả giá của lô bị vô hiệu. */
    @Transactional
    public Lot cancelLot(Long lotId, String reason) {
        Lot lot = lotRepository.lockById(lotId).orElseThrow(() -> ApiException.notFound("lô"));
        if (lot.getSessionId() == null) {
            throw ApiException.conflict("LOT_NOT_SCHEDULED", "Lô chưa được xếp phiên");
        }
        AuctionSession s = lock(lot.getSessionId());
        boolean wasOpen = lot.getStatus() == LotStatus.OPEN;
        lot.setStatus(lot.getStatus().moveTo(LotStatus.CANCELLED));
        lot.setCloseResult(Lot.CloseResult.CANCELLED);
        lot.setClosedAt(Instant.now());
        lot.setCurrentWinnerId(null);
        proxyRepository.deactivateAll(lotId);
        if (wasOpen) {
            s.setNextLotAt(Instant.now().plus(Duration.ofSeconds(s.getLotGapSec())));
            if (s.getStatus() == SessionStatus.PAUSED) {
                s.setPausedRemainingMs(s.getLotGapSec() * 1000L);
            }
        }
        views.broadcast(s, "LOT_CLOSED", lot, "Lô " + lot.getLotNumber() + " bị huỷ" + (reason != null ? ": " + reason : ""));
        settlementNotify(lot, "Lô " + lot.getLotNumber() + " bị huỷ do sự cố. Bạn có thể đưa lô vào phiên sau hoặc nhận lại sách");
        return lot;
    }

    @Transactional
    public AuctionSession cancelSession(Long sessionId, String reason) {
        AuctionSession s = lock(sessionId);
        if (!EnumSet.of(SessionStatus.DRAFT, SessionStatus.PUBLISHED, SessionStatus.POSTPONED, SessionStatus.CONFIRMED)
                .contains(s.getStatus())) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Chỉ huỷ được phiên chưa diễn ra");
        }
        cancel(s, reason);
        return s;
    }

    /** Demo: mở phiên ngay (bỏ qua chờ tới giờ). Phiên PUBLISHED sẽ kiểm tra đủ người trước. */
    @Transactional
    public AuctionSession startNow(Long sessionId) {
        AuctionSession s = lock(sessionId);
        Instant now = Instant.now();
        if (s.getStatus() == SessionStatus.PUBLISHED) {
            s.setRegistrationDeadline(now);
            s.setStartAt(now);
            long count = registrationRepository.findBySessionIdAndStatus(sessionId, AuctionRegistration.Status.APPROVED).size();
            if (count < s.getMinParticipants()) {
                throw ApiException.conflict("NOT_ENOUGH_PARTICIPANTS", "Mới có " + count + "/" + s.getMinParticipants() + " người đăng ký");
            }
            s.setStatus(s.getStatus().moveTo(SessionStatus.CONFIRMED));
        }
        if (s.getStatus() != SessionStatus.CONFIRMED) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Phiên phải ở trạng thái PUBLISHED hoặc CONFIRMED");
        }
        s.setStartAt(now);
        if (s.getRegistrationDeadline().isAfter(now)) {
            s.setRegistrationDeadline(now);
        }
        s.setStatus(s.getStatus().moveTo(SessionStatus.LIVE));
        s.setStartedAt(now);
        s.setNextLotAt(now);
        views.broadcast(s, "SESSION_STARTED", null, "Phiên đấu giá bắt đầu");
        return s;
    }

    private void cancel(AuctionSession s, String reason) {
        s.setStatus(s.getStatus().moveTo(SessionStatus.CANCELLED));
        settlement.onSessionCancelled(s);
        views.broadcast(s, "SESSION_CANCELLED", null, reason);
        log.info("Phiên {} CANCELLED: {}", s.getId(), reason);
    }

    private void settlementNotify(Lot lot, String text) {
        notifications.notify(settlement.sellerOf(lot), NotificationService.AUCTION, "Lô đấu giá bị huỷ", text,
                Map.of("lotId", lot.getId()));
    }

    private List<Long> sellerIds(Long sessionId) {
        List<Long> ids = new ArrayList<>();
        for (Lot l : lotRepository.findBySessionIdOrderByLotNumberAsc(sessionId)) {
            ids.add(settlement.sellerOf(l));
        }
        return ids;
    }

    private AuctionSession lock(Long id) {
        return sessionRepository.lockById(id).orElseThrow(() -> ApiException.notFound("phiên đấu giá"));
    }
}
