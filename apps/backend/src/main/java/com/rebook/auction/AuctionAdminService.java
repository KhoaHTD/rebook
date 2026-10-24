package com.rebook.auction;

import com.rebook.auction.AuctionDtos.LotPublic;
import com.rebook.auction.AuctionDtos.SessionDetail;
import com.rebook.auction.AuctionDtos.SessionRequest;
import com.rebook.auction.AuctionDtos.SessionSummary;
import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Giai đoạn C — Admin tạo phiên, xếp lô, cấu hình người tối thiểu / tiền cọc / thời lượng, công bố. */
@Service
@RequiredArgsConstructor
public class AuctionAdminService {

    private final AuctionSessionRepository sessionRepository;
    private final LotRepository lotRepository;
    private final SystemConfigService config;
    private final AuctionViews views;

    @Transactional(readOnly = true)
    public PageResponse<SessionSummary> all(int page, int size) {
        return PageResponse.of(sessionRepository.findAllByOrderByStartAtDesc(PageRequest.of(page, size)), views::summary);
    }

    @Transactional(readOnly = true)
    public SessionDetail detail(Long id) {
        AuctionSession s = get(id);
        Map<Long, String> paddles = views.paddles(id);
        List<LotPublic> lots = lotRepository.findBySessionIdOrderByLotNumberAsc(id).stream()
                .map(l -> views.lotPublic(l, paddles, Set.of())).toList();
        return new SessionDetail(views.summary(s), s.getLotDurationSec(), s.getSoftCloseSec(), lots, null);
    }

    /** Lô đang chờ xếp phiên (đã qua kiểm định, người bán đã đồng ý). */
    @Transactional(readOnly = true)
    public PageResponse<LotPublic> readyLots(int page, int size) {
        return PageResponse.of(lotRepository.findByStatusOrderByCreatedAtAsc(LotStatus.READY, PageRequest.of(page, size)),
                l -> views.lotPublic(l, Map.of(), Set.of()));
    }

    @Transactional
    public SessionSummary create(Long adminId, SessionRequest req) {
        AuctionSession s = new AuctionSession();
        s.setCreatedBy(adminId);
        apply(s, req);
        return views.summary(sessionRepository.save(s));
    }

    @Transactional
    public SessionSummary update(Long id, SessionRequest req) {
        AuctionSession s = lock(id);
        if (s.getStatus() != SessionStatus.DRAFT) {
            throw ApiException.conflict("SESSION_LOCKED", "Chỉ sửa được phiên nháp");
        }
        apply(s, req);
        return views.summary(s);
    }

    /** Xếp lô theo thứ tự chạy. Lô cũ không còn trong danh sách quay về READY. */
    @Transactional
    public SessionDetail assignLots(Long id, List<Long> lotIds) {
        AuctionSession s = lock(id);
        if (s.getStatus() != SessionStatus.DRAFT) {
            throw ApiException.conflict("SESSION_LOCKED", "Chỉ xếp lô khi phiên còn là nháp");
        }
        if (new HashSet<>(lotIds).size() != lotIds.size()) {
            throw ApiException.badRequest("DUPLICATE_LOT", "Danh sách lô bị trùng");
        }
        int maxRounds = config.integer(SystemConfigService.CONSIGN_MAX_ROUNDS);
        for (Lot old : lotRepository.findBySessionIdOrderByLotNumberAsc(id)) {
            if (!lotIds.contains(old.getId())) {
                old.resetToReady();
            } else {
                old.setLotNumber(null); // tránh trùng UNIQUE(session_id, lot_number) khi đánh số lại
            }
        }
        lotRepository.flush();
        int number = 1;
        for (Long lotId : lotIds) {
            Lot lot = lotRepository.lockById(lotId).orElseThrow(() -> ApiException.notFound("lô #" + lotId));
            if (lot.getStatus() == LotStatus.READY) {
                if (lot.getRounds() >= maxRounds) {
                    throw ApiException.conflict("MAX_ROUNDS", "Lô #" + lotId + " đã qua " + maxRounds + " phiên");
                }
                lot.setStatus(lot.getStatus().moveTo(LotStatus.SCHEDULED));
                lot.setSessionId(id);
            } else if (!(lot.getStatus() == LotStatus.SCHEDULED && id.equals(lot.getSessionId()))) {
                throw ApiException.conflict("LOT_NOT_READY", "Lô #" + lotId + " không ở trạng thái chờ xếp phiên");
            }
            lot.setLotNumber(number++);
        }
        return detail(id);
    }

    /** Công bố catalogue. Từ đây lô bị khoá, người bán không rút được. */
    @Transactional
    public SessionSummary publish(Long id) {
        AuctionSession s = lock(id);
        Instant now = Instant.now();
        if (!s.getStartAt().isAfter(now) || !s.getRegistrationDeadline().isAfter(now)) {
            throw ApiException.badRequest("INVALID_SCHEDULE", "Giờ bắt đầu và hạn đăng ký phải ở tương lai");
        }
        List<Lot> lots = lotRepository.findBySessionIdOrderByLotNumberAsc(id);
        if (lots.isEmpty()) {
            throw ApiException.badRequest("NO_LOTS", "Phiên chưa có lô nào");
        }
        s.setStatus(s.getStatus().moveTo(SessionStatus.PUBLISHED));
        s.setPublishedAt(now);
        lots.forEach(l -> l.setRounds(l.getRounds() + 1));
        return views.summary(s);
    }

    private void apply(AuctionSession s, SessionRequest req) {
        Instant now = Instant.now();
        if (!req.startAt().isAfter(now) || !req.registrationDeadline().isAfter(now)) {
            throw ApiException.badRequest("INVALID_SCHEDULE", "Giờ bắt đầu và hạn đăng ký phải ở tương lai");
        }
        if (req.registrationDeadline().isAfter(req.startAt())) {
            throw ApiException.badRequest("INVALID_SCHEDULE", "Hạn đăng ký phải trước giờ bắt đầu");
        }
        s.setTitle(req.title().trim());
        s.setDescription(req.description());
        s.setCoverUrl(req.coverUrl());
        s.setStartAt(req.startAt());
        s.setRegistrationDeadline(req.registrationDeadline());
        s.setMinParticipants(req.minParticipants());
        s.setDepositAmount(req.depositAmount());
        s.setLotDurationSec(req.lotDurationSec() == null ? 60 : req.lotDurationSec());
        s.setSoftCloseSec(req.softCloseSec() == null ? 15 : req.softCloseSec());
        s.setLotGapSec(req.lotGapSec() == null ? 7 : req.lotGapSec());
    }

    private AuctionSession get(Long id) {
        return sessionRepository.findById(id).orElseThrow(() -> ApiException.notFound("phiên đấu giá"));
    }

    private AuctionSession lock(Long id) {
        return sessionRepository.lockById(id).orElseThrow(() -> ApiException.notFound("phiên đấu giá"));
    }
}
