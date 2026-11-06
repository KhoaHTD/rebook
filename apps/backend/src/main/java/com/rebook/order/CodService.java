package com.rebook.order;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.wallet.Payment;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.EnumSet;
import java.util.Set;

/**
 * Đối soát COD theo mô hình sàn thương mại điện tử: hãng vận chuyển thu hộ tiền mặt, rồi chuyển cho sàn theo đợt.
 * Chỉ khi sàn xác nhận đã NHẬN tiền (Admin nhập ở đây) tiền mới vào ví sàn; từ đó mới trả shop (sau khi đơn hoàn tất,
 * trừ phí) hoặc hoàn người mua (nếu trả hàng). Nhờ vậy ví không bao giờ có tiền mà sàn chưa thực nhận.
 */
@Service
@RequiredArgsConstructor
public class CodService {

    /** Các trạng thái mà hãng vận chuyển đã thu tiền mặt của người mua. */
    private static final Set<OrderStatus> COLLECTED = EnumSet.of(OrderStatus.DELIVERED, OrderStatus.COMPLETED,
            OrderStatus.RETURN_REQUESTED, OrderStatus.RETURNED);

    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final OrderSettlement settlement;
    private final WalletService walletService;
    private final AuditLog audit;

    public record CodPendingResponse(Long orderId, String code, OrderStatus status, BigDecimal total, Instant deliveredAt,
                                     boolean refundPending) {
    }

    /** Đơn COD đã giao nhưng sàn chưa nhận tiền đối soát, giao lâu nhất trước. */
    @Transactional(readOnly = true)
    public PageResponse<CodPendingResponse> pending(int page, int size) {
        return PageResponse.of(orderRepository.findCodAwaitingRemittance(PageRequest.of(page, size)),
                o -> new CodPendingResponse(o.getId(), o.getCode(), o.getStatus(), o.getTotal(), o.getDeliveredAt(),
                        o.isCodRefundPending()));
    }

    /** Admin xác nhận sàn đã nhận đúng số tiền COD của đơn từ hãng vận chuyển. */
    @Transactional
    public OrderDetail remit(Long adminId, Long orderId, BigDecimal amount, String reference) {
        Order o = orderService.lock(orderId);
        if (o.getPaymentMethod() != Payment.Method.COD) {
            throw ApiException.badRequest("NOT_COD", "Đơn này không phải đơn COD");
        }
        if (o.getCodRemittedAt() != null) {
            throw ApiException.conflict("ALREADY_REMITTED", "Đơn này đã đối soát COD");
        }
        if (!COLLECTED.contains(o.getStatus())) {
            throw ApiException.conflict("COD_NOT_COLLECTED", "Đơn chưa giao thành công nên hãng vận chuyển chưa thu tiền");
        }
        if (amount == null || amount.compareTo(o.getTotal()) != 0) {
            audit.recordDenied(EventCode.COD_REMITTED, "COD_AMOUNT_MISMATCH", "ORDER", o.getId(),
                    "Số tiền đối soát COD không khớp", "orderCode", o.getCode(), "expected", o.getTotal(), "received", amount);
            throw ApiException.badRequest("COD_AMOUNT_MISMATCH",
                    "Số tiền đối soát phải đúng " + o.getTotal().toPlainString() + "đ");
        }
        walletService.credit(null, WalletTxType.COD_RECEIPT, o.getTotal(), "ORDER", o.getId(),
                "Nhận tiền COD đối soát đơn " + o.getCode() + (reference == null || reference.isBlank() ? "" : " (" + reference.trim() + ")"));
        o.setCodRemittedAt(Instant.now());
        audit.record(EventCode.COD_REMITTED, "ORDER", o.getId(), o.getCode(), "Sàn nhận tiền COD đối soát",
                "amount", o.getTotal(), "reference", reference, "status", o.getStatus(), "adminId", adminId);
        if (o.getStatus() == OrderStatus.COMPLETED) {
            settlement.payOutCod(o); // đơn đã hoàn tất từ trước, chỉ chờ tiền về
        } else if (o.getStatus() == OrderStatus.RETURNED && o.isCodRefundPending()) {
            settlement.refundCod(o); // trả hàng đã chấp nhận từ trước, chỉ chờ tiền về
        }
        return orderService.toDetail(o);
    }
}
