package com.rebook.consignment;

import com.rebook.auction.Lot;
import com.rebook.auction.LotRepository;
import com.rebook.auction.LotStatus;
import com.rebook.catalog.Book;
import com.rebook.catalog.BookService;
import com.rebook.catalog.CatalogDtos.BookResponse;
import com.rebook.catalog.Listing;
import com.rebook.catalog.ListingRepository;
import com.rebook.catalog.ListingStatus;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.common.PageResponse;
import com.rebook.consignment.ConsignmentDtos.AppointmentRequest;
import com.rebook.consignment.ConsignmentDtos.CheckInRequest;
import com.rebook.consignment.ConsignmentDtos.ConsignmentCreateRequest;
import com.rebook.consignment.ConsignmentDtos.ConsignmentResponse;
import com.rebook.consignment.ConsignmentDtos.InspectionRequest;
import com.rebook.consignment.ConsignmentDtos.InspectionResponse;
import com.rebook.consignment.ConsignmentDtos.LotBrief;
import com.rebook.consignment.ConsignmentDtos.SellerDecisionRequest;
import com.rebook.consignment.ConsignmentDtos.UnsoldDecisionRequest;
import com.rebook.consignment.ConsignmentDtos.WarehouseResponse;
import com.rebook.notification.NotificationService;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Shop;
import com.rebook.user.User;
import com.rebook.user.UserService;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

/** Giai đoạn A (ký gửi) và B (kiểm định), cùng quản lý kho. */
@Service
@RequiredArgsConstructor
public class ConsignmentService {

    private static final LocalTime OPEN_HOUR = LocalTime.of(8, 0);
    private static final LocalTime CLOSE_HOUR = LocalTime.of(17, 0);

    private final ConsignmentRepository consignmentRepository;
    private final InspectionRepository inspectionRepository;
    private final WarehouseItemRepository warehouseRepository;
    private final LotRepository lotRepository;
    private final ListingRepository listingRepository;
    private final BookService bookService;
    private final UserService userService;
    private final WalletService walletService;
    private final SystemConfigService config;
    private final NotificationService notifications;

    // =====================================================================
    // Người bán
    // =====================================================================

    @Transactional
    public ConsignmentResponse create(Long sellerId, ConsignmentCreateRequest req) {
        User seller = userService.getUser(sellerId);
        if (!seller.isEmailVerified()) {
            throw ApiException.forbidden("Cần xác thực email trước khi ký gửi");
        }
        BigDecimal min = config.decimal(SystemConfigService.CONSIGN_MIN_PRICE);
        if (req.expectedPrice().compareTo(min) < 0) {
            throw ApiException.badRequest("PRICE_TOO_LOW", "Sàn chỉ nhận ký gửi sách có giá mong muốn từ "
                    + min.toPlainString() + "đ. Sách giá thấp hơn nên đăng bán giá cố định.");
        }
        Book book = bookService.create(sellerId, req.book());
        Consignment c = new Consignment();
        c.setCode(CodeGenerator.next("KG"));
        c.setSellerId(sellerId);
        c.setBookId(book.getId());
        c.setExpectedPrice(req.expectedPrice());
        c.setProvenance(req.provenance());
        return toResponse(consignmentRepository.save(c));
    }

    @Transactional(readOnly = true)
    public List<ConsignmentResponse> mine(Long sellerId) {
        return consignmentRepository.findBySellerIdOrderByIdDesc(sellerId).stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public ConsignmentResponse detail(Long viewerId, boolean staff, Long id) {
        Consignment c = get(id);
        if (!staff && !c.getSellerId().equals(viewerId)) {
            throw ApiException.notFound("yêu cầu ký gửi");
        }
        return toResponse(c);
    }

    /** Đặt / đổi lịch hẹn mang sách tới kho (8h–17h, trong 7 ngày kể từ khi được duyệt). */
    @Transactional
    public ConsignmentResponse bookAppointment(Long sellerId, Long id, AppointmentRequest req) {
        Consignment c = requireOwned(sellerId, id);
        if (c.getStatus() != ConsignmentStatus.APPROVED && c.getStatus() != ConsignmentStatus.APPOINTMENT_BOOKED) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Chỉ đặt lịch khi yêu cầu đã được duyệt");
        }
        Instant deadline = c.getApprovedAt().plus(config.days(SystemConfigService.CONSIGN_APPOINTMENT_DAYS));
        LocalTime time = req.appointmentAt().atZone(CodeGenerator.VN).toLocalTime();
        if (req.appointmentAt().isAfter(deadline)) {
            throw ApiException.badRequest("APPOINTMENT_TOO_LATE", "Lịch hẹn phải trước " + deadline);
        }
        if (time.isBefore(OPEN_HOUR) || time.isAfter(CLOSE_HOUR)) {
            throw ApiException.badRequest("OUTSIDE_HOURS", "Kho nhận sách từ 8:00 đến 17:00");
        }
        if (c.getStatus() == ConsignmentStatus.APPROVED) {
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.APPOINTMENT_BOOKED));
            c.setAppointmentCode("AP" + CodeGenerator.random(8));
        }
        c.setAppointmentAt(req.appointmentAt());
        return toResponse(c);
    }

    /** Rút yêu cầu trước khi gửi sách tới kho. */
    @Transactional
    public ConsignmentResponse withdraw(Long sellerId, Long id) {
        Consignment c = requireOwned(sellerId, id);
        if (c.getReceivedAt() != null) {
            throw ApiException.conflict("ALREADY_RECEIVED", "Sách đã ở kho, hãy dùng quyết định sau kiểm định");
        }
        c.setStatus(c.getStatus().moveTo(ConsignmentStatus.WITHDRAWN));
        return toResponse(c);
    }

    /** Người bán chấp nhận giá đề xuất (có thể đề nghị giá sàn khác) hoặc rút sách. */
    @Transactional
    public ConsignmentResponse sellerDecision(Long sellerId, Long id, SellerDecisionRequest req) {
        Consignment c = requireOwned(sellerId, id);
        if (c.getStatus() != ConsignmentStatus.AWAITING_SELLER) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Chưa có kết quả kiểm định để quyết định");
        }
        Inspection insp = inspectionRepository.findByConsignmentId(id).orElseThrow();
        insp.setDecidedAt(Instant.now());

        if (req.decision() == ConsignmentDtos.Decision.WITHDRAW) {
            insp.setSellerDecision(Inspection.SellerDecision.WITHDRAWN);
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.WITHDRAWN));
            markReturnPending(c);
            return toResponse(c);
        }
        if (!req.agreeTerms()) {
            throw ApiException.badRequest("TERMS_REQUIRED", "Cần đồng ý hợp đồng ký gửi điện tử");
        }
        BigDecimal reserve = insp.getProposedReserve();
        if (req.counterReserve() != null) {
            if (req.counterReserve().compareTo(insp.getEstimateLow()) > 0) {
                throw ApiException.badRequest("RESERVE_TOO_HIGH", "Giá sàn không được vượt mức thấp của giá ước tính ("
                        + insp.getEstimateLow().toPlainString() + "đ)");
            }
            if (req.counterReserve().compareTo(insp.getProposedStart()) < 0) {
                throw ApiException.badRequest("RESERVE_TOO_LOW", "Giá sàn không được thấp hơn giá khởi điểm");
            }
            reserve = req.counterReserve();
            insp.setSellerCounterReserve(reserve);
            insp.setSellerDecision(Inspection.SellerDecision.COUNTER);
        } else {
            insp.setSellerDecision(Inspection.SellerDecision.ACCEPTED);
        }
        c.setStatus(c.getStatus().moveTo(ConsignmentStatus.ACCEPTED));

        // Sách vào kho chính thức, trở thành một lô chờ xếp phiên
        Lot lot = new Lot();
        lot.setConsignmentId(c.getId());
        lot.setBookId(c.getBookId());
        lot.setStartPrice(insp.getProposedStart());
        lot.setReservePrice(reserve);
        lot.setEstimateLow(insp.getEstimateLow());
        lot.setEstimateHigh(insp.getEstimateHigh());
        lotRepository.save(lot);
        return toResponse(c);
    }

    /** Lô không bán được (hoặc bị huỷ / phiên huỷ): vào phiên sau, chuyển sang bán thường, hoặc nhận lại. */
    @Transactional
    public ConsignmentResponse unsoldDecision(Long sellerId, Long id, UnsoldDecisionRequest req) {
        Consignment c = requireOwned(sellerId, id);
        Lot lot = lotRepository.findByConsignmentId(id)
                .orElseThrow(() -> ApiException.conflict("NO_LOT", "Yêu cầu ký gửi chưa có lô"));
        if (lot.getStatus() != LotStatus.UNSOLD && lot.getStatus() != LotStatus.READY
                && lot.getStatus() != LotStatus.CANCELLED) {
            throw ApiException.conflict("LOT_LOCKED", "Lô đang được xếp phiên hoặc đã bán, không thể thay đổi");
        }
        switch (req.action()) {
            case RELIST -> {
                if (lot.getRounds() >= config.integer(SystemConfigService.CONSIGN_MAX_ROUNDS)) {
                    throw ApiException.conflict("MAX_ROUNDS", "Lô đã qua số phiên tối đa, hãy chuyển sang bán giá cố định hoặc nhận lại");
                }
                if (req.newReserve() != null) {
                    if (req.newReserve().compareTo(lot.getStartPrice()) < 0 || req.newReserve().compareTo(lot.getReservePrice()) > 0) {
                        throw ApiException.badRequest("INVALID_RESERVE", "Giá sàn mới phải nằm giữa giá khởi điểm và giá sàn cũ");
                    }
                    lot.setReservePrice(req.newReserve());
                }
                if (lot.getStatus() != LotStatus.READY) {
                    lot.resetToReady();
                }
            }
            case CONVERT_TO_LISTING -> {
                Shop shop = userService.requireShop(sellerId);
                if (req.listingPrice() == null || req.listingPrice().signum() <= 0) {
                    throw ApiException.badRequest("PRICE_REQUIRED", "Nhập giá bán cố định");
                }
                // Tái dùng Book đã có (không nhập lại). Người bán nhận sách về rồi tự giao như tin thường.
                Listing listing = listingRepository.findByBookId(c.getBookId()).orElseGet(Listing::new);
                listing.setBook(bookService.get(c.getBookId()));
                listing.setShop(shop);
                listing.setPrice(req.listingPrice());
                listing.setStock(1);
                listing.setStatus(ListingStatus.PENDING_REVIEW);
                listingRepository.save(listing);
                lot.setStatus(lot.getStatus().moveTo(LotStatus.CONVERTED));
                markReturnPending(c);
            }
            case RETURN -> {
                lot.setStatus(lot.getStatus().moveTo(LotStatus.RETURNED));
                markReturnPending(c);
            }
        }
        return toResponse(c);
    }

    // =====================================================================
    // Staff
    // =====================================================================

    @Transactional(readOnly = true)
    public PageResponse<ConsignmentResponse> search(ConsignmentStatus status, int page, int size) {
        return PageResponse.of(consignmentRepository.search(status, PageRequest.of(page, size)), this::toResponse);
    }

    @Transactional(readOnly = true)
    public List<ConsignmentResponse> appointments(Instant from, Instant to) {
        return consignmentRepository.appointmentsBetween(from, to).stream().map(this::toResponse).toList();
    }

    /** Quét mã QR của lịch hẹn. */
    @Transactional(readOnly = true)
    public ConsignmentResponse byAppointmentCode(String code) {
        return toResponse(consignmentRepository.findByAppointmentCode(code)
                .orElseThrow(() -> ApiException.notFound("lịch hẹn " + code)));
    }

    /** Sơ duyệt online (48h). */
    @Transactional
    public ConsignmentResponse review(Long staffId, Long id, boolean approve, String note) {
        Consignment c = lock(id);
        c.setReviewNote(note);
        if (approve) {
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.APPROVED));
            c.setApprovedAt(Instant.now());
            notifySeller(c, "Yêu cầu ký gửi " + c.getCode() + " đã được duyệt. Hãy đặt lịch mang sách tới kho trong "
                    + config.integer(SystemConfigService.CONSIGN_APPOINTMENT_DAYS) + " ngày");
        } else {
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.REJECTED));
            notifySeller(c, "Yêu cầu ký gửi " + c.getCode() + " bị từ chối" + (note != null ? ": " + note : ""));
        }
        return toResponse(c);
    }

    /** Nhận sách tại kho: lập biên nhận, gán mã kho, ảnh lúc nhận. */
    @Transactional
    public ConsignmentResponse checkIn(Long staffId, Long id, CheckInRequest req) {
        Consignment c = lock(id);
        c.setStatus(c.getStatus().moveTo(ConsignmentStatus.RECEIVED));
        c.setReceivedAt(Instant.now());
        c.setReceivedBy(staffId);
        if (req.photoUrls() != null && !req.photoUrls().isEmpty()) {
            bookService.get(c.getBookId()).addStaffImages(req.photoUrls());
        }
        WarehouseItem w = new WarehouseItem();
        w.setConsignmentId(c.getId());
        w.setCode("WH" + CodeGenerator.random(8));
        w.setShelfCode(req.shelfCode());
        warehouseRepository.save(w);
        notifySeller(c, "Kho đã nhận sách của yêu cầu " + c.getCode() + ", đang chờ kiểm định");
        return toResponse(c);
    }

    /** Phiếu kiểm định: đạt → gửi đề xuất giá cho người bán; không đạt → người bán có 14 ngày đến nhận lại. */
    @Transactional
    public ConsignmentResponse inspect(Long staffId, Long id, InspectionRequest req) {
        Consignment c = lock(id);
        if (c.getStatus() != ConsignmentStatus.RECEIVED) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Sách chưa được nhận tại kho hoặc đã kiểm định");
        }
        Inspection insp = new Inspection();
        insp.setConsignmentId(id);
        insp.setInspectorId(staffId);
        insp.setResult(req.result());
        insp.setChecklist(req.checklist());
        insp.setConditionGrade(req.conditionGrade());
        insp.setConditionReport(req.conditionReport());

        Book book = bookService.get(c.getBookId());
        if (req.photoUrls() != null && !req.photoUrls().isEmpty()) {
            book.addStaffImages(req.photoUrls());
        }
        if (req.result() == Inspection.Result.PASS) {
            validatePricing(req);
            insp.setEstimateLow(req.estimateLow());
            insp.setEstimateHigh(req.estimateHigh());
            insp.setProposedStart(req.proposedStart());
            insp.setProposedReserve(req.proposedReserve());
            if (req.conditionGrade() != null) {
                book.setConditionGrade(req.conditionGrade()); // tình trạng theo kiểm định của sàn
            }
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.AWAITING_SELLER));
            notifySeller(c, "Sách của bạn đạt kiểm định. Giá ước tính " + req.estimateLow().toPlainString() + "–"
                    + req.estimateHigh().toPlainString() + "đ. Hãy xem và chấp nhận đề xuất");
        } else {
            insp.setSellerDecision(Inspection.SellerDecision.WITHDRAWN);
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.INSPECTION_FAILED));
            markReturnPending(c);
            notifySeller(c, "Sách không đạt kiểm định. Vui lòng đến kho nhận lại trong "
                    + config.integer(SystemConfigService.STORAGE_FREE_DAYS) + " ngày");
        }
        inspectionRepository.save(insp);
        return toResponse(c);
    }

    private static void validatePricing(InspectionRequest req) {
        if (req.estimateLow() == null || req.estimateHigh() == null || req.proposedStart() == null || req.proposedReserve() == null) {
            throw ApiException.badRequest("PRICING_REQUIRED", "Kiểm định đạt cần giá ước tính, giá khởi điểm, giá sàn");
        }
        if (req.estimateLow().compareTo(req.estimateHigh()) > 0) {
            throw ApiException.badRequest("INVALID_ESTIMATE", "Giá ước tính thấp phải ≤ giá ước tính cao");
        }
        if (req.proposedReserve().compareTo(req.estimateLow()) > 0) {
            throw ApiException.badRequest("RESERVE_TOO_HIGH", "Giá sàn không vượt mức thấp của giá ước tính");
        }
        if (req.proposedStart().compareTo(req.proposedReserve()) > 0) {
            throw ApiException.badRequest("INVALID_START", "Giá khởi điểm phải ≤ giá sàn");
        }
    }

    @Transactional(readOnly = true)
    public PageResponse<WarehouseResponse> warehouse(WarehouseItem.Status status, int page, int size) {
        return PageResponse.of(warehouseRepository.search(status, PageRequest.of(page, size)), this::toWarehouse);
    }

    @Transactional
    public WarehouseResponse updateShelf(Long warehouseId, String shelfCode) {
        WarehouseItem w = warehouseRepository.findById(warehouseId).orElseThrow(() -> ApiException.notFound("sách trong kho"));
        w.setShelfCode(shelfCode);
        return toWarehouse(w);
    }

    /** Xuất kho trả sách cho người bán, thu phí lưu kho nếu quá hạn miễn phí. */
    @Transactional
    public WarehouseResponse returnToSeller(Long staffId, Long warehouseId) {
        WarehouseItem w = warehouseRepository.findById(warehouseId).orElseThrow(() -> ApiException.notFound("sách trong kho"));
        if (w.getStatus() != WarehouseItem.Status.IN_STOCK || w.getReturnNotifiedAt() == null) {
            throw ApiException.conflict("NOT_RETURNABLE", "Sách này không ở trạng thái chờ người bán nhận lại");
        }
        Consignment c = lock(w.getConsignmentId());
        long days = Duration.between(w.getReturnNotifiedAt(), Instant.now()).toDays();
        long chargeable = Math.max(0, days - config.integer(SystemConfigService.STORAGE_FREE_DAYS));
        BigDecimal fee = config.decimal(SystemConfigService.STORAGE_PER_DAY).multiply(BigDecimal.valueOf(chargeable));
        if (fee.signum() > 0) {
            walletService.debit(c.getSellerId(), WalletTxType.FEE, fee, "WAREHOUSE", w.getId(), "Phí lưu kho quá hạn " + chargeable + " ngày");
            walletService.credit(null, WalletTxType.FEE, fee, "WAREHOUSE", w.getId(), "Phí lưu kho " + c.getCode());
        }
        w.setStorageFee(fee);
        w.setStatus(WarehouseItem.Status.RETURNED);
        w.setCheckedOutAt(Instant.now());
        w.setCheckoutReason("RETURNED_TO_SELLER");
        c.setStatus(c.getStatus().moveTo(ConsignmentStatus.RETURNED));
        notifySeller(c, "Bạn đã nhận lại sách của yêu cầu " + c.getCode());
        return toWarehouse(w);
    }

    /** Job: hết hạn yêu cầu không mang sách tới. */
    @Transactional
    public void expire(Long id) {
        Consignment c = lock(id);
        if (c.getStatus() == ConsignmentStatus.APPROVED || c.getStatus() == ConsignmentStatus.APPOINTMENT_BOOKED) {
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.EXPIRED));
            notifySeller(c, "Yêu cầu ký gửi " + c.getCode() + " đã hết hạn vì sách chưa được mang tới kho");
        }
    }

    // =====================================================================
    // Nội bộ
    // =====================================================================

    /** Đánh dấu bắt đầu tính hạn người bán đến nhận lại sách. */
    public void markReturnPending(Consignment c) {
        warehouseRepository.findByConsignmentId(c.getId()).ifPresent(w -> {
            if (w.getReturnNotifiedAt() == null) {
                w.setReturnNotifiedAt(Instant.now());
            }
        });
    }

    public Consignment get(Long id) {
        return consignmentRepository.findById(id).orElseThrow(() -> ApiException.notFound("yêu cầu ký gửi"));
    }

    private Consignment lock(Long id) {
        return consignmentRepository.lockById(id).orElseThrow(() -> ApiException.notFound("yêu cầu ký gửi"));
    }

    private Consignment requireOwned(Long sellerId, Long id) {
        Consignment c = lock(id);
        if (!c.getSellerId().equals(sellerId)) {
            throw ApiException.notFound("yêu cầu ký gửi");
        }
        return c;
    }

    private void notifySeller(Consignment c, String text) {
        notifications.notify(c.getSellerId(), NotificationService.CONSIGNMENT, "Ký gửi đấu giá", text,
                Map.of("consignmentId", c.getId()));
    }

    private WarehouseResponse toWarehouse(WarehouseItem w) {
        String title = consignmentRepository.findById(w.getConsignmentId())
                .map(c -> bookService.get(c.getBookId()).getTitle()).orElse(null);
        return WarehouseResponse.of(w, title);
    }

    public ConsignmentResponse toResponse(Consignment c) {
        Book book = bookService.get(c.getBookId());
        String sellerName = userService.getUser(c.getSellerId()).getFullName();
        InspectionResponse insp = inspectionRepository.findByConsignmentId(c.getId()).map(InspectionResponse::of).orElse(null);
        LotBrief lot = lotRepository.findByConsignmentId(c.getId()).map(LotBrief::of).orElse(null);
        WarehouseResponse wh = warehouseRepository.findByConsignmentId(c.getId())
                .map(w -> WarehouseResponse.of(w, book.getTitle())).orElse(null);
        return new ConsignmentResponse(c.getId(), c.getCode(), c.getStatus(), c.getSellerId(), sellerName,
                BookResponse.of(book), c.getExpectedPrice(), c.getProvenance(), c.getReviewNote(), c.getAppointmentAt(),
                c.getAppointmentCode(), c.getApprovedAt(), c.getReceivedAt(), insp, lot, wh, c.getCreatedAt(),
                c.getUpdatedAt());
    }
}
