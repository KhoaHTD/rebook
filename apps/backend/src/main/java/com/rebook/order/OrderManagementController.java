package com.rebook.order;

import com.rebook.common.PageResponse;
import com.rebook.order.OrderDtos.CancelRequest;
import com.rebook.order.OrderDtos.DecisionRequest;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.order.OrderDtos.OrderSummary;
import com.rebook.order.OrderDtos.ReturnResponse;
import com.rebook.order.OrderDtos.ShipRequest;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Xử lý đơn: người bán với đơn thường (/seller/orders), Staff kho với đơn đấu giá (/staff/orders),
 * Admin phân xử trả hàng (/admin/disputes). Giao hàng là giả lập bằng nút bấm.
 */
@Tag(name = "Order management")
@RestController
@RequiredArgsConstructor
public class OrderManagementController {

    private final OrderService orderService;

    // ---- Người bán ----

    @GetMapping("/seller/orders")
    public PageResponse<OrderSummary> sellerOrders(@AuthenticationPrincipal UserPrincipal me,
                                                   @RequestParam(required = false) OrderStatus status,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        return orderService.shopOrders(me.id(), status, page, size);
    }

    @Operation(summary = "Xác nhận đơn (trong 24h)")
    @PostMapping("/seller/orders/{id}/confirm")
    public OrderDetail sellerConfirm(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return orderService.confirm(me.id(), false, id);
    }

    @Operation(summary = "Đã giao cho shipper (nhập mã vận đơn, bỏ trống để tự sinh)")
    @PostMapping("/seller/orders/{id}/ship")
    public OrderDetail sellerShip(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                  @Valid @RequestBody(required = false) ShipRequest req) {
        return orderService.ship(me.id(), false, id, req == null ? null : req.trackingCode());
    }

    @Operation(summary = "[Giả lập] Đã giao thành công")
    @PostMapping("/seller/orders/{id}/delivered")
    public OrderDetail sellerDelivered(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return orderService.markDelivered(me.id(), false, id);
    }

    @Operation(summary = "[Giả lập] Giao thất bại")
    @PostMapping("/seller/orders/{id}/delivery-failed")
    public OrderDetail sellerFailed(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                    @Valid @RequestBody CancelRequest req) {
        return orderService.markDeliveryFailed(me.id(), false, id, req.reason());
    }

    @PostMapping("/seller/orders/{id}/cancel")
    public OrderDetail sellerCancel(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                    @Valid @RequestBody CancelRequest req) {
        return orderService.sellerCancel(me.id(), id, req.reason());
    }

    @Operation(summary = "Đồng ý / từ chối yêu cầu huỷ của người mua")
    @PostMapping("/seller/orders/{id}/cancel-request")
    public OrderDetail respondCancel(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                     @Valid @RequestBody DecisionRequest req) {
        return orderService.respondCancelRequest(me.id(), id, req.approve(), req.note());
    }

    @Operation(summary = "Đồng ý / từ chối trả hàng (từ chối → Admin phân xử)")
    @PostMapping("/seller/orders/{id}/return-decision")
    public OrderDetail sellerReturnDecision(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                            @Valid @RequestBody DecisionRequest req) {
        return orderService.respondReturn(me.id(), false, id, req.approve(), req.note());
    }

    // ---- Staff kho: đơn lô đấu giá ----

    @Operation(summary = "[Staff] Đơn lô đấu giá cần xuất kho / giao")
    @GetMapping("/staff/orders")
    public PageResponse<OrderSummary> auctionOrders(@RequestParam(required = false) OrderStatus status,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return orderService.auctionOrders(status, page, size);
    }

    @PostMapping("/staff/orders/{id}/confirm")
    public OrderDetail staffConfirm(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return orderService.confirm(me.id(), true, id);
    }

    @Operation(summary = "[Staff] Xuất kho, giao cho shipper")
    @PostMapping("/staff/orders/{id}/ship")
    public OrderDetail staffShip(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                 @Valid @RequestBody(required = false) ShipRequest req) {
        return orderService.ship(me.id(), true, id, req == null ? null : req.trackingCode());
    }

    @Operation(summary = "[Staff] Giao thành công / bàn giao tại kho")
    @PostMapping("/staff/orders/{id}/delivered")
    public OrderDetail staffDelivered(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return orderService.markDelivered(me.id(), true, id);
    }

    @PostMapping("/staff/orders/{id}/delivery-failed")
    public OrderDetail staffFailed(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                   @Valid @RequestBody CancelRequest req) {
        return orderService.markDeliveryFailed(me.id(), true, id, req.reason());
    }

    @Operation(summary = "[Staff] Xử lý trả hàng lô đấu giá (sàn chịu trách nhiệm)")
    @PostMapping("/staff/orders/{id}/return-decision")
    public OrderDetail staffReturnDecision(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                           @Valid @RequestBody DecisionRequest req) {
        return orderService.respondReturn(me.id(), true, id, req.approve(), req.note());
    }

    // ---- Admin ----

    @Operation(summary = "[Admin] Khiếu nại trả hàng chờ phân xử")
    @GetMapping("/admin/disputes")
    public PageResponse<ReturnResponse> disputes(@RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return orderService.disputes(page, size);
    }

    @Operation(summary = "[Admin] Phân xử: approve=true hoàn tiền người mua, false giữ đơn hoàn tất")
    @PostMapping("/admin/disputes/{orderId}/resolve")
    public OrderDetail resolve(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long orderId,
                               @Valid @RequestBody DecisionRequest req) {
        return orderService.resolveDispute(me.id(), orderId, req.approve(), req.note());
    }
}
