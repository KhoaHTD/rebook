package com.rebook.auction;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.catalog.Book;
import com.rebook.catalog.BookRepository;
import com.rebook.common.ApiException;
import com.rebook.common.Money;
import com.rebook.consignment.Consignment;
import com.rebook.consignment.ConsignmentRepository;
import com.rebook.consignment.WarehouseItem;
import com.rebook.consignment.WarehouseItemRepository;
import com.rebook.notification.NotificationService;
import com.rebook.order.CheckoutService;
import com.rebook.order.Order;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.order.OrderItem;
import com.rebook.order.OrderRepository;
import com.rebook.order.OrderService;
import com.rebook.order.OrderStatus;
import com.rebook.order.OrderStatusChangedEvent;
import com.rebook.order.ShippingCalculator;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Address;
import com.rebook.user.AddressRepository;
import com.rebook.user.User;
import com.rebook.user.UserService;
import com.rebook.wallet.AccountDebt;
import com.rebook.wallet.DebtService;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Giai đoạn F – sau phiên: hoá đơn người thắng, hoàn / áp / thu cọc, mời người trả giá cao thứ hai,
 * và dòng tiền của đơn AUCTION (sàn giữ tiền, trả người bán giá gõ búa − hoa hồng khi hoàn tất).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuctionSettlement {

    private static final String REF = "ORDER";

    private final LotRepository lotRepository;
    private final AuctionSessionRepository sessionRepository;
    private final AuctionRegistrationRepository registrationRepository;
    private final BidRepository bidRepository;
    private final ConsignmentRepository consignmentRepository;
    private final WarehouseItemRepository warehouseRepository;
    private final BookRepository bookRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final AddressRepository addressRepository;
    private final ShippingCalculator shipping;
    private final WalletService walletService;
    private final UserService userService;
    private final SystemConfigService config;
    private final NotificationService notifications;
    private final DebtService debts;
    private final ProxyBidRepository proxyRepository;
    private final AuctionViews views;
    private final AuditLog audit;

    // =====================================================================
    // Sau khi phiên kết thúc
    // =====================================================================

    public void afterSessionEnded(AuctionSession session) {
        List<Lot> lots = lotRepository.findBySessionIdOrderByLotNumberAsc(session.getId());
        Set<Long> winners = new HashSet<>();
        Set<Long> depositUsed = new HashSet<>();
        Map<Long, Integer> weightByWinner = new HashMap<>(); // gộp kiện: khối lượng các lô đã lập hoá đơn của mỗi người
        for (Lot lot : lots) {
            if (lot.getStatus() == LotStatus.SOLD) {
                winners.add(lot.getWinnerId());
                boolean applyDeposit = depositUsed.add(lot.getWinnerId());
                int weight = bookRepository.findById(lot.getBookId()).orElseThrow().getWeightGram();
                int prior = weightByWinner.getOrDefault(lot.getWinnerId(), 0);
                weightByWinner.put(lot.getWinnerId(), prior + weight);
                createInvoice(lot, lot.getWinnerId(), lot.getHammerPrice(), false, applyDeposit, prior);
            } else if (lot.getStatus() == LotStatus.UNSOLD) {
                notifySeller(lot, "Lô " + lot.getLotNumber() + " không bán được. Hãy chọn: vào phiên sau, chuyển sang bán giá cố định, hoặc nhận lại sách");
            }
        }
        // Người không thắng lô nào → mở khoá cọc ngay
        for (AuctionRegistration reg : registrationRepository.findBySessionIdAndStatus(session.getId(), AuctionRegistration.Status.APPROVED)) {
            if (!winners.contains(reg.getUserId())) {
                refundDeposit(reg, "Hoàn cọc phiên " + session.getTitle());
            }
        }
    }

    /** Hoá đơn lô thắng: giá gõ búa + phí người mua + phí giao (hoặc nhận tại kho), trừ tiền cọc. */
    public Order createInvoice(Lot lot, Long buyerId, BigDecimal hammer, boolean secondChance, boolean applyDeposit) {
        return createInvoice(lot, buyerId, hammer, secondChance, applyDeposit, 0);
    }

    /** priorWeightGram: khối lượng các lô cùng phiên đã lập hoá đơn cho người này, để gộp phí giao (docs/AUCTION_MONEY_FLOW.md 3.5). */
    public Order createInvoice(Lot lot, Long buyerId, BigDecimal hammer, boolean secondChance, boolean applyDeposit,
                               int priorWeightGram) {
        Book book = bookRepository.findById(lot.getBookId()).orElseThrow();
        Address address = addressRepository.findByUserIdOrderByDefaultAddressDescIdAsc(buyerId).stream().findFirst().orElse(null);

        Order o = new Order();
        o.setCode(OrderService.newCode());
        o.setBuyerId(buyerId);
        o.setLotId(lot.getId());
        o.setOrderType(Order.Type.AUCTION);
        o.setStatus(OrderStatus.PENDING_PAYMENT);
        o.setSecondChance(secondChance);
        o.setSubtotal(hammer);
        o.setBuyerPremium(Money.percent(hammer, buyerPremiumPercent(lot)));
        if (address != null) {
            o.setAddressSnapshot(CheckoutService.snapshot(address));
            BigDecimal fullFee = shipping.fee(shipping.warehouseProvince(), address.getProvince(), priorWeightGram + book.getWeightGram());
            // Gộp kiện: lô sau chỉ trả phần phí tăng thêm so với kiện đã tính cho các lô trước
            o.setShippingFee(priorWeightGram > 0
                    ? fullFee.subtract(shipping.fee(shipping.warehouseProvince(), address.getProvince(), priorWeightGram))
                    : fullFee);
        } else {
            o.setPickupAtWarehouse(true);
        }
        o.setTotal(o.getSubtotal().add(o.getBuyerPremium()).add(o.getShippingFee()));
        if (applyDeposit) {
            registrationRepository.findBySessionIdAndUserId(lot.getSessionId(), buyerId)
                    .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                    .ifPresent(r -> o.setDepositApplied(r.getDepositAmount().min(o.getTotal())));
        }
        o.setPaymentDueAt(Instant.now().plus(config.hours(secondChance
                ? SystemConfigService.SECOND_CHANCE_HOURS : SystemConfigService.AUCTION_PAYMENT_HOURS)));

        OrderItem item = new OrderItem();
        item.setLotId(lot.getId());
        item.setTitleSnapshot(book.getTitle());
        item.setImageSnapshot(book.coverUrl());
        item.setUnitPrice(hammer);
        item.setQuantity(1);
        o.addItem(item);
        Order saved = orderRepository.save(o);
        orderService.recordHistory(saved, null, OrderStatus.PENDING_PAYMENT, null,
                secondChance ? "Mời mua lần hai" : "Hoá đơn lô thắng đấu giá");

        notifications.notify(buyerId, NotificationService.AUCTION_WON,
                secondChance ? "Cơ hội mua lô đấu giá" : "Bạn đã thắng đấu giá!",
                (secondChance ? "Người thắng không thanh toán. Bạn được mời mua \"" : "Bạn thắng \"")
                        + book.getTitle() + "\" với giá " + hammer.toPlainString() + "đ. Hãy thanh toán hoá đơn "
                        + saved.getCode() + " trước " + saved.getPaymentDueAt(),
                Map.of("orderId", saved.getId(), "lotId", lot.getId()));
        return saved;
    }

    // =====================================================================
    // Quá hạn thanh toán 48h
    // =====================================================================

    /** Mất cọc, bị cấm đấu giá, mời người trả giá cao thứ hai (hoặc lô quay lại chờ xếp phiên). */
    @Transactional
    public void handleOverdue(Long orderId) {
        Order o = orderService.lock(orderId);
        if (o.getStatus() != OrderStatus.PENDING_PAYMENT || o.getOrderType() != Order.Type.AUCTION) {
            return;
        }
        o.setCancelReason(o.isSecondChance() ? "Không nhận lời mời mua lần hai" : "Quá hạn thanh toán lô thắng");
        orderService.transition(o, OrderStatus.CANCELLED, null, o.getCancelReason());

        Lot lot = lotRepository.lockById(o.getLotId()).orElseThrow();
        if (!o.isSecondChance()) {
            forfeitAndBan(lot, o.getBuyerId(), o);
            // Giá người về nhì dưới giá sàn thì người bán chưa đồng ý bán ở mức đó → không mời.
            // Người đang bị cấm đấu giá, đang nợ hoặc là người ký gửi cũng bị bỏ qua → mời người kế tiếp.
            Bid second = eligibleRunnerUp(lot, o.getBuyerId());
            if (second != null) {
                BigDecimal price = fairSecondChancePrice(lot, o.getBuyerId(), second);
                lot.setWinnerId(second.getUserId());
                lot.setHammerPrice(price);
                createInvoice(lot, second.getUserId(), price, true, false);
                return;
            }
        }
        lot.resetToReady();
        notifySeller(lot, "Người mua không thanh toán, lô quay lại chờ xếp phiên sau");
    }

    /** Người được mời mua lần hai từ chối. */
    @Transactional
    public void declineSecondChance(Long userId, Long orderId) {
        Order o = orderService.lock(orderId);
        if (!o.getBuyerId().equals(userId) || !o.isSecondChance()) {
            throw ApiException.notFound("lời mời mua lần hai");
        }
        if (o.getStatus() != OrderStatus.PENDING_PAYMENT) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Lời mời không còn hiệu lực");
        }
        o.setCancelReason("Từ chối mua lần hai");
        orderService.transition(o, OrderStatus.CANCELLED, userId, o.getCancelReason());
        Lot lot = lotRepository.lockById(o.getLotId()).orElseThrow();
        lot.resetToReady();
        notifySeller(lot, "Lô không có người mua, quay lại chờ xếp phiên sau");
    }

    /** Người trả giá cao nhất (không phải người bỏ) còn đủ điều kiện nhận lời mời mua lần hai và có giá ≥ giá sàn. */
    private Bid eligibleRunnerUp(Lot lot, Long defaultedBuyerId) {
        if (lot.getOpenedAt() == null) {
            return null;
        }
        Long sellerId = sellerOf(lot);
        Set<Long> seen = new HashSet<>();
        for (Bid b : bidRepository.findTopExcluding(lot.getId(), lot.getOpenedAt(), defaultedBuyerId, PageRequest.of(0, 50))) {
            if (!seen.add(b.getUserId())) {
                continue; // chỉ xét lượt cao nhất của mỗi người
            }
            if (b.getAmount().compareTo(lot.getReservePrice()) < 0) {
                return null; // danh sách giảm dần: từ đây trở xuống đều dưới giá sàn
            }
            User u = userService.getUser(b.getUserId());
            if (!u.isAuctionBanned() && !u.getId().equals(sellerId) && !debts.hasOpenDebt(u.getId())) {
                return b;
            }
        }
        return null;
    }

    /**
     * Giá mời mua lần hai = giá người về nhì lẽ ra phải trả nếu không có người bỏ (BR-6.5):
     * max(giá sàn, min(giá cao nhất của người về nhì, giá cao nhất của người kế tiếp + 1 bước)).
     * Không có người kế tiếp thì bằng giá sàn. Kẻ đẩy giá rồi bỏ không còn ép được người mua thật trả giá tối đa của họ.
     */
    BigDecimal fairSecondChancePrice(Lot lot, Long defaultedBuyerId, Bid runnerUp) {
        BigDecimal other = null;
        for (Bid b : bidRepository.findTopExcluding(lot.getId(), lot.getOpenedAt(), defaultedBuyerId, PageRequest.of(0, 50))) {
            if (!b.getUserId().equals(runnerUp.getUserId())) {
                other = b.getAmount();
                break;
            }
        }
        BigDecimal wouldPay = other == null ? lot.getStartPrice() : other.add(views.increment(lot, other));
        return wouldPay.min(runnerUp.getAmount()).max(lot.getReservePrice());
    }

    /** Hoàn cọc và huỷ đăng ký ở các phiên chưa chốt khi người dùng bị khoá hoặc bị cấm đấu giá (không để họ bị kẹt vốn). */
    @Transactional
    public int releaseFutureRegistrations(Long userId, String reason) {
        int released = 0;
        for (AuctionRegistration reg : registrationRepository.findApprovedInOpenSessions(userId)) {
            walletService.release(userId, WalletTxType.DEPOSIT_RELEASE, reg.getDepositAmount(), "REGISTRATION", reg.getId(),
                    "Hoàn cọc: " + reason);
            reg.setStatus(reg.getStatus().moveTo(AuctionRegistration.Status.CANCELLED));
            proxyRepository.deactivateForUserInSession(userId, reg.getSessionId());
            audit.record(EventCode.AUCTION_REGISTRATION_CANCELLED, "SESSION", reg.getSessionId(), null, reason,
                    "deposit", reg.getDepositAmount(), "userId", userId);
            released++;
        }
        return released;
    }

    private void forfeitAndBan(Lot lot, Long userId, Order order) {
        User user = userService.getUser(userId);
        user.setAuctionBannedUntil(Instant.now().plus(config.days(SystemConfigService.AUCTION_BAN_DAYS)));
        BigDecimal[] forfeited = {BigDecimal.ZERO}; // cọc còn giữ đã bị thu ở lô này
        registrationRepository.lockBySessionIdAndUserId(lot.getSessionId(), userId)
                .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                .ifPresent(reg -> {
                    BigDecimal deposit = reg.getDepositAmount();
                    forfeited[0] = deposit;
                    reg.setStatus(reg.getStatus().moveTo(AuctionRegistration.Status.FORFEITED));
                    walletService.removeHeld(userId, WalletTxType.DEPOSIT_FORFEIT, deposit, "REGISTRATION", reg.getId(),
                            "Mất cọc do không thanh toán lô thắng");
                    // Chia tiền cọc: một phần bù cho người bán, phần còn lại cho sàn
                    BigDecimal sellerShare = Money.percent(deposit, config.decimal(SystemConfigService.FORFEIT_SELLER_PERCENT));
                    Long sellerId = sellerOf(lot);
                    walletService.credit(sellerId, WalletTxType.DEPOSIT_FORFEIT, sellerShare, "REGISTRATION", reg.getId(),
                            "Bồi thường từ tiền cọc người thắng bỏ thanh toán");
                    walletService.credit(null, WalletTxType.DEPOSIT_FORFEIT, deposit.subtract(sellerShare), "REGISTRATION",
                            reg.getId(), "Thu cọc người thắng bỏ thanh toán");
                    lot.setForfeitedPlatformTake(lot.getForfeitedPlatformTake().add(deposit.subtract(sellerShare)));
                });
        // Ghi lại để bù chênh cho người bán nếu lô bán lại thấp hơn (BR-6.2)
        if (lot.getDefaultedHammer() == null || lot.getDefaultedHammer().compareTo(order.getSubtotal()) < 0) {
            lot.setDefaultedHammer(order.getSubtotal());
        }
        releaseFutureRegistrations(userId, "Tài khoản bị cấm đấu giá"); // không để cọc các phiên khác bị kẹt
        // Phạt = % giá búa của lô; còn cọc thì mất cọc (SRS) và phạt không thấp hơn cọc. Phần vượt cọc thu từ ví, thiếu thì ghi nợ.
        BigDecimal pct = config.decimal(SystemConfigService.DEFAULT_PENALTY_PERCENT);
        BigDecimal penalty = Money.percent(order.getSubtotal(), pct).max(forfeited[0]);
        BigDecimal extra = penalty.subtract(forfeited[0]);
        if (extra.signum() > 0) {
            debts.create(userId, AccountDebt.Type.AUCTION_PENALTY, extra, "ORDER", order.getId(), sellerOf(lot),
                    config.decimal(SystemConfigService.FORFEIT_SELLER_PERCENT),
                    "Phạt bỏ thanh toán lô " + lot.getLotNumber() + " (đơn " + order.getCode() + ")");
        }
        audit.record(EventCode.AUCTION_DEFAULT_PENALIZED, "ORDER", order.getId(), order.getCode(), "Phạt bỏ thanh toán lô thắng",
                "hammer", order.getSubtotal(), "penaltyPercent", pct, "penalty", penalty, "fromDeposit", forfeited[0],
                "chargedToWalletOrDebt", extra, "bannedUntil", user.getAuctionBannedUntil());
        notifications.notify(userId, NotificationService.AUCTION, "Bạn bị phạt vì không thanh toán lô thắng",
                "Do không thanh toán lô thắng đúng hạn, bạn bị phạt " + penalty.toPlainString()
                        + "đ (trừ vào tiền cọc, ví hoặc ghi nợ) và bị cấm đấu giá đến "
                        + user.getAuctionBannedUntil(), Map.of("lotId", lot.getId()));
    }

    // =====================================================================
    // Huỷ phiên (thiếu người hoặc Admin huỷ)
    // =====================================================================

    public void onSessionCancelled(AuctionSession session) {
        for (AuctionRegistration reg : registrationRepository.findBySessionIdAndStatus(session.getId(), AuctionRegistration.Status.APPROVED)) {
            refundDeposit(reg, "Hoàn cọc do phiên bị huỷ");
            notifications.notify(reg.getUserId(), NotificationService.AUCTION, "Phiên đấu giá bị huỷ",
                    "Phiên \"" + session.getTitle() + "\" đã bị huỷ, tiền cọc đã được hoàn", Map.of("sessionId", session.getId()));
        }
        for (Lot lot : lotRepository.findBySessionIdOrderByLotNumberAsc(session.getId())) {
            if (lot.getStatus() == LotStatus.SCHEDULED) {
                lot.setRounds(Math.max(0, lot.getRounds() - 1)); // phiên không diễn ra thì không tính lượt
                lot.resetToReady();
                notifySeller(lot, "Phiên \"" + session.getTitle() + "\" bị huỷ. Lô quay về chờ xếp phiên, bạn có thể rút sách nếu muốn");
            }
        }
    }

    private void refundDeposit(AuctionRegistration reg, String note) {
        reg.setStatus(reg.getStatus().moveTo(AuctionRegistration.Status.REFUNDED));
        walletService.release(reg.getUserId(), WalletTxType.DEPOSIT_RELEASE, reg.getDepositAmount(), "REGISTRATION", reg.getId(), note);
    }

    // =====================================================================
    // Dòng tiền của đơn AUCTION
    // =====================================================================

    @EventListener
    public void onOrderStatusChanged(OrderStatusChangedEvent e) {
        Order o = e.order();
        if (o.getOrderType() != Order.Type.AUCTION) {
            return;
        }
        Lot lot = lotRepository.findById(o.getLotId()).orElseThrow();
        Long sellerId = sellerOf(lot);
        BigDecimal hammer = o.getSubtotal();
        BigDecimal platformShare = o.getBuyerPremium().add(o.getShippingFee());
        WarehouseItem wh = warehouseRepository.findByConsignmentId(lot.getConsignmentId()).orElse(null);

        switch (e.to()) {
            case PENDING_CONFIRM -> { // đã thanh toán
                applyDeposit(o, lot);
                walletService.addHeld(sellerId, WalletTxType.SALE_PENDING, hammer, REF, o.getId(),
                        "Tiền bán lô " + lot.getLotNumber() + " chờ người mua nhận hàng");
                walletService.credit(null, WalletTxType.FEE, platformShare, REF, o.getId(), "Phí người mua + phí giao đơn " + o.getCode());
                lot.setStatus(lot.getStatus().moveTo(LotStatus.PAID));
                if (wh != null) {
                    wh.setStatus(WarehouseItem.Status.RESERVED);
                }
                notifySeller(lot, "Lô " + lot.getLotNumber() + " đã được người thắng thanh toán");
            }
            case SHIPPING, DELIVERED -> {
                if (wh != null && wh.getStatus() != WarehouseItem.Status.SHIPPED) {
                    wh.setStatus(WarehouseItem.Status.SHIPPED);
                    wh.setCheckedOutAt(Instant.now());
                    wh.setCheckoutReason("SHIPPED_TO_WINNER");
                }
            }
            case COMPLETED -> { // trả người bán: giá gõ búa − hoa hồng
                BigDecimal commission = Money.percent(hammer, lot.getCommissionPercent() != null
                        ? lot.getCommissionPercent() : config.decimal(SystemConfigService.SELLER_COMMISSION));
                walletService.release(sellerId, WalletTxType.SALE_RELEASE, hammer, REF, o.getId(), "Giải ngân lô " + lot.getLotNumber());
                walletService.debit(sellerId, WalletTxType.FEE, commission, REF, o.getId(), "Hoa hồng đấu giá lô " + lot.getLotNumber());
                walletService.credit(null, WalletTxType.FEE, commission, REF, o.getId(), "Hoa hồng đấu giá đơn " + o.getCode());
                compensateSellerForDefault(lot, sellerId, hammer, o);
                lot.setStatus(lot.getStatus().moveTo(LotStatus.COMPLETED));
                notifySeller(lot, "Lô " + lot.getLotNumber() + " đã hoàn tất. Bạn nhận "
                        + hammer.subtract(commission).toPlainString() + "đ vào ví");
            }
            case RETURNED, FAILED_DELIVERY -> { // sàn đã kiểm định nên sàn chịu trách nhiệm, không đẩy cho người bán
                if (o.getPaidAt() != null) {
                    walletService.removeHeld(sellerId, WalletTxType.REFUND, hammer, REF, o.getId(), "Huỷ tiền chờ lô " + lot.getLotNumber());
                    walletService.debit(null, WalletTxType.REFUND, platformShare, REF, o.getId(), "Hoàn phí đơn " + o.getCode());
                    walletService.credit(o.getBuyerId(), WalletTxType.REFUND, o.getTotal(), REF, o.getId(), "Hoàn tiền đơn " + o.getCode());
                }
                if (wh != null) {
                    wh.setStatus(WarehouseItem.Status.IN_STOCK);
                    wh.setCheckedOutAt(null);
                    wh.setCheckoutReason(null);
                }
                // Sách đã qua tay người mua: phải kiểm định lại trước khi xếp phiên sau (docs/AUCTION_MONEY_FLOW.md 3.6)
                lot.setStatus(lot.getStatus().moveTo(LotStatus.INSPECTING));
                notifySeller(lot, "Lô " + lot.getLotNumber() + " bị trả lại kho, sẽ được kiểm định lại trước khi xếp phiên sau");
            }
            default -> {
            }
        }
    }

    /**
     * Lô từng bị người thắng bỏ thanh toán rồi bán lại thấp hơn: sàn bù cho người bán phần chênh sau hoa hồng,
     * tối đa bằng số sàn thực thu từ người bỏ cho lô này (cọc bị thu + phạt đã thu được). BR-6.2.
     * shortcut: phạt thu được sau thời điểm hoàn tất không được bù thêm; làm job bù bổ sung nếu chủ sàn cần.
     */
    private void compensateSellerForDefault(Lot lot, Long sellerId, BigDecimal hammer, Order o) {
        if (lot.getDefaultedHammer() == null || hammer.compareTo(lot.getDefaultedHammer()) >= 0) {
            return;
        }
        BigDecimal diff = lot.getDefaultedHammer().subtract(hammer);
        BigDecimal pct = lot.getCommissionPercent() != null ? lot.getCommissionPercent() : config.decimal(SystemConfigService.SELLER_COMMISSION);
        BigDecimal owed = diff.subtract(Money.percent(diff, pct));
        BigDecimal collected = lot.getForfeitedPlatformTake().add(debts.platformPenaltyCollectedForLot(lot.getId()));
        BigDecimal pay = owed.min(collected).min(walletService.platformAvailable());
        if (pay.signum() <= 0) {
            return;
        }
        walletService.debit(null, WalletTxType.COMPENSATION, pay, REF, o.getId(), "Bù chênh lô " + lot.getLotNumber() + " bị bỏ thanh toán");
        walletService.credit(sellerId, WalletTxType.COMPENSATION, pay, REF, o.getId(),
                "Sàn bù chênh giá do người thắng trước bỏ thanh toán lô " + lot.getLotNumber());
        audit.record(EventCode.AUCTION_SELLER_COMPENSATED, "ORDER", o.getId(), o.getCode(), "Bù chênh cho người bán",
                "defaultedHammer", lot.getDefaultedHammer(), "hammer", hammer, "owed", owed, "collected", collected, "paid", pay);
    }

    /** Cọc được trừ vào hoá đơn: chuyển phần đã áp khỏi held, trả lại phần dư (nếu cọc > hoá đơn). */
    private void applyDeposit(Order o, Lot lot) {
        if (o.getDepositApplied().signum() <= 0) {
            return;
        }
        registrationRepository.lockBySessionIdAndUserId(lot.getSessionId(), o.getBuyerId())
                .filter(r -> r.getStatus() == AuctionRegistration.Status.APPROVED)
                .ifPresent(reg -> {
                    walletService.removeHeld(o.getBuyerId(), WalletTxType.PAYMENT, o.getDepositApplied(), REF, o.getId(),
                            "Trừ tiền cọc vào hoá đơn " + o.getCode());
                    BigDecimal leftover = reg.getDepositAmount().subtract(o.getDepositApplied());
                    if (leftover.signum() > 0) {
                        walletService.release(o.getBuyerId(), WalletTxType.DEPOSIT_RELEASE, leftover, "REGISTRATION", reg.getId(),
                                "Hoàn phần cọc còn dư");
                    }
                    reg.setStatus(reg.getStatus().moveTo(AuctionRegistration.Status.APPLIED));
                });
    }

    /** Đổi cách nhận hàng của hoá đơn lô thắng (giao tận nơi / nhận tại kho), tính lại phí giao. */
    @Transactional
    public OrderDetail updateDelivery(Long userId, Long orderId, Long addressId, boolean pickup) {
        Order o = orderService.lock(orderId);
        if (!o.getBuyerId().equals(userId) || o.getOrderType() != Order.Type.AUCTION) {
            throw ApiException.notFound("hoá đơn đấu giá");
        }
        if (o.getStatus() != OrderStatus.PENDING_PAYMENT) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Chỉ đổi cách nhận khi chưa thanh toán");
        }
        if (pickup) {
            o.setPickupAtWarehouse(true);
            o.setAddressSnapshot(null);
            o.setShippingFee(BigDecimal.ZERO);
        } else {
            if (addressId == null) {
                throw ApiException.badRequest("ADDRESS_REQUIRED", "Chọn địa chỉ giao hàng");
            }
            Address a = userService.getAddress(userId, addressId);
            Lot lot = lotRepository.findById(o.getLotId()).orElseThrow();
            int weight = bookRepository.findById(lot.getBookId()).orElseThrow().getWeightGram();
            o.setPickupAtWarehouse(false);
            o.setAddressSnapshot(CheckoutService.snapshot(a));
            o.setShippingFee(shipping.fee(shipping.warehouseProvince(), a.getProvince(), weight));
        }
        o.setTotal(o.getSubtotal().add(o.getBuyerPremium()).add(o.getShippingFee()));
        if (o.getDepositApplied().compareTo(o.getTotal()) > 0) {
            o.setDepositApplied(o.getTotal());
        }
        reconsolidateShipping(o);
        return orderService.toDetail(o);
    }

    /**
     * Gộp kiện sau khi người mua đổi cách nhận: các hoá đơn giao tận nơi của cùng phiên được tính phí như một kiện,
     * lô sau chỉ trả phần tăng thêm so với các lô trước (docs/AUCTION_MONEY_FLOW.md 3.5). Chỉ đổi hoá đơn chưa thanh toán;
     * hoá đơn đã trả vẫn được tính vào khối lượng của kiện.
     * shortcut: phí tính theo tỉnh nhận của từng hoá đơn, giả định cùng một nơi nhận; khác tỉnh vẫn ra số hợp lý nhưng không tối ưu.
     */
    private void reconsolidateShipping(Order changed) {
        Long sessionId = lotRepository.findById(changed.getLotId()).orElseThrow().getSessionId();
        int prior = 0;
        for (Order x : orderRepository.findAuctionOrdersInSession(changed.getBuyerId(), sessionId)) {
            if (x.isPickupAtWarehouse() || x.getAddressSnapshot() == null) {
                continue;
            }
            Lot xl = lotRepository.findById(x.getLotId()).orElseThrow();
            int weight = bookRepository.findById(xl.getBookId()).orElseThrow().getWeightGram();
            if (x.getStatus() == OrderStatus.PENDING_PAYMENT) {
                String province = String.valueOf(x.getAddressSnapshot().get("province"));
                BigDecimal full = shipping.fee(shipping.warehouseProvince(), province, prior + weight);
                x.setShippingFee(prior > 0 ? full.subtract(shipping.fee(shipping.warehouseProvince(), province, prior)) : full);
                x.setTotal(x.getSubtotal().add(x.getBuyerPremium()).add(x.getShippingFee()));
                if (x.getDepositApplied().compareTo(x.getTotal()) > 0) {
                    x.setDepositApplied(x.getTotal());
                }
            }
            prior += weight;
        }
    }

    // ---- Nội bộ ----

    /** % phí người mua đã chốt vào phiên lúc công bố (BR-5.3); phiên cũ thì dùng cấu hình hiện tại. */
    private BigDecimal buyerPremiumPercent(Lot lot) {
        BigDecimal p = sessionRepository.findById(lot.getSessionId()).map(AuctionSession::getBuyerPremiumPercent).orElse(null);
        return p != null ? p : config.decimal(SystemConfigService.BUYER_PREMIUM);
    }

    public Long sellerOf(Lot lot) {
        return consignmentRepository.findById(lot.getConsignmentId()).map(Consignment::getSellerId).orElseThrow();
    }

    private void notifySeller(Lot lot, String text) {
        notifications.notify(sellerOf(lot), NotificationService.AUCTION, "Kết quả đấu giá", text,
                Map.of("lotId", lot.getId(), "consignmentId", lot.getConsignmentId()));
    }
}
