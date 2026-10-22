package com.rebook.order;

import com.rebook.common.PageResponse;
import com.rebook.order.OrderDtos.AddCartRequest;
import com.rebook.order.OrderDtos.CancelRequest;
import com.rebook.order.OrderDtos.CartResponse;
import com.rebook.order.OrderDtos.CheckoutPreview;
import com.rebook.order.OrderDtos.CheckoutPreviewRequest;
import com.rebook.order.OrderDtos.CheckoutRequest;
import com.rebook.order.OrderDtos.CheckoutResponse;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.order.OrderDtos.OrderSummary;
import com.rebook.order.OrderDtos.PayRequest;
import com.rebook.order.OrderDtos.PayResponse;
import com.rebook.order.OrderDtos.ReturnCreateRequest;
import com.rebook.order.OrderDtos.ReviewRequest;
import com.rebook.order.OrderDtos.ReviewResponse;
import com.rebook.order.OrderDtos.UpdateCartRequest;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Order")
@RestController
@RequiredArgsConstructor
public class OrderController {

    private final CartService cartService;
    private final CheckoutService checkoutService;
    private final OrderService orderService;

    // ---- Giỏ hàng ----

    @Operation(summary = "Giỏ hàng (gom theo shop)")
    @GetMapping("/cart")
    public CartResponse cart(@AuthenticationPrincipal UserPrincipal me) {
        return cartService.get(me.id());
    }

    @PostMapping("/cart")
    public CartResponse addToCart(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody AddCartRequest req) {
        return cartService.add(me.id(), req.listingId(), req.quantity());
    }

    @PutMapping("/cart/{listingId}")
    public CartResponse updateCart(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long listingId,
                                   @Valid @RequestBody UpdateCartRequest req) {
        return cartService.update(me.id(), listingId, req.quantity());
    }

    @DeleteMapping("/cart/{listingId}")
    public CartResponse removeFromCart(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long listingId) {
        return cartService.remove(me.id(), listingId);
    }

    @DeleteMapping("/cart")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void clearCart(@AuthenticationPrincipal UserPrincipal me) {
        cartService.clear(me.id());
    }

    // ---- Đặt hàng ----

    @Operation(summary = "Xem trước: tách đơn theo shop + phí ship")
    @PostMapping("/orders/checkout/preview")
    public CheckoutPreview preview(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody CheckoutPreviewRequest req) {
        return checkoutService.preview(me.id(), req.addressId(), req.listingIds());
    }

    @Operation(summary = "Đặt hàng: mỗi shop một đơn, giữ hàng ngay",
            description = "COD → đơn vào thẳng PENDING_CONFIRM. WALLET → trừ ví ngay. VNPAY → trả về payment.paymentUrl, hạn 15 phút.")
    @PostMapping("/orders/checkout")
    @ResponseStatus(HttpStatus.CREATED)
    public CheckoutResponse checkout(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody CheckoutRequest req,
                                     HttpServletRequest http) {
        return checkoutService.checkout(me.id(), req, http.getRemoteAddr());
    }

    @Operation(summary = "Thanh toán đơn đang chờ (cả hoá đơn lô đấu giá) bằng WALLET hoặc VNPAY")
    @PostMapping("/orders/{id}/pay")
    public PayResponse pay(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                           @Valid @RequestBody PayRequest req, HttpServletRequest http) {
        return checkoutService.pay(me.id(), id, req.method(), http.getRemoteAddr());
    }

    // ---- Đơn của tôi ----

    @GetMapping("/orders")
    public PageResponse<OrderSummary> myOrders(@AuthenticationPrincipal UserPrincipal me,
                                               @RequestParam(required = false) OrderStatus status,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "20") int size) {
        return orderService.buyerOrders(me.id(), status, page, size);
    }

    @Operation(summary = "Chi tiết đơn + lịch sử trạng thái")
    @GetMapping("/orders/{id}")
    public OrderDetail detail(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return orderService.detail(me.id(), me.isStaffOrAdmin(), id);
    }

    @Operation(summary = "Huỷ đơn (chưa xác nhận) hoặc gửi yêu cầu huỷ (đã xác nhận)")
    @PostMapping("/orders/{id}/cancel")
    public OrderDetail cancel(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                              @Valid @RequestBody CancelRequest req) {
        return orderService.buyerCancel(me.id(), id, req.reason());
    }

    @Operation(summary = "Xác nhận đã nhận hàng → hoàn tất, giải ngân cho người bán")
    @PostMapping("/orders/{id}/confirm-received")
    public OrderDetail confirmReceived(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return orderService.confirmReceived(me.id(), id);
    }

    @Operation(summary = "Yêu cầu trả hàng (chỉ khi sách khác mô tả)")
    @PostMapping("/orders/{id}/return")
    public OrderDetail requestReturn(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                     @Valid @RequestBody ReturnCreateRequest req) {
        return orderService.requestReturn(me.id(), id, req);
    }

    @Operation(summary = "Đánh giá shop (1–5 sao, mỗi đơn một lần)")
    @PostMapping("/orders/{id}/review")
    @ResponseStatus(HttpStatus.CREATED)
    public ReviewResponse review(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                 @Valid @RequestBody ReviewRequest req) {
        return orderService.review(me.id(), id, req);
    }

    @Operation(summary = "Đánh giá của shop (công khai)")
    @GetMapping("/shops/{shopId}/reviews")
    public PageResponse<ReviewResponse> shopReviews(@PathVariable Long shopId,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return orderService.shopReviews(shopId, page, size);
    }
}
