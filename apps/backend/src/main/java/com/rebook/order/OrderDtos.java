package com.rebook.order;

import com.rebook.wallet.Payment;
import com.rebook.wallet.PaymentService.PaymentResponse;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class OrderDtos {

    private OrderDtos() {
    }

    // ---- Giỏ hàng ----

    public record AddCartRequest(@NotNull Long listingId, @NotNull @Min(1) @Max(99) Integer quantity) {
    }

    public record UpdateCartRequest(@NotNull @Min(1) @Max(99) Integer quantity) {
    }

    /** available = false khi tin đã ngừng bán hoặc không đủ hàng. */
    public record CartLine(Long listingId, String title, String author, String coverUrl, BigDecimal price,
                           int quantity, int stock, boolean available, BigDecimal lineTotal) {
    }

    public record CartShopGroup(Long shopId, String shopName, String shopProvince, List<CartLine> items,
                                BigDecimal subtotal) {
    }

    public record CartResponse(List<CartShopGroup> shops, int totalQuantity, BigDecimal subtotal) {
    }

    // ---- Checkout ----

    /** listingIds = null → đặt toàn bộ giỏ. paymentMethod: COD | WALLET | ZALOPAY. */
    /** expectedTotal: tổng tiền người mua thấy ở bước xem trước; gửi kèm thì giá đổi sẽ bị từ chối (PRICE_CHANGED). */
    public record CheckoutRequest(@NotNull Long addressId, @NotNull Payment.Method paymentMethod,
                                  List<Long> listingIds, @Size(max = 500) String note, java.math.BigDecimal expectedTotal) {
    }

    public record CheckoutPreviewRequest(@NotNull Long addressId, List<Long> listingIds) {
    }

    public record ShopQuote(Long shopId, String shopName, BigDecimal subtotal, BigDecimal shippingFee, BigDecimal total) {
    }

    public record CheckoutPreview(List<ShopQuote> shops, BigDecimal subtotal, BigDecimal shippingFee, BigDecimal total) {
    }

    /** payment != null khi cần thanh toán qua ZaloPay: mở payment.paymentUrl. */
    public record CheckoutResponse(List<OrderSummary> orders, PaymentResponse payment) {
    }

    public record PayRequest(@NotNull Payment.Method method) {
    }

    public record PayResponse(OrderSummary order, PaymentResponse payment) {
    }

    // ---- Đơn hàng ----

    public record OrderSummary(Long id, String code, Order.Type orderType, OrderStatus status, Long shopId,
                               String shopName, Long buyerId, int itemCount, String firstItemTitle, String coverUrl,
                               BigDecimal total, BigDecimal amountDue, Payment.Method paymentMethod,
                               boolean paid, boolean cancelRequested, Instant paymentDueAt, Instant createdAt,
                               Long lotId, boolean secondChance) {
    }

    public record OrderItemResponse(Long id, Long listingId, Long lotId, String title, String imageUrl,
                                    BigDecimal unitPrice, int quantity, BigDecimal lineTotal) {
    }

    public record HistoryResponse(OrderStatus fromStatus, OrderStatus toStatus, Long actorId, String note,
                                  Instant createdAt) {
    }

    public record OrderDetail(Long id, String code, Order.Type orderType, OrderStatus status, Long buyerId,
                              Long shopId, String shopName, Long lotId, List<OrderItemResponse> items,
                              BigDecimal subtotal, BigDecimal shippingFee, BigDecimal buyerPremium,
                              BigDecimal depositApplied, BigDecimal total, BigDecimal amountDue,
                              Payment.Method paymentMethod, Instant paidAt, Map<String, Object> address,
                              boolean pickupAtWarehouse, String trackingCode, String note, String cancelReason,
                              boolean cancelRequested, boolean secondChance, Instant paymentDueAt,
                              Instant confirmDueAt, Instant deliveredAt, Instant completedAt, Instant cancelledAt,
                              Instant createdAt, List<HistoryResponse> history, ReturnResponse returnRequest,
                              boolean reviewed, boolean canReview, boolean canRequestReturn) {
    }

    @io.swagger.v3.oas.annotations.media.Schema(name = "ReasonRequest")
    public record CancelRequest(@NotBlank @Size(max = 500) String reason) {
    }

    /** fault: ai gây giao thất bại. BUYER = người mua từ chối nhận, sai địa chỉ, không liên lạc được. Không gửi = không rõ, coi như không phải lỗi người mua. */
    public record DeliveryFailedRequest(@NotBlank @Size(max = 500) String reason, Order.DeliveryFault fault) {
    }

    public record ShipRequest(@Size(max = 50) String trackingCode) {
    }

    public record DecisionRequest(boolean approve, @Size(max = 1000) String note) {
    }

    // ---- Trả hàng ----

    public record ReturnCreateRequest(@NotNull ReturnRequest.Reason reason,
                                      @NotBlank @Size(max = 1000) String description,
                                      // Bắt buộc 1–10 ảnh, trừ lý do NOT_RECEIVED (kiểm ở OrderService.requestReturn)
                                      @Size(max = 10, message = "Tối đa 10 ảnh minh chứng") List<@NotBlank String> images) {
    }

    /**
     * respondBy: hạn người bán / kho trả lời (chỉ khi còn chờ trả lời).
     * resolvedBy / resolvedByName / resolvedAt: Admin phân xử và lúc nào.
     */
    public record ReturnResponse(Long id, Long orderId, ReturnRequest.Reason reason, String description,
                                 List<String> images, ReturnRequest.Status status, String sellerNote,
                                 String resolution, Instant createdAt, Instant respondBy, Long resolvedBy,
                                 String resolvedByName, Instant resolvedAt, String returnTrackingCode,
                                 Instant returnShippedAt, Instant returnReceivedAt, Instant shipBy,
                                 String returnToName, String returnToAddress) {

        public static ReturnResponse of(ReturnRequest r, Instant respondBy, Instant shipBy, String resolvedByName,
                                        String returnToName, String returnToAddress) {
            return new ReturnResponse(r.getId(), r.getOrderId(), r.getReason(), r.getDescription(), r.getImages(),
                    r.getStatus(), r.getSellerNote(), r.getResolution(), r.getCreatedAt(), respondBy,
                    r.getResolvedBy(), resolvedByName, r.getResolvedAt(), r.getReturnTrackingCode(),
                    r.getReturnShippedAt(), r.getReturnReceivedAt(), shipBy, returnToName, returnToAddress);
        }
    }

    /** Đơn thường đang giao để Staff đối chiếu với hãng vận chuyển; overdue = giao quá lâu mà chưa có kết quả. */
    public record InTransitOrder(Long orderId, String code, Long shopId, String shopName, Long buyerId,
                                 Payment.Method paymentMethod, BigDecimal total, String trackingCode, Instant shippedAt,
                                 boolean overdue) {
    }

    /** Người mua gửi hàng trả: mã vận đơn. */
    public record ReturnShipmentRequest(@NotBlank @Size(max = 50) String trackingCode) {
    }

    // ---- Đánh giá ----

    public record ReviewRequest(@NotNull @Min(1) @Max(5) Integer rating, @Size(max = 1000) String comment) {
    }

    public record ReviewResponse(Long id, Long orderId, String reviewerName, int rating, String comment,
                                 Instant createdAt) {
    }
}
