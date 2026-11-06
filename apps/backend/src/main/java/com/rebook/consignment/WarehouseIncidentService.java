package com.rebook.consignment;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.auction.Lot;
import com.rebook.auction.LotRepository;
import com.rebook.auction.LotStatus;
import com.rebook.catalog.BookService;
import com.rebook.catalog.ListingRepository;
import com.rebook.catalog.ListingStatus;
import com.rebook.common.ApiException;
import com.rebook.common.Money;
import com.rebook.common.PageResponse;
import com.rebook.consignment.ConsignmentDtos.IncidentDecisionRequest;
import com.rebook.consignment.ConsignmentDtos.IncidentRequest;
import com.rebook.consignment.ConsignmentDtos.IncidentResponse;
import com.rebook.notification.NotificationService;
import com.rebook.order.Order;
import com.rebook.order.OrderRepository;
import com.rebook.order.OrderService;
import com.rebook.order.OrderStatus;
import com.rebook.system.SystemConfigService;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

/**
 * Sự cố kho: mất / hỏng sách ký gửi (docs/SRS_BO_SUNG_NGHIEP_VU.md BR-4.2, BR-4.8, BR-4.9).
 * Staff khai báo; Admin duyệt thì sàn chi bồi thường từ ví sàn theo giai đoạn của sách:
 * chưa kiểm định = giá mong muốn (có trần) · đã kiểm định = mức thấp giá ước tính ·
 * đã bán và người thắng đã trả tiền = giá búa − hoa hồng cho người bán, người mua được hoàn đủ + % giá búa.
 * Hỏng (hoặc sách đã trượt kiểm định): Admin chọn 0–100% mức trên; hỏng thì sách trả lại người bán, miễn phí lưu kho.
 * Mất sách chưa trượt kiểm định: luôn 100%.
 */
@Service
@RequiredArgsConstructor
public class WarehouseIncidentService {

    private static final String REF = "INCIDENT";
    private static final Set<WarehouseItem.Status> IN_WAREHOUSE = EnumSet.of(WarehouseItem.Status.IN_STOCK, WarehouseItem.Status.RESERVED);

    private final WarehouseIncidentRepository incidents;
    private final WarehouseItemRepository warehouseRepository;
    private final ConsignmentRepository consignmentRepository;
    private final InspectionRepository inspectionRepository;
    private final LotRepository lotRepository;
    private final ListingRepository listingRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final BookService bookService;
    private final WalletService walletService;
    private final SystemConfigService config;
    private final NotificationService notifications;
    private final AuditLog audit;

    @Transactional
    public IncidentResponse report(Long staffId, Long warehouseId, IncidentRequest req) {
        WarehouseItem w = warehouseRepository.findById(warehouseId).orElseThrow(() -> ApiException.notFound("sách trong kho"));
        if (!IN_WAREHOUSE.contains(w.getStatus())) {
            throw ApiException.conflict("NOT_IN_WAREHOUSE", "Sách không còn nằm trong kho");
        }
        if (incidents.existsByWarehouseItemIdAndStatus(w.getId(), WarehouseIncident.Status.PENDING)) {
            throw ApiException.conflict("INCIDENT_PENDING", "Cuốn này đã có sự cố đang chờ Admin duyệt");
        }
        WarehouseIncident i = new WarehouseIncident();
        i.setWarehouseItemId(w.getId());
        i.setConsignmentId(w.getConsignmentId());
        i.setType(req.type());
        i.setDescription(req.description().trim());
        i.setImages(req.photoUrls() == null ? new ArrayList<>() : new ArrayList<>(req.photoUrls()));
        i.setReportedBy(staffId);
        i = incidents.save(i);
        audit.record(EventCode.WAREHOUSE_INCIDENT_REPORTED, "WAREHOUSE", w.getId(), w.getCode(), "Khai báo sự cố kho",
                "incidentId", i.getId(), "type", req.type());
        return toResponse(i);
    }

    @Transactional(readOnly = true)
    public PageResponse<IncidentResponse> list(WarehouseIncident.Status status, int page, int size) {
        var p = PageRequest.of(page, size);
        return PageResponse.of(status == null ? incidents.findAllByOrderByIdDesc(p) : incidents.findByStatusOrderByIdDesc(status, p),
                this::toResponse);
    }

    @Transactional
    public IncidentResponse approve(Long adminId, Long id, IncidentDecisionRequest req) {
        WarehouseIncident i = lockPending(id);
        WarehouseItem w = warehouseRepository.findById(i.getWarehouseItemId()).orElseThrow();
        if (!IN_WAREHOUSE.contains(w.getStatus())) {
            throw ApiException.conflict("NOT_IN_WAREHOUSE", "Sách không còn nằm trong kho");
        }
        Consignment c = consignmentRepository.lockById(i.getConsignmentId()).orElseThrow();
        Lot lot = lotRepository.findByConsignmentId(c.getId()).flatMap(l -> lotRepository.lockById(l.getId())).orElse(null);
        if (lot != null && lot.getStatus() == LotStatus.OPEN) {
            throw ApiException.conflict("LOT_LIVE", "Lô đang được đấu, hãy huỷ lô trước khi duyệt sự cố");
        }
        if (lot != null && lot.getStatus() == LotStatus.SOLD) {
            // shortcut: chờ người thắng trả tiền (thành ca đã bán) hoặc quá hạn (lô về hàng chờ); làm huỷ hoá đơn không phạt nếu cần sớm hơn
            throw ApiException.conflict("LOT_AWAITING_PAYMENT", "Lô đang chờ người thắng thanh toán, hãy duyệt sau khi có kết quả thanh toán");
        }
        boolean lost = i.getType() == WarehouseIncident.Type.LOST;
        // Sách đã trượt kiểm định: giá người bán tự khai không đáng tin, Admin phải chọn mức như sách hỏng
        boolean failedInspection = inspectionRepository.findByConsignmentId(c.getId())
                .filter(x -> x.getResult() == Inspection.Result.FAIL).isPresent();
        int percent = lost && !failedInspection ? 100 : requirePercent(req);

        Order order = null;
        BigDecimal base;
        BigDecimal buyerAmount = BigDecimal.ZERO;
        if (lot != null && lot.getStatus() == LotStatus.PAID) {
            Long lotId = lot.getId();
            order = orderRepository.findByLotIdAndStatusNot(lotId, OrderStatus.CANCELLED).stream()
                    .filter(o -> o.getStatus() == OrderStatus.PENDING_CONFIRM || o.getStatus() == OrderStatus.PREPARING)
                    .findFirst().map(o -> orderService.lock(o.getId()))
                    .orElseThrow(() -> ApiException.conflict("NOT_IN_WAREHOUSE", "Đơn của lô đã giao đi"));
            BigDecimal hammer = order.getSubtotal();
            BigDecimal commission = Money.percent(hammer, lot.getCommissionPercent() != null ? lot.getCommissionPercent()
                    : config.decimal(SystemConfigService.SELLER_COMMISSION));
            base = hammer.subtract(commission);
            buyerAmount = Money.percent(hammer, config.decimal(SystemConfigService.COMPENSATION_BUYER_PERCENT));
            i.setStage(WarehouseIncident.Stage.SOLD_PAID);
        } else {
            Inspection insp = inspectionRepository.findByConsignmentId(c.getId())
                    .filter(x -> x.getResult() == Inspection.Result.PASS).orElse(null);
            if (insp != null) {
                base = insp.getEstimateLow();
                i.setStage(WarehouseIncident.Stage.INSPECTED);
            } else {
                base = c.getExpectedPrice().min(config.decimal(SystemConfigService.COMPENSATION_CAP_UNINSPECTED));
                i.setStage(WarehouseIncident.Stage.UNINSPECTED);
            }
        }
        BigDecimal sellerAmount = Money.percent(base, BigDecimal.valueOf(percent));
        BigDecimal platformShare = order == null ? BigDecimal.ZERO : order.getBuyerPremium().add(order.getShippingFee());
        BigDecimal need = sellerAmount.add(buyerAmount).add(platformShare);
        if (walletService.platformAvailable().compareTo(need) < 0) {
            throw ApiException.conflict("PLATFORM_FUNDS_INSUFFICIENT", "Ví sàn không đủ để chi bồi thường (cần " + need.toPlainString() + "đ)");
        }

        String what = lost ? "mất" : "hỏng";
        if (order != null) {
            // Hoàn đơn như trả hàng đơn đấu giá, rồi bồi thường thêm cho người mua
            walletService.removeHeld(c.getSellerId(), WalletTxType.REFUND, order.getSubtotal(), "ORDER", order.getId(),
                    "Huỷ tiền chờ do kho làm " + what + " sách, đơn " + order.getCode());
            walletService.debit(null, WalletTxType.REFUND, platformShare, "ORDER", order.getId(), "Hoàn phí đơn " + order.getCode());
            walletService.credit(order.getBuyerId(), WalletTxType.REFUND, order.getTotal(), "ORDER", order.getId(),
                    "Hoàn tiền đơn " + order.getCode() + " do kho làm " + what + " sách");
            pay(order.getBuyerId(), buyerAmount, i, "Bồi thường do kho làm " + what + " sách đơn " + order.getCode());
            order.setCancelReason("Kho làm " + what + " sách");
            orderService.transition(order, OrderStatus.CANCELLED, adminId, "Kho làm " + what + " sách, sàn hoàn tiền và bồi thường");
            i.setOrderId(order.getId());
            i.setBuyerId(order.getBuyerId());
            i.setBuyerAmount(buyerAmount);
            notifications.notify(order.getBuyerId(), NotificationService.ORDER, "Đơn đấu giá bị huỷ do sự cố kho",
                    "Kho làm " + what + " sách của đơn " + order.getCode() + ". Bạn được hoàn " + order.getTotal().toPlainString()
                            + "đ và bồi thường thêm " + buyerAmount.toPlainString() + "đ vào ví", Map.of("orderId", order.getId()));
        }
        pay(c.getSellerId(), sellerAmount, i, "Bồi thường do kho làm " + what + " sách (" + c.getCode() + ")");

        if (lot != null && !lot.getStatus().nextStates().isEmpty()) {
            if (lot.getStatus() == LotStatus.SCHEDULED) {
                lot.setStatus(lot.getStatus().moveTo(LotStatus.CANCELLED));
                lot.setCloseResult(Lot.CloseResult.CANCELLED);
                lot.setClosedAt(Instant.now());
            }
            lot.setStatus(lot.getStatus().moveTo(lost ? LotStatus.LOST : LotStatus.RETURNED));
        }
        if (lost) {
            w.setStatus(WarehouseItem.Status.LOST);
            w.setCheckedOutAt(Instant.now());
            w.setCheckoutReason("LOST");
            c.setStatus(c.getStatus().moveTo(ConsignmentStatus.LOST));
            // Lô đã chuyển sang bán thường: tin chờ duyệt không bao giờ duyệt được nữa → từ chối kèm lý do
            listingRepository.findByBookId(c.getBookId()).filter(l -> l.getStatus() == ListingStatus.PENDING_REVIEW).ifPresent(l -> {
                l.setStatus(l.getStatus().moveTo(ListingStatus.REJECTED));
                l.setRejectReason("Kho của sàn làm mất sách, sàn đã bồi thường");
                l.setStock(0);
            });
        } else {
            // Hỏng: trả sách lại người bán, không tính phí lưu kho
            w.setStatus(WarehouseItem.Status.IN_STOCK);
            w.setStorageFeeWaived(true);
            if (w.getReturnNotifiedAt() == null) {
                w.setReturnNotifiedAt(Instant.now());
            }
            if (c.getStatus() == ConsignmentStatus.RECEIVED || c.getStatus() == ConsignmentStatus.AWAITING_SELLER) {
                c.setStatus(c.getStatus().moveTo(ConsignmentStatus.WITHDRAWN));
            }
        }

        i.setStatus(WarehouseIncident.Status.APPROVED);
        i.setBaseAmount(base);
        i.setSellerPercent(percent);
        i.setSellerAmount(sellerAmount);
        i.setDecidedBy(adminId);
        i.setDecidedAt(Instant.now());
        i.setDecisionNote(req == null ? null : req.note());
        audit.record(EventCode.WAREHOUSE_INCIDENT_APPROVED, "WAREHOUSE", w.getId(), c.getCode(), "Duyệt sự cố kho, chi bồi thường",
                "incidentId", i.getId(), "type", i.getType(), "stage", i.getStage(), "base", base, "sellerPercent", percent,
                "sellerAmount", sellerAmount, "buyerAmount", buyerAmount, "orderId", i.getOrderId());
        notifications.notify(c.getSellerId(), NotificationService.CONSIGNMENT, "Sàn bồi thường sách ký gửi",
                "Kho làm " + what + " sách của yêu cầu " + c.getCode() + ". Bạn được bồi thường " + sellerAmount.toPlainString() + "đ vào ví"
                        + (lost ? "" : "; hãy đến kho nhận lại sách (không tính phí lưu kho)"), Map.of("consignmentId", c.getId()));
        return toResponse(i);
    }

    @Transactional
    public IncidentResponse reject(Long adminId, Long id, String reason) {
        WarehouseIncident i = lockPending(id);
        i.setStatus(WarehouseIncident.Status.REJECTED);
        i.setDecidedBy(adminId);
        i.setDecidedAt(Instant.now());
        i.setDecisionNote(reason.trim());
        audit.record(EventCode.WAREHOUSE_INCIDENT_REJECTED, "WAREHOUSE", i.getWarehouseItemId(), null, "Từ chối sự cố kho",
                "incidentId", i.getId(), "reason", reason);
        return toResponse(i);
    }

    private void pay(Long userId, BigDecimal amount, WarehouseIncident i, String note) {
        if (amount.signum() <= 0) {
            return;
        }
        walletService.debit(null, WalletTxType.COMPENSATION, amount, REF, i.getId(), note);
        walletService.credit(userId, WalletTxType.COMPENSATION, amount, REF, i.getId(), note);
    }

    private static int requirePercent(IncidentDecisionRequest req) {
        if (req == null || req.sellerPercent() == null) {
            throw ApiException.badRequest("SELLER_PERCENT_REQUIRED", "Sự cố hỏng sách hoặc sách đã trượt kiểm định cần chọn mức bồi thường 0–100%");
        }
        return req.sellerPercent();
    }

    private WarehouseIncident lockPending(Long id) {
        WarehouseIncident i = incidents.lockById(id).orElseThrow(() -> ApiException.notFound("sự cố kho"));
        if (i.getStatus() != WarehouseIncident.Status.PENDING) {
            throw ApiException.conflict("INCIDENT_DECIDED", "Sự cố đã được xử lý");
        }
        return i;
    }

    private IncidentResponse toResponse(WarehouseIncident i) {
        Consignment c = consignmentRepository.findById(i.getConsignmentId()).orElseThrow();
        return IncidentResponse.of(i, c.getCode(), bookService.get(c.getBookId()).getTitle());
    }
}
