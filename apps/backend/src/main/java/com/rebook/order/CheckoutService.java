package com.rebook.order;

import com.rebook.catalog.Listing;
import com.rebook.catalog.ListingRepository;
import com.rebook.catalog.ListingStatus;
import com.rebook.common.ApiException;
import com.rebook.order.OrderDtos.CheckoutPreview;
import com.rebook.order.OrderDtos.CheckoutRequest;
import com.rebook.order.OrderDtos.CheckoutResponse;
import com.rebook.order.OrderDtos.OrderSummary;
import com.rebook.order.OrderDtos.PayResponse;
import com.rebook.order.OrderDtos.ShopQuote;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Address;
import com.rebook.user.Shop;
import com.rebook.user.User;
import com.rebook.user.UserService;
import com.rebook.wallet.Payment;
import com.rebook.wallet.PaymentService;
import com.rebook.wallet.PaymentService.PaymentResponse;
import com.rebook.wallet.PaymentSucceededEvent;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Đặt hàng: tách giỏ thành nhiều đơn (mỗi shop một đơn, phí ship riêng), giữ hàng ngay,
 * một lần thanh toán trả cho nhiều đơn.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CheckoutService {

    private final CartItemRepository cartRepository;
    private final ListingRepository listingRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final UserService userService;
    private final ShippingCalculator shipping;
    private final PaymentService paymentService;
    private final WalletService walletService;
    private final SystemConfigService config;

    private record Line(Listing listing, int quantity) {
    }

    @Transactional(readOnly = true)
    public CheckoutPreview preview(Long userId, Long addressId, List<Long> listingIds) {
        Address address = userService.getAddress(userId, addressId);
        Map<Shop, List<Line>> groups = loadCart(userId, listingIds);
        List<ShopQuote> quotes = new ArrayList<>();
        BigDecimal sub = BigDecimal.ZERO;
        BigDecimal ship = BigDecimal.ZERO;
        for (var e : groups.entrySet()) {
            BigDecimal s = subtotal(e.getValue());
            BigDecimal f = shippingFee(e.getKey(), address, e.getValue());
            quotes.add(new ShopQuote(e.getKey().getId(), e.getKey().getName(), s, f, s.add(f)));
            sub = sub.add(s);
            ship = ship.add(f);
        }
        return new CheckoutPreview(quotes, sub, ship, sub.add(ship));
    }

    @Transactional
    public CheckoutResponse checkout(Long userId, CheckoutRequest req, String clientIp) {
        User buyer = userService.getUser(userId);
        if (!buyer.isEmailVerified()) {
            throw ApiException.forbidden("Cần xác thực email trước khi đặt hàng");
        }
        Address address = userService.getAddress(userId, req.addressId());
        Map<Shop, List<Line>> groups = loadCart(userId, req.listingIds());

        Instant now = Instant.now();
        List<Order> orders = new ArrayList<>();
        Set<Long> orderedListingIds = new HashSet<>();
        for (var e : groups.entrySet()) {
            Shop shop = e.getKey();
            Order o = new Order();
            o.setCode(OrderService.newCode());
            o.setBuyerId(userId);
            o.setShopId(shop.getId());
            o.setOrderType(Order.Type.NORMAL);
            o.setPaymentMethod(req.paymentMethod());
            o.setNote(req.note());
            o.setAddressSnapshot(snapshot(address));

            for (Line line : e.getValue()) {
                Listing l = line.listing();
                // Giữ hàng: UPDATE ... WHERE stock >= qty — 0 dòng nghĩa là người khác vừa mua mất
                if (listingRepository.reserveStock(l.getId(), line.quantity()) == 0) {
                    throw ApiException.conflict("OUT_OF_STOCK", "\"" + l.getBook().getTitle() + "\" vừa hết hàng");
                }
                OrderItem item = new OrderItem();
                item.setListingId(l.getId());
                item.setTitleSnapshot(l.getBook().getTitle());
                item.setImageSnapshot(l.getBook().coverUrl());
                item.setUnitPrice(l.getPrice());
                item.setQuantity(line.quantity());
                o.addItem(item);
                orderedListingIds.add(l.getId());
            }
            o.setSubtotal(subtotal(e.getValue()));
            o.setShippingFee(shippingFee(shop, address, e.getValue()));
            o.setTotal(o.getSubtotal().add(o.getShippingFee()));

            if (req.paymentMethod() == Payment.Method.COD) {
                o.setStatus(OrderStatus.PENDING_CONFIRM);
                o.setConfirmDueAt(now.plus(config.hours(SystemConfigService.CONFIRM_TIMEOUT_HOURS)));
            } else {
                o.setStatus(OrderStatus.PENDING_PAYMENT);
                o.setPaymentDueAt(now.plus(config.minutes(SystemConfigService.PAYMENT_TIMEOUT_MIN)));
            }
            o = orderRepository.save(o);
            orderService.recordHistory(o, null, o.getStatus(), userId, "Đặt hàng");
            orders.add(o);
        }
        cartRepository.deleteByUserIdAndListingIdIn(userId, orderedListingIds);

        BigDecimal grandTotal = orders.stream().map(Order::getTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
        PaymentResponse payment = switch (req.paymentMethod()) {
            case COD -> null;
            case WALLET -> {
                payWithWallet(userId, orders, grandTotal);
                yield null;
            }
            case VNPAY -> {
                PaymentResponse p = paymentService.createVnpay(userId, Payment.Purpose.ORDER, grandTotal,
                        config.minutes(SystemConfigService.PAYMENT_TIMEOUT_MIN),
                        "Thanh toan don hang ReBook", clientIp);
                orders.forEach(o -> o.setPaymentId(p.id()));
                yield p;
            }
        };
        List<OrderSummary> summaries = orders.stream().map(orderService::toSummary).toList();
        return new CheckoutResponse(summaries, payment);
    }

    /** Thanh toán lại một đơn đang chờ thanh toán (đơn thường hoặc hoá đơn lô đấu giá). */
    @Transactional
    public PayResponse pay(Long userId, Long orderId, Payment.Method method, String clientIp) {
        Order o = orderService.lock(orderId);
        if (!o.getBuyerId().equals(userId)) {
            throw ApiException.notFound("đơn hàng");
        }
        if (o.getStatus() != OrderStatus.PENDING_PAYMENT) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Đơn không ở trạng thái chờ thanh toán");
        }
        if (o.getPaymentDueAt() != null && o.getPaymentDueAt().isBefore(Instant.now())) {
            throw ApiException.conflict("PAYMENT_EXPIRED", "Đã quá hạn thanh toán");
        }
        return switch (method) {
            case WALLET -> {
                payWithWallet(userId, List.of(o), o.amountDue());
                yield new PayResponse(orderService.toSummary(o), null);
            }
            case VNPAY -> {
                Duration ttl = Duration.between(Instant.now(), o.getPaymentDueAt());
                PaymentResponse p = paymentService.createVnpay(userId, Payment.Purpose.ORDER, o.amountDue(),
                        ttl.compareTo(Duration.ofMinutes(15)) > 0 ? Duration.ofMinutes(15) : ttl,
                        "Thanh toan don " + o.getCode(), clientIp);
                o.setPaymentMethod(Payment.Method.VNPAY);
                o.setPaymentId(p.id());
                yield new PayResponse(orderService.toSummary(o), p);
            }
            case COD -> throw ApiException.badRequest("INVALID_METHOD", "Chỉ chọn COD khi đặt hàng");
        };
    }

    private void payWithWallet(Long userId, List<Order> orders, BigDecimal amount) {
        Payment payment = paymentService.createInternal(userId, Payment.Method.WALLET, amount);
        for (Order o : orders) {
            walletService.debit(userId, WalletTxType.PAYMENT, o.amountDue(), "ORDER", o.getId(), "Thanh toán đơn " + o.getCode());
            markPaid(o, Payment.Method.WALLET, payment.getId());
        }
    }

    private void markPaid(Order o, Payment.Method method, Long paymentId) {
        o.setPaymentMethod(method);
        o.setPaymentId(paymentId);
        o.setPaidAt(Instant.now());
        if (o.getOrderType() == Order.Type.NORMAL) {
            o.setConfirmDueAt(Instant.now().plus(config.hours(SystemConfigService.CONFIRM_TIMEOUT_HOURS)));
        }
        orderService.transition(o, OrderStatus.PENDING_CONFIRM, o.getBuyerId(), "Đã thanh toán (" + method + ")");
    }

    /**
     * VNPay báo thành công → chuyển các đơn sang chờ xác nhận. Đơn đã bị huỷ thì hoàn tiền vào ví.
     * Phần tiền không còn đơn nào nhận (người mua đã trả lại đơn bằng ví hoặc link VNPay mới) cũng hoàn vào ví.
     */
    @EventListener
    public void onPaymentSucceeded(PaymentSucceededEvent event) {
        Payment p = event.payment();
        if (p.getPurpose() != Payment.Purpose.ORDER || p.getMethod() != Payment.Method.VNPAY) {
            return;
        }
        BigDecimal handled = BigDecimal.ZERO;
        for (Order o : orderService.byPayment(p.getId())) {
            Order locked = orderService.lock(o.getId());
            handled = handled.add(locked.amountDue());
            if (locked.getStatus() == OrderStatus.PENDING_PAYMENT) {
                markPaid(locked, Payment.Method.VNPAY, p.getId());
            } else {
                log.warn("Payment {} về sau khi đơn {} đã {}, hoàn tiền vào ví", p.getCode(), locked.getCode(), locked.getStatus());
                walletService.credit(locked.getBuyerId(), WalletTxType.REFUND, locked.amountDue(), "ORDER", locked.getId(),
                        "Hoàn tiền: thanh toán đến sau khi đơn đã huỷ");
            }
        }
        BigDecimal orphan = p.getAmount().subtract(handled);
        if (orphan.signum() > 0) {
            log.warn("Payment {} có {} đ không còn đơn nào cần trả, hoàn vào ví", p.getCode(), orphan);
            walletService.credit(p.getUserId(), WalletTxType.REFUND, orphan, "PAYMENT", p.getId(),
                    "Hoàn tiền: đơn đã được thanh toán bằng cách khác");
        }
    }

    // ---- Nội bộ ----

    /** Đọc giỏ (hoặc các listingIds đã chọn), kiểm tra còn bán, gom theo shop. */
    private Map<Shop, List<Line>> loadCart(Long userId, List<Long> listingIds) {
        List<CartItem> items = cartRepository.findByUserIdOrderByIdDesc(userId).stream()
                .filter(c -> listingIds == null || listingIds.isEmpty() || listingIds.contains(c.getListingId()))
                .toList();
        if (items.isEmpty()) {
            throw ApiException.badRequest("EMPTY_CART", "Giỏ hàng trống");
        }
        Map<Long, Shop> shops = new LinkedHashMap<>();
        Map<Long, List<Line>> byShop = new LinkedHashMap<>();
        for (CartItem item : items) {
            Listing l = listingRepository.findWithDetailsById(item.getListingId())
                    .orElseThrow(() -> ApiException.notFound("tin đăng"));
            if (l.getStatus() != ListingStatus.ACTIVE || l.getStock() < item.getQuantity()) {
                throw ApiException.conflict("OUT_OF_STOCK", "\"" + l.getBook().getTitle() + "\" không còn đủ hàng");
            }
            if (l.getShop().getUserId().equals(userId)) {
                throw ApiException.badRequest("OWN_LISTING", "Không thể mua sách của chính shop mình");
            }
            shops.putIfAbsent(l.getShop().getId(), l.getShop());
            byShop.computeIfAbsent(l.getShop().getId(), k -> new ArrayList<>()).add(new Line(l, item.getQuantity()));
        }
        Map<Shop, List<Line>> result = new LinkedHashMap<>();
        byShop.forEach((shopId, lines) -> result.put(shops.get(shopId), lines));
        return result;
    }

    private static BigDecimal subtotal(List<Line> lines) {
        return lines.stream().map(l -> l.listing().getPrice().multiply(BigDecimal.valueOf(l.quantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal shippingFee(Shop shop, Address to, List<Line> lines) {
        int weight = lines.stream().mapToInt(l -> l.listing().getBook().getWeightGram() * l.quantity()).sum();
        return shipping.fee(shop.getPickupProvince(), to.getProvince(), weight);
    }

    public static Map<String, Object> snapshot(Address a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("receiverName", a.getReceiverName());
        m.put("phone", a.getPhone());
        m.put("province", a.getProvince());
        m.put("district", a.getDistrict());
        m.put("ward", a.getWard());
        m.put("detail", a.getDetail());
        return m;
    }
}
