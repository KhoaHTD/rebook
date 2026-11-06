package com.rebook.order;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.common.PageResponse;
import com.rebook.notification.NotificationService;
import com.rebook.order.OrderDtos.HistoryResponse;
import com.rebook.order.OrderDtos.InTransitOrder;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.order.OrderDtos.OrderItemResponse;
import com.rebook.order.OrderDtos.OrderSummary;
import com.rebook.order.OrderDtos.ReturnCreateRequest;
import com.rebook.order.OrderDtos.ReturnResponse;
import com.rebook.order.OrderDtos.ReviewRequest;
import com.rebook.order.OrderDtos.ReviewResponse;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Shop;
import com.rebook.user.ShopRepository;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import com.rebook.user.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Vòng đời đơn hàng. Mọi lần đổi trạng thái đi qua {@link #transition}: kiểm luồng hợp lệ (409 nếu sai),
 * ghi lịch sử, phát {@link OrderStatusChangedEvent} để xử lý tiền / tồn kho, gửi thông báo.
 */
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderStatusHistoryRepository historyRepository;
    private final ReviewRepository reviewRepository;
    private final ReturnRequestRepository returnRepository;
    private final ShopRepository shopRepository;
    private final UserRepository userRepository;
    private final UserService userService;
    private final SystemConfigService config;
    private final NotificationService notifications;
    private final ApplicationEventPublisher events;
    private final AuditLog audit;
    private final ShopReputation reputation;

    private static final Set<OrderStatus> STAFF_HANDLED = EnumSet.of(OrderStatus.PENDING_CONFIRM, OrderStatus.PREPARING,
            OrderStatus.SHIPPING);

    // =====================================================================
    // Lõi
    // =====================================================================

    @Transactional
    public Order transition(Order o, OrderStatus to, Long actorId, String note) {
        OrderStatus from = o.getStatus();
        o.setStatus(from.moveTo(to));
        Instant now = Instant.now();
        switch (to) {
            case SHIPPING -> o.setShippedAt(now);
            case DELIVERED -> o.setDeliveredAt(now);
            case COMPLETED -> o.setCompletedAt(now);
            case CANCELLED, FAILED_DELIVERY, RETURNED -> o.setCancelledAt(now);
            default -> {
            }
        }
        recordHistory(o, from, to, actorId, note);
        audit.record(EventCode.ORDER_STATUS_CHANGED, "ORDER", o.getId(), o.getCode(), note,
                "from", from, "to", to, "orderType", o.getOrderType(), "paymentMethod", o.getPaymentMethod(),
                "total", o.getTotal());
        events.publishEvent(new OrderStatusChangedEvent(o, from, to, actorId));
        notifyBuyer(o, to);
        return o;
    }

    public void recordHistory(Order o, OrderStatus from, OrderStatus to, Long actorId, String note) {
        OrderStatusHistory h = new OrderStatusHistory();
        h.setOrderId(o.getId());
        h.setFromStatus(from);
        h.setToStatus(to);
        h.setActorId(actorId);
        h.setNote(note);
        historyRepository.save(h);
    }

    public static String newCode() {
        return CodeGenerator.next("OD");
    }

    public Order lock(Long orderId) {
        return orderRepository.lockById(orderId).orElseThrow(() -> ApiException.notFound("đơn hàng"));
    }

    private void notifyBuyer(Order o, OrderStatus to) {
        String text = switch (to) {
            case PENDING_CONFIRM -> "Đơn " + o.getCode() + " đã được đặt, chờ xác nhận";
            case PREPARING -> "Đơn " + o.getCode() + " đã được xác nhận và đang đóng gói";
            case SHIPPING -> "Đơn " + o.getCode() + " đang được giao";
            case DELIVERED -> "Đơn " + o.getCode() + " đã giao thành công. Bấm \"Đã nhận hàng\" trong "
                    + config.integer(SystemConfigService.AUTO_COMPLETE_DAYS) + " ngày";
            case COMPLETED -> "Đơn " + o.getCode() + " đã hoàn tất. Hãy đánh giá shop nhé!";
            case CANCELLED -> "Đơn " + o.getCode() + " đã bị huỷ";
            case RETURNED -> "Yêu cầu trả hàng đơn " + o.getCode() + " đã được chấp nhận, tiền đã hoàn vào ví";
            case FAILED_DELIVERY -> "Giao đơn " + o.getCode() + " không thành công";
            default -> null;
        };
        if (text != null) {
            notifications.notify(o.getBuyerId(), NotificationService.ORDER, "Cập nhật đơn hàng", text,
                    Map.of("orderId", o.getId(), "status", to.name()));
        }
    }

    private void notifyShop(Order o, String text) {
        if (o.getShopId() != null) {
            shopRepository.findById(o.getShopId()).ifPresent(s -> notifications.notify(s.getUserId(),
                    NotificationService.ORDER, "Đơn hàng của shop", text, Map.of("orderId", o.getId())));
        }
    }

    // =====================================================================
    // Truy vấn
    // =====================================================================

    @Transactional(readOnly = true)
    public PageResponse<OrderSummary> buyerOrders(Long userId, OrderStatus status, int page, int size) {
        return toSummaries(orderRepository.findForBuyer(userId, status, PageRequest.of(page, size)));
    }

    @Transactional(readOnly = true)
    public PageResponse<OrderSummary> shopOrders(Long userId, OrderStatus status, int page, int size) {
        Shop shop = userService.requireShop(userId);
        return toSummaries(orderRepository.findForShop(shop.getId(), status, PageRequest.of(page, size)));
    }

    @Transactional(readOnly = true)
    public PageResponse<OrderSummary> auctionOrders(OrderStatus status, int page, int size) {
        return toSummaries(orderRepository.findAuctionOrders(status, PageRequest.of(page, size)));
    }

    /** Người mua, chủ shop của đơn, hoặc Staff/Admin được xem. */
    @Transactional(readOnly = true)
    public OrderDetail detail(Long viewerId, boolean staff, Long orderId) {
        Order o = orderRepository.findById(orderId).orElseThrow(() -> ApiException.notFound("đơn hàng"));
        boolean isBuyer = o.getBuyerId().equals(viewerId);
        boolean isSeller = o.getShopId() != null && shopRepository.findById(o.getShopId())
                .map(s -> s.getUserId().equals(viewerId)).orElse(false);
        if (!isBuyer && !isSeller && !staff) {
            throw ApiException.notFound("đơn hàng");
        }
        return toDetail(o);
    }

    public OrderDetail toDetail(Order o) {
        String shopName = o.getShopId() == null ? "Kho ReBook" : shopRepository.findById(o.getShopId()).map(Shop::getName).orElse(null);
        var history = historyRepository.findByOrderIdOrderByIdAsc(o.getId()).stream()
                .map(h -> new HistoryResponse(h.getFromStatus(), h.getToStatus(), h.getActorId(), h.getNote(), h.getCreatedAt()))
                .toList();
        var items = o.getItems().stream().map(i -> new OrderItemResponse(i.getId(), i.getListingId(), i.getLotId(),
                i.getTitleSnapshot(), i.getImageSnapshot(), i.getUnitPrice(), i.getQuantity(), i.lineTotal())).toList();
        ReturnResponse ret = returnRepository.findByOrderId(o.getId()).map(this::returnView).orElse(null);
        boolean reviewed = reviewRepository.existsByOrderId(o.getId());
        boolean canReview = !reviewed && o.getStatus() == OrderStatus.COMPLETED && o.getOrderType() == Order.Type.NORMAL;
        boolean canReturn = o.getStatus() == OrderStatus.DELIVERED && withinComplaintWindow(o);
        return new OrderDetail(o.getId(), o.getCode(), o.getOrderType(), o.getStatus(), o.getBuyerId(), o.getShopId(),
                shopName, o.getLotId(), items, o.getSubtotal(), o.getShippingFee(), o.getBuyerPremium(),
                o.getDepositApplied(), o.getTotal(), o.amountDue(), o.getPaymentMethod(), o.getPaidAt(),
                o.getAddressSnapshot(), o.isPickupAtWarehouse(), o.getTrackingCode(), o.getNote(), o.getCancelReason(),
                o.isCancelRequested(), o.isSecondChance(), o.getPaymentDueAt(), o.getConfirmDueAt(), o.getDeliveredAt(),
                o.getCompletedAt(), o.getCancelledAt(), o.getCreatedAt(), history, ret, reviewed, canReview, canReturn);
    }

    public PageResponse<OrderSummary> toSummaries(Page<Order> page) {
        Set<Long> shopIds = page.getContent().stream().map(Order::getShopId).filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());
        Map<Long, String> shopNames = shopRepository.findAllById(shopIds).stream()
                .collect(Collectors.toMap(Shop::getId, Shop::getName));
        return PageResponse.of(page, o -> toSummary(o, shopNames));
    }

    public OrderSummary toSummary(Order o, Map<Long, String> shopNames) {
        OrderItem first = o.getItems().isEmpty() ? null : o.getItems().getFirst();
        String shopName = o.getShopId() == null ? "Kho ReBook" : shopNames.get(o.getShopId());
        return new OrderSummary(o.getId(), o.getCode(), o.getOrderType(), o.getStatus(), o.getShopId(), shopName,
                o.getBuyerId(), o.getItems().stream().mapToInt(OrderItem::getQuantity).sum(),
                first == null ? null : first.getTitleSnapshot(), first == null ? null : first.getImageSnapshot(),
                o.getTotal(), o.amountDue(), o.getPaymentMethod(), o.getPaidAt() != null, o.isCancelRequested(),
                o.getPaymentDueAt(), o.getCreatedAt(), o.getLotId(), o.isSecondChance());
    }

    public OrderSummary toSummary(Order o) {
        Map<Long, String> names = o.getShopId() == null ? Map.of()
                : shopRepository.findById(o.getShopId()).map(s -> Map.of(s.getId(), s.getName())).orElse(Map.of());
        return toSummary(o, names);
    }

    // =====================================================================
    // Người mua
    // =====================================================================

    /** Huỷ tự do khi chưa xác nhận; đã xác nhận (PREPARING) thì gửi yêu cầu huỷ để shop đồng ý. */
    @Transactional
    public OrderDetail buyerCancel(Long userId, Long orderId, String reason) {
        Order o = requireBuyerOrder(userId, orderId);
        if (o.getOrderType() == Order.Type.AUCTION) {
            throw ApiException.conflict("AUCTION_ORDER", "Không thể huỷ hoá đơn lô đấu giá đã thắng");
        }
        switch (o.getStatus()) {
            case PENDING_PAYMENT, PENDING_CONFIRM -> {
                o.setCancelReason(reason);
                transition(o, OrderStatus.CANCELLED, userId, "Người mua huỷ: " + reason);
            }
            case PREPARING -> {
                if (o.isCancelRequested()) {
                    throw ApiException.conflict("ALREADY_REQUESTED", "Đã gửi yêu cầu huỷ, chờ shop phản hồi");
                }
                o.setCancelRequested(true);
                o.setCancelRequestedAt(Instant.now());
                o.setCancelReason(reason);
                recordHistory(o, o.getStatus(), o.getStatus(), userId, "Người mua yêu cầu huỷ: " + reason);
                notifyShop(o, "Người mua yêu cầu huỷ đơn " + o.getCode() + ": " + reason);
            }
            default -> throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Đơn đã giao cho vận chuyển, không thể huỷ");
        }
        return toDetail(o);
    }

    @Transactional
    public OrderDetail confirmReceived(Long userId, Long orderId) {
        Order o = requireBuyerOrder(userId, orderId);
        if (o.getStatus() == OrderStatus.RETURN_REQUESTED) {
            // Người mua rút yêu cầu trả hàng: đóng yêu cầu để không còn treo chờ người bán / Admin
            returnRepository.findByOrderId(orderId)
                    .filter(x -> x.getStatus() == ReturnRequest.Status.PENDING || x.getStatus() == ReturnRequest.Status.DISPUTED
                            || x.getStatus() == ReturnRequest.Status.AWAITING_GOODS)
                    .ifPresent(x -> {
                        x.setStatus(ReturnRequest.Status.REJECTED);
                        x.setResolution("Người mua rút yêu cầu, đã xác nhận nhận hàng");
                    });
        }
        if (o.getStatus() == OrderStatus.SHIPPING) {
            // Chưa có hãng vận chuyển thật: người mua xác nhận đã nhận thì coi là giao thành công rồi hoàn tất
            transition(o, OrderStatus.DELIVERED, userId, "Người mua xác nhận đã nhận hàng");
            audit.record(EventCode.ORDER_DELIVERY_CONFIRMED, "ORDER", o.getId(), o.getCode(), "Người mua xác nhận đã nhận hàng khi đang giao",
                    "shipToConfirmSec", o.getShippedAt() == null ? null : Duration.between(o.getShippedAt(), Instant.now()).toSeconds());
        }
        transition(o, OrderStatus.COMPLETED, userId, "Người mua xác nhận đã nhận hàng");
        return toDetail(o);
    }

    @Transactional
    public OrderDetail requestReturn(Long userId, Long orderId, ReturnCreateRequest req) {
        Order o = requireBuyerOrder(userId, orderId);
        if (o.getStatus() != OrderStatus.DELIVERED || !withinComplaintWindow(o)) {
            throw ApiException.conflict("RETURN_NOT_ALLOWED", "Chỉ yêu cầu trả hàng trong thời hạn khiếu nại sau khi giao");
        }
        ReturnRequest r = new ReturnRequest();
        r.setOrderId(o.getId());
        r.setReason(req.reason());
        r.setDescription(req.description());
        r.setImages(req.images());
        returnRepository.save(r);
        transition(o, OrderStatus.RETURN_REQUESTED, userId, "Yêu cầu trả hàng: " + req.reason());
        notifyShop(o, "Đơn " + o.getCode() + " có yêu cầu trả hàng");
        return toDetail(o);
    }

    @Transactional
    public ReviewResponse review(Long userId, Long orderId, ReviewRequest req) {
        Order o = requireBuyerOrder(userId, orderId);
        if (o.getStatus() != OrderStatus.COMPLETED || o.getOrderType() != Order.Type.NORMAL) {
            throw ApiException.conflict("REVIEW_NOT_ALLOWED", "Chỉ đánh giá được đơn mua thường đã hoàn tất");
        }
        if (reviewRepository.existsByOrderId(orderId)) {
            throw ApiException.conflict("ALREADY_REVIEWED", "Đơn này đã được đánh giá");
        }
        Review r = new Review();
        r.setOrderId(orderId);
        r.setReviewerId(userId);
        r.setShopId(o.getShopId());
        r.setRating(req.rating().shortValue());
        r.setComment(req.comment());
        r = reviewRepository.saveAndFlush(r);

        Shop shop = shopRepository.findById(o.getShopId()).orElseThrow();
        shop.setRatingAvg(BigDecimal.valueOf(reviewRepository.averageForShop(shop.getId())).setScale(2, RoundingMode.HALF_UP));
        shop.setRatingCount((int) reviewRepository.countByShopId(shop.getId()));
        return toReview(r, userService.getUser(userId));
    }

    @Transactional(readOnly = true)
    public PageResponse<ReviewResponse> shopReviews(Long shopId, int page, int size) {
        Page<Review> reviews = reviewRepository.findByShopIdOrderByIdDesc(shopId, PageRequest.of(page, size));
        Map<Long, User> users = userRepository.findAllById(reviews.map(Review::getReviewerId).toSet()).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));
        return PageResponse.of(reviews, r -> toReview(r, users.get(r.getReviewerId())));
    }

    private ReviewResponse toReview(Review r, User reviewer) {
        String name = reviewer == null ? "Người dùng" : maskName(reviewer.getFullName());
        return new ReviewResponse(r.getId(), r.getOrderId(), name, r.getRating(), r.getComment(), r.getCreatedAt());
    }

    private static String maskName(String fullName) {
        String[] parts = fullName.trim().split("\\s+");
        return parts.length == 1 ? parts[0] : parts[parts.length - 1] + " " + parts[0].charAt(0) + ".";
    }

    private Order requireBuyerOrder(Long userId, Long orderId) {
        Order o = lock(orderId);
        if (!o.getBuyerId().equals(userId)) {
            throw ApiException.notFound("đơn hàng");
        }
        return o;
    }

    private boolean withinComplaintWindow(Order o) {
        return o.getDeliveredAt() != null && o.getDeliveredAt()
                .plus(config.days(SystemConfigService.AUTO_COMPLETE_DAYS)).isAfter(Instant.now());
    }

    // =====================================================================
    // Người bán (đơn NORMAL) và Staff kho (đơn AUCTION)
    // =====================================================================

    /** Lấy đơn mà người xử lý có quyền: chủ shop với đơn NORMAL, Staff/Admin với đơn AUCTION. */
    private Order requireHandlerOrder(Long userId, boolean staff, Long orderId) {
        Order o = lock(orderId);
        if (o.getOrderType() == Order.Type.AUCTION) {
            if (!staff) {
                throw ApiException.forbidden("Đơn đấu giá do kho xử lý");
            }
            return o;
        }
        Shop shop = shopRepository.findById(o.getShopId()).orElseThrow();
        if (!shop.getUserId().equals(userId)) {
            throw ApiException.notFound("đơn hàng");
        }
        return o;
    }

    @Transactional
    public OrderDetail confirm(Long userId, boolean staff, Long orderId) {
        Order o = requireHandlerOrder(userId, staff, orderId);
        transition(o, OrderStatus.PREPARING, userId, "Đã xác nhận, đang chuẩn bị hàng");
        if (o.getOrderType() == Order.Type.NORMAL) {
            o.setShipDueAt(Instant.now().plus(config.days(SystemConfigService.SHIP_DEADLINE_DAYS))); // hạn giao cho vận chuyển
        }
        return toDetail(o);
    }

    @Transactional
    public OrderDetail ship(Long userId, boolean staff, Long orderId, String trackingCode) {
        Order o = requireHandlerOrder(userId, staff, orderId);
        if (o.isCancelRequested()) {
            throw ApiException.conflict("CANCEL_REQUESTED", "Hãy xử lý yêu cầu huỷ của người mua trước");
        }
        if (o.isPickupAtWarehouse()) {
            throw ApiException.conflict("PICKUP_ORDER", "Đơn nhận tại kho, dùng thao tác bàn giao tại kho");
        }
        o.setTrackingCode(trackingCode == null || trackingCode.isBlank() ? "RB" + CodeGenerator.digits(10) : trackingCode);
        transition(o, OrderStatus.SHIPPING, userId, "Đã giao cho đơn vị vận chuyển, mã vận đơn " + o.getTrackingCode());
        return toDetail(o);
    }

    /** Giả lập: đơn vị vận chuyển báo giao thành công (hoặc bàn giao tại kho với đơn nhận tại kho). */
    @Transactional
    public OrderDetail markDelivered(Long userId, boolean staff, Long orderId) {
        Order o = requireHandlerOrder(userId, staff, orderId);
        if (o.getStatus() == OrderStatus.PREPARING && !o.isPickupAtWarehouse()) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Đơn chưa được giao cho vận chuyển");
        }
        transition(o, OrderStatus.DELIVERED, userId, o.isPickupAtWarehouse() ? "Người mua đã nhận tại kho" : "Giao hàng thành công");
        audit.record(EventCode.ORDER_DELIVERY_MARKED, "ORDER", o.getId(), o.getCode(), "Đánh dấu giao thành công",
                "outcome", "DELIVERED", "byStaff", staff, "simulated", !staff && !o.isPickupAtWarehouse(),
                "shipToDeliverSec", o.getShippedAt() == null ? null : Duration.between(o.getShippedAt(), Instant.now()).toSeconds());
        return toDetail(o);
    }

    @Transactional
    public OrderDetail markDeliveryFailed(Long userId, boolean staff, Long orderId, String reason) {
        Order o = requireHandlerOrder(userId, staff, orderId);
        o.setCancelReason(reason);
        transition(o, OrderStatus.FAILED_DELIVERY, userId, "Giao thất bại: " + reason);
        audit.record(EventCode.ORDER_DELIVERY_MARKED, "ORDER", o.getId(), o.getCode(), "Đánh dấu giao thất bại",
                "outcome", "FAILED", "byStaff", staff, "simulated", !staff, "reason", reason);
        return toDetail(o);
    }

    @Transactional
    public OrderDetail sellerCancel(Long userId, Long orderId, String reason) {
        Order o = requireHandlerOrder(userId, false, orderId);
        if (!EnumSet.of(OrderStatus.PENDING_CONFIRM, OrderStatus.PREPARING).contains(o.getStatus())) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Không thể huỷ đơn ở trạng thái " + o.getStatus());
        }
        o.setCancelReason(reason);
        transition(o, OrderStatus.CANCELLED, userId, "Shop huỷ: " + reason);
        markSellerFault(o);
        return toDetail(o);
    }

    @Transactional
    public OrderDetail respondCancelRequest(Long userId, Long orderId, boolean approve, String note) {
        Order o = requireHandlerOrder(userId, false, orderId);
        if (!o.isCancelRequested()) {
            throw ApiException.conflict("NO_CANCEL_REQUEST", "Đơn không có yêu cầu huỷ");
        }
        o.setCancelRequested(false);
        if (approve) {
            transition(o, OrderStatus.CANCELLED, userId, "Shop đồng ý yêu cầu huỷ");
        } else {
            recordHistory(o, o.getStatus(), o.getStatus(), userId, "Shop từ chối yêu cầu huỷ: " + note);
            notifications.notify(o.getBuyerId(), NotificationService.ORDER, "Yêu cầu huỷ bị từ chối",
                    "Shop từ chối huỷ đơn " + o.getCode() + (note != null ? ": " + note : ""), Map.of("orderId", o.getId()));
        }
        return toDetail(o);
    }

    /** Shop (hoặc kho với đơn đấu giá) đồng ý / từ chối trả hàng. Từ chối → chờ Admin phân xử. */
    @Transactional
    public OrderDetail respondReturn(Long userId, boolean staff, Long orderId, boolean approve, String note) {
        Order o = requireHandlerOrder(userId, staff, orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.PENDING)
                .orElseThrow(() -> ApiException.conflict("NO_RETURN_REQUEST", "Không có yêu cầu trả hàng đang chờ"));
        r.setSellerNote(note);
        if (approve) {
            approveReturn(o, r, userId, "Người bán đồng ý trả hàng");
        } else {
            r.setStatus(ReturnRequest.Status.DISPUTED);
            recordHistory(o, o.getStatus(), o.getStatus(), userId, "Từ chối trả hàng, chờ Admin phân xử");
        }
        return toDetail(o);
    }

    // =====================================================================
    // Admin phân xử
    // =====================================================================

    /** resolved = false: khiếu nại chờ phân xử (cũ nhất trước); true: đã phân xử (mới nhất trước). */
    @Transactional(readOnly = true)
    public PageResponse<ReturnResponse> disputes(boolean resolved, int page, int size) {
        var pageable = PageRequest.of(page, size);
        var result = resolved
                ? returnRepository.findByResolvedByIsNotNullOrderByResolvedAtDesc(pageable)
                : returnRepository.findByStatusOrderByIdAsc(ReturnRequest.Status.DISPUTED, pageable);
        return PageResponse.of(result, this::returnView);
    }

    private ReturnResponse returnView(ReturnRequest r) {
        Instant respondBy = r.getStatus() == ReturnRequest.Status.PENDING && r.getCreatedAt() != null
                ? r.getCreatedAt().plus(config.days(SystemConfigService.RETURN_RESPONSE_DAYS)) : null;
        Instant shipBy = r.getStatus() == ReturnRequest.Status.AWAITING_GOODS && r.getReturnShippedAt() == null
                && r.getApprovedAt() != null ? r.getApprovedAt().plus(config.days(SystemConfigService.RETURN_SHIP_DAYS)) : null;
        String resolvedByName = r.getResolvedBy() == null ? null
                : userRepository.findById(r.getResolvedBy()).map(User::getFullName).orElse(null);
        String[] dest = orderRepository.findById(r.getOrderId()).map(this::returnDestination).orElse(new String[]{null, null});
        return ReturnResponse.of(r, respondBy, shipBy, resolvedByName, dest[0], dest[1]);
    }

    @Transactional
    public OrderDetail resolveDispute(Long adminId, Long orderId, boolean refundBuyer, String resolution) {
        Order o = lock(orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.DISPUTED)
                .orElseThrow(() -> ApiException.conflict("NO_DISPUTE", "Đơn không có khiếu nại chờ phân xử"));
        r.setResolution(resolution);
        r.setResolvedBy(adminId);
        r.setResolvedAt(Instant.now());
        if (refundBuyer) {
            if (r.getReturnShippedAt() != null) {
                // Người mua đã gửi hàng về mà shop không xác nhận: Admin quyết hoàn tiền ngay
                completeReturn(o, r, adminId, "Admin chấp nhận trả hàng: " + resolution);
            } else {
                approveReturn(o, r, adminId, resolution);
            }
        } else {
            r.setStatus(ReturnRequest.Status.REJECTED);
            transition(o, OrderStatus.COMPLETED, adminId, "Admin từ chối trả hàng: " + resolution);
        }
        return toDetail(o);
    }

    // =====================================================================
    // Dùng bởi job tự động
    // =====================================================================

    /** Người bán không trả lời yêu cầu trả hàng đúng hạn → chuyển Admin phân xử, tiền vẫn giữ ở sàn. */
    @Transactional
    public void autoEscalateReturn(Long orderId) {
        Order o = lock(orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.PENDING)
                .orElse(null);
        if (r == null || o.getStatus() != OrderStatus.RETURN_REQUESTED) {
            return;
        }
        r.setStatus(ReturnRequest.Status.DISPUTED);
        r.setSellerNote("Người bán không trả lời đúng hạn");
        recordHistory(o, o.getStatus(), o.getStatus(), null, "Người bán không trả lời yêu cầu trả hàng, chuyển Admin phân xử");
        notifications.notify(o.getBuyerId(), NotificationService.ORDER, "Yêu cầu trả hàng đã chuyển Admin",
                "Người bán chưa trả lời yêu cầu trả hàng đơn " + o.getCode() + ", Admin sẽ phân xử", Map.of("orderId", o.getId()));
        notifyShop(o, "Bạn không trả lời yêu cầu trả hàng đơn " + o.getCode() + " đúng hạn, Admin sẽ phân xử");
    }

    @Transactional
    public void autoCancelUnpaid(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.PENDING_PAYMENT) {
            o.setCancelReason("Quá hạn thanh toán");
            transition(o, OrderStatus.CANCELLED, null, "Tự huỷ: quá hạn thanh toán");
        }
    }

    @Transactional
    public void autoCancelUnconfirmed(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.PENDING_CONFIRM) {
            o.setCancelReason("Shop không xác nhận đúng hạn");
            transition(o, OrderStatus.CANCELLED, null, "Tự huỷ: shop không xác nhận trong hạn");
            notifyShop(o, "Đơn " + o.getCode() + " bị huỷ vì không xác nhận đúng hạn");
            markSellerFault(o);
        }
    }

    @Transactional
    public void autoComplete(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.DELIVERED) {
            transition(o, OrderStatus.COMPLETED, null, "Tự hoàn tất sau thời hạn khiếu nại");
        }
    }

    // =====================================================================
    // Trả hàng theo bước: được đồng ý → người mua gửi hàng về → shop / kho xác nhận đã nhận → hoàn tiền
    // =====================================================================

    private void approveReturn(Order o, ReturnRequest r, Long actorId, String resolution) {
        r.setStatus(ReturnRequest.Status.AWAITING_GOODS);
        r.setApprovedAt(Instant.now());
        r.setResolution(resolution);
        int days = config.integer(SystemConfigService.RETURN_SHIP_DAYS);
        recordHistory(o, o.getStatus(), o.getStatus(), actorId, "Đồng ý trả hàng, chờ người mua gửi sách về");
        String[] dest = returnDestination(o);
        notifications.notify(o.getBuyerId(), NotificationService.ORDER, "Yêu cầu trả hàng được đồng ý",
                "Hãy gửi sách về trong " + days + " ngày và nhập mã vận đơn. Địa chỉ nhận: " + dest[0] + ", " + dest[1]
                        + ". Tiền hoàn vào ví khi hàng trả được xác nhận đã nhận (đơn " + o.getCode() + ")", Map.of("orderId", o.getId()));
        audit.record(EventCode.ORDER_RETURN_APPROVED, "ORDER", o.getId(), o.getCode(), "Đồng ý trả hàng",
                "shipWithinDays", days, "decidedBy", actorId);
    }

    /** Hàng trả đã về tay shop / kho (hoặc Admin quyết): hoàn tiền người mua. Tồn kho không tự cộng lại. */
    private void completeReturn(Order o, ReturnRequest r, Long actorId, String note) {
        r.setStatus(ReturnRequest.Status.APPROVED);
        r.setReturnReceivedAt(Instant.now());
        transition(o, OrderStatus.RETURNED, actorId, note);
        audit.record(EventCode.ORDER_RETURN_RECEIVED, "ORDER", o.getId(), o.getCode(), note,
                "refund", o.getTotal(), "paymentMethod", o.getPaymentMethod(), "confirmedBy", actorId);
    }

    @Transactional
    public OrderDetail buyerShipReturn(Long userId, Long orderId, String trackingCode) {
        Order o = requireBuyerOrder(userId, orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.AWAITING_GOODS && o.getStatus() == OrderStatus.RETURN_REQUESTED)
                .orElseThrow(() -> ApiException.conflict("NO_RETURN_TO_SHIP", "Không có yêu cầu trả hàng đang chờ bạn gửi hàng về"));
        if (r.getReturnShippedAt() != null) {
            throw ApiException.conflict("ALREADY_SHIPPED", "Bạn đã gửi hàng trả cho đơn này");
        }
        r.setReturnTrackingCode(trackingCode.trim());
        r.setReturnShippedAt(Instant.now());
        recordHistory(o, o.getStatus(), o.getStatus(), userId, "Người mua đã gửi hàng trả, mã vận đơn " + r.getReturnTrackingCode());
        notifyShop(o, "Người mua đã gửi hàng trả đơn " + o.getCode() + ", mã vận đơn " + r.getReturnTrackingCode());
        audit.record(EventCode.ORDER_RETURN_SHIPPED, "ORDER", o.getId(), o.getCode(), "Người mua gửi hàng trả",
                "trackingCode", r.getReturnTrackingCode());
        return toDetail(o);
    }

    /** Shop (hoặc kho với đơn đấu giá) xác nhận đã nhận lại sách → hoàn tiền người mua. */
    @Transactional
    public OrderDetail confirmReturnReceived(Long userId, boolean staff, Long orderId) {
        Order o = requireHandlerOrder(userId, staff, orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.AWAITING_GOODS && o.getStatus() == OrderStatus.RETURN_REQUESTED)
                .orElseThrow(() -> ApiException.conflict("NO_RETURN_TO_RECEIVE", "Không có hàng trả nào đang chờ xác nhận"));
        if (r.getReturnShippedAt() == null) {
            throw ApiException.conflict("RETURN_NOT_SHIPPED", "Người mua chưa gửi hàng trả");
        }
        completeReturn(o, r, userId, "Shop (hoặc kho) xác nhận đã nhận hàng trả");
        return toDetail(o);
    }

    /** Job: người mua không bấm xác nhận sau N ngày kể từ lúc giao cho vận chuyển → tự coi là đã giao, bắt đầu hạn khiếu nại. */
    @Transactional
    public void autoDeliver(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.SHIPPING) {
            transition(o, OrderStatus.DELIVERED, null, "Tự coi là đã giao sau "
                    + config.integer(SystemConfigService.AUTO_DELIVER_DAYS) + " ngày kể từ lúc giao cho vận chuyển");
            audit.record(EventCode.ORDER_DELIVERY_AUTO, "ORDER", o.getId(), o.getCode(), "Tự coi là đã giao",
                    "autoDeliverDays", config.integer(SystemConfigService.AUTO_DELIVER_DAYS));
        }
    }

    /** Job: được đồng ý trả nhưng người mua không gửi hàng về đúng hạn → đóng yêu cầu, đơn hoàn tất, shop nhận tiền. */
    @Transactional
    public void autoExpireReturn(Long orderId) {
        Order o = lock(orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.AWAITING_GOODS && x.getReturnShippedAt() == null)
                .orElse(null);
        if (r == null || o.getStatus() != OrderStatus.RETURN_REQUESTED) {
            return;
        }
        r.setStatus(ReturnRequest.Status.EXPIRED);
        r.setResolution("Người mua không gửi hàng trả đúng hạn");
        audit.record(EventCode.ORDER_RETURN_EXPIRED, "ORDER", o.getId(), o.getCode(), "Quá hạn gửi hàng trả");
        transition(o, OrderStatus.COMPLETED, null, "Tự hoàn tất: người mua không gửi hàng trả đúng hạn");
    }

    /** Job: người mua đã gửi hàng về nhưng shop / kho không xác nhận đúng hạn → chuyển Admin phân xử. */
    @Transactional
    public void autoEscalateGoods(Long orderId) {
        Order o = lock(orderId);
        ReturnRequest r = returnRepository.findByOrderId(orderId)
                .filter(x -> x.getStatus() == ReturnRequest.Status.AWAITING_GOODS && x.getReturnShippedAt() != null)
                .orElse(null);
        if (r == null || o.getStatus() != OrderStatus.RETURN_REQUESTED) {
            return;
        }
        r.setStatus(ReturnRequest.Status.DISPUTED);
        r.setSellerNote("Shop không xác nhận đã nhận hàng trả đúng hạn");
        recordHistory(o, o.getStatus(), o.getStatus(), null, "Shop không xác nhận hàng trả đúng hạn, chuyển Admin phân xử");
        notifications.notify(o.getBuyerId(), NotificationService.ORDER, "Hàng trả chuyển Admin",
                "Shop chưa xác nhận nhận hàng trả đơn " + o.getCode() + ", Admin sẽ phân xử", Map.of("orderId", o.getId()));
        notifyShop(o, "Bạn chưa xác nhận hàng trả đơn " + o.getCode() + " đúng hạn, Admin sẽ phân xử");
        audit.record(EventCode.ORDER_RETURN_ESCALATED, "ORDER", o.getId(), o.getCode(), "Chuyển Admin vì shop không xác nhận hàng trả");
    }

    // =====================================================================
    // Hạn xử lý của shop và điểm uy tín
    // =====================================================================

    /** Đơn hỏng do lỗi của shop: tính vào điểm uy tín, vượt ngưỡng thì gỡ uy tín shop. */
    private void markSellerFault(Order o) {
        o.setSellerFault(true);
        if (o.getShopId() != null) {
            reputation.review(o.getShopId());
        }
    }

    /** Job: shop xác nhận rồi nhưng quá hạn không giao cho vận chuyển → huỷ, hoàn tiền người mua, tính lỗi cho shop. */
    @Transactional
    public void autoCancelUnshipped(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.PREPARING && !o.isCancelRequested() && !o.isPickupAtWarehouse()) {
            o.setCancelReason("Shop không giao hàng cho vận chuyển đúng hạn");
            transition(o, OrderStatus.CANCELLED, null, "Tự huỷ: shop không giao cho vận chuyển trong "
                    + config.integer(SystemConfigService.SHIP_DEADLINE_DAYS) + " ngày");
            notifyShop(o, "Đơn " + o.getCode() + " bị huỷ vì bạn không giao cho vận chuyển đúng hạn");
            audit.record(EventCode.ORDER_AUTO_CANCELLED, "ORDER", o.getId(), o.getCode(), "Quá hạn giao cho vận chuyển",
                    "reason", "SHIP_DEADLINE", "shopId", o.getShopId());
            markSellerFault(o);
        }
    }

    /** Job: người mua xin huỷ đơn đang chuẩn bị mà shop không trả lời đúng hạn → coi như đồng ý huỷ (không tính lỗi shop). */
    @Transactional
    public void autoApproveCancelRequest(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.PREPARING && o.isCancelRequested()) {
            o.setCancelRequested(false);
            transition(o, OrderStatus.CANCELLED, null, "Tự đồng ý huỷ: shop không trả lời yêu cầu huỷ trong "
                    + config.integer(SystemConfigService.CANCEL_RESPONSE_HOURS) + " giờ");
            notifyShop(o, "Đơn " + o.getCode() + " được huỷ theo yêu cầu của người mua vì bạn không trả lời đúng hạn");
            audit.record(EventCode.ORDER_AUTO_CANCELLED, "ORDER", o.getId(), o.getCode(), "Shop không trả lời yêu cầu huỷ",
                    "reason", "CANCEL_REQUEST_UNANSWERED", "shopId", o.getShopId());
        }
    }

    /** Hệ thống huỷ đơn chưa giao cho vận chuyển (vd khoá tài khoản): hoàn tiền, trả tồn kho, không tính lỗi shop. */
    @Transactional
    public void cancelBySystem(Long orderId, String reason) {
        Order o = lock(orderId);
        if (EnumSet.of(OrderStatus.PENDING_PAYMENT, OrderStatus.PENDING_CONFIRM, OrderStatus.PREPARING).contains(o.getStatus())) {
            o.setCancelReason(reason);
            transition(o, OrderStatus.CANCELLED, null, "Hệ thống huỷ: " + reason);
            audit.record(EventCode.ORDER_AUTO_CANCELLED, "ORDER", o.getId(), o.getCode(), reason, "reason", "SYSTEM");
        }
    }

    // =====================================================================
    // Vận hành khi chưa có hãng vận chuyển tích hợp, nhắc trước hạn, địa chỉ nhận hàng trả
    // =====================================================================

    /** Nơi người mua gửi hàng trả: shop với đơn thường, kho của sàn với đơn đấu giá. [tên, địa chỉ] */
    private String[] returnDestination(Order o) {
        if (o.getShopId() != null) {
            return shopRepository.findById(o.getShopId()).map(s -> new String[]{s.getName(), s.getPickupAddress()})
                    .orElse(new String[]{null, null});
        }
        return new String[]{"Kho ReBook", config.get(SystemConfigService.WAREHOUSE_ADDRESS)};
    }

    @Transactional(readOnly = true)
    public PageResponse<InTransitOrder> inTransit(int page, int size) {
        Instant overdueBefore = Instant.now().minus(config.days(SystemConfigService.AUTO_DELIVER_DAYS));
        Page<Order> orders = orderRepository.findNormalInTransit(PageRequest.of(page, size));
        Map<Long, String> names = shopRepository.findAllById(orders.map(Order::getShopId).toSet()).stream()
                .collect(Collectors.toMap(Shop::getId, Shop::getName));
        return PageResponse.of(orders, o -> new InTransitOrder(o.getId(), o.getCode(), o.getShopId(), names.get(o.getShopId()),
                o.getBuyerId(), o.getPaymentMethod(), o.getTotal(), o.getTrackingCode(), o.getShippedAt(),
                o.getShippedAt() != null && o.getShippedAt().isBefore(overdueBefore)));
    }

    /**
     * Staff / Admin xác nhận kết quả giao của đơn thường sau khi đối chiếu với hãng vận chuyển (chưa có tích hợp tự động).
     * Đơn COD không tự coi là đã giao nên đây là đường duy nhất để đơn đi tiếp hoặc để ghi nhận người nhận bom hàng.
     */
    @Transactional
    public OrderDetail carrierConfirm(Long staffId, Long orderId, boolean delivered, String reason) {
        Order o = lock(orderId);
        if (o.getOrderType() != Order.Type.NORMAL) {
            throw ApiException.conflict("NOT_NORMAL_ORDER", "Đơn đấu giá do kho xử lý bằng thao tác giao của kho");
        }
        if (o.getStatus() != OrderStatus.SHIPPING) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Đơn không ở trạng thái đang giao");
        }
        Long shipToConfirmSec = o.getShippedAt() == null ? null : Duration.between(o.getShippedAt(), Instant.now()).toSeconds();
        if (delivered) {
            transition(o, OrderStatus.DELIVERED, staffId, "Đối chiếu hãng vận chuyển: giao thành công");
        } else {
            o.setCancelReason(reason);
            transition(o, OrderStatus.FAILED_DELIVERY, staffId, "Đối chiếu hãng vận chuyển: giao thất bại: " + reason);
        }
        audit.record(EventCode.ORDER_DELIVERY_MARKED, "ORDER", o.getId(), o.getCode(), "Staff xác nhận kết quả giao theo hãng vận chuyển",
                "outcome", delivered ? "DELIVERED" : "FAILED", "source", "CARRIER_CHECK", "byStaff", true, "simulated", false,
                "shipToDeliverSec", shipToConfirmSec, "reason", reason);
        return toDetail(o);
    }

    private static String vn(Instant t) {
        return t.atZone(CodeGenerator.VN).toLocalDateTime().toString().replace('T', ' ');
    }

    /** Job: nhắc shop trước khi quá hạn giao cho vận chuyển (một lần). */
    @Transactional
    public void sendShipReminder(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.PREPARING && !o.isCancelRequested() && !o.isShipReminderSent() && o.getShipDueAt() != null) {
            o.setShipReminderSent(true);
            notifyShop(o, "Đơn " + o.getCode() + " cần giao cho vận chuyển trước " + vn(o.getShipDueAt())
                    + ". Quá hạn đơn tự huỷ, hoàn tiền người mua và tính vào điểm uy tín của shop");
        }
    }

    /** Job: nhắc shop trả lời yêu cầu huỷ của người mua (một lần). */
    @Transactional
    public void sendCancelReminder(Long orderId) {
        Order o = lock(orderId);
        if (o.getStatus() == OrderStatus.PREPARING && o.isCancelRequested() && !o.isCancelReminderSent()) {
            o.setCancelReminderSent(true);
            notifyShop(o, "Người mua đang chờ bạn trả lời yêu cầu huỷ đơn " + o.getCode() + ". Sau "
                    + config.integer(SystemConfigService.CANCEL_RESPONSE_HOURS) + " giờ không trả lời đơn sẽ tự huỷ");
        }
    }

    /** Job: nhắc người thắng thanh toán hoá đơn lô trước hạn, nói rõ hậu quả nếu quá hạn (một lần). */
    @Transactional
    public void sendPaymentReminder(Long orderId) {
        Order o = lock(orderId);
        if (o.getOrderType() == Order.Type.AUCTION && o.getStatus() == OrderStatus.PENDING_PAYMENT && !o.isPaymentReminderSent()
                && o.getPaymentDueAt() != null) {
            o.setPaymentReminderSent(true);
            notifications.notify(o.getBuyerId(), NotificationService.AUCTION, "Sắp hết hạn thanh toán lô thắng",
                    "Hoá đơn " + o.getCode() + " hết hạn lúc " + vn(o.getPaymentDueAt()) + ". Quá hạn bạn bị phạt "
                            + config.decimal(SystemConfigService.DEFAULT_PENALTY_PERCENT).toPlainString()
                            + "% giá búa (mất cọc nếu cọc lớn hơn) và bị cấm đấu giá " + config.integer(SystemConfigService.AUCTION_BAN_DAYS) + " ngày",
                    Map.of("orderId", o.getId()));
        }
    }

    public boolean isStaffHandled(OrderStatus s) {
        return STAFF_HANDLED.contains(s);
    }

    public List<Order> byPayment(Long paymentId) {
        return orderRepository.findByPaymentId(paymentId);
    }
}
