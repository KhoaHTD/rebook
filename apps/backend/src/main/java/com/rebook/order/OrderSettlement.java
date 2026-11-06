package com.rebook.order;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.catalog.ListingRepository;
import com.rebook.common.Money;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Shop;
import com.rebook.user.ShopRepository;
import com.rebook.wallet.Payment;
import com.rebook.wallet.WalletService;
import com.rebook.wallet.WalletTxType;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Dòng tiền giữ trung gian (escrow) cho đơn bán giá cố định:
 * <ul>
 *   <li>Đã thanh toán online → tiền vào held của người bán (SALE_PENDING)</li>
 *   <li>Hoàn tất → held → available (SALE_RELEASE), trừ phí sàn 5% (FEE) chuyển vào ví sàn</li>
 *   <li>Huỷ / giao thất bại / trả hàng → rút lại tiền chờ của người bán, hoàn tiền người mua vào ví, hoàn tồn kho</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class OrderSettlement {

    private static final String REF = "ORDER";

    private final WalletService walletService;
    private final ShopRepository shopRepository;
    private final ListingRepository listingRepository;
    private final SystemConfigService config;
    private final AuditLog audit;

    @EventListener
    public void onStatusChanged(OrderStatusChangedEvent e) {
        Order o = e.order();
        if (o.getOrderType() != Order.Type.NORMAL) {
            return;
        }
        Shop shop = shopRepository.findById(o.getShopId()).orElseThrow();
        Long sellerId = shop.getUserId();
        BigDecimal gross = o.getSubtotal().add(o.getShippingFee()); // shop tự giao nên nhận cả phí ship

        switch (e.to()) {
            case PENDING_CONFIRM -> {
                if (e.from() == OrderStatus.PENDING_PAYMENT && o.isPaidOnline()) {
                    walletService.addHeld(sellerId, WalletTxType.SALE_PENDING, gross, REF, o.getId(),
                            "Tiền bán đơn " + o.getCode() + " chờ hoàn tất");
                }
            }
            case COMPLETED -> {
                if (o.isPaidOnline()) {
                    walletService.release(sellerId, WalletTxType.SALE_RELEASE, gross, REF, o.getId(), "Giải ngân đơn " + o.getCode());
                    BigDecimal fee = Money.percent(o.getSubtotal(), feePercentOf(o));
                    walletService.debit(sellerId, WalletTxType.FEE, fee, REF, o.getId(), "Phí sàn đơn " + o.getCode());
                    walletService.credit(null, WalletTxType.FEE, fee, REF, o.getId(), "Phí sàn đơn " + o.getCode());
                } else if (o.getPaymentMethod() == Payment.Method.COD && o.getCodRemittedAt() != null) {
                    // COD: hãng vận chuyển thu hộ; chỉ trả shop khi sàn đã nhận tiền đối soát. Chưa đối soát thì
                    // CodService.remit sẽ trả ngay lúc sàn xác nhận nhận tiền.
                    payOutCod(o);
                }
            }
            case CANCELLED, FAILED_DELIVERY, RETURNED -> {
                if (e.to() == OrderStatus.FAILED_DELIVERY && o.isPaidOnline() && o.getDeliveryFault() == Order.DeliveryFault.BUYER) {
                    // BR-3.5: lỗi người mua thì hoàn tiền sách, phí giao chiều đi về shop (shop đã trả hãng vận chuyển)
                    walletService.removeHeld(sellerId, WalletTxType.REFUND, o.getSubtotal(), REF, o.getId(), "Huỷ tiền chờ đơn " + o.getCode());
                    walletService.release(sellerId, WalletTxType.SALE_RELEASE, o.getShippingFee(), REF, o.getId(),
                            "Phí giao chiều đi đơn " + o.getCode() + " (người mua không nhận hàng)");
                    walletService.credit(o.getBuyerId(), WalletTxType.REFUND, o.getSubtotal(), REF, o.getId(),
                            "Hoàn tiền đơn " + o.getCode() + " (đã trừ phí giao chiều đi)");
                } else if (o.isPaidOnline()) {
                    walletService.removeHeld(sellerId, WalletTxType.REFUND, gross, REF, o.getId(), "Huỷ tiền chờ đơn " + o.getCode());
                    walletService.credit(o.getBuyerId(), WalletTxType.REFUND, o.getTotal(), REF, o.getId(), "Hoàn tiền đơn " + o.getCode());
                } else if (e.to() == OrderStatus.RETURNED && o.getPaymentMethod() == Payment.Method.COD) {
                    // COD: tiền mặt nằm ở hãng vận chuyển. Sàn chỉ hoàn ví người mua khi đã nhận tiền đối soát,
                    // chưa nhận thì đánh dấu chờ và hoàn ngay lúc CodService.remit.
                    if (o.getCodRemittedAt() != null) {
                        refundCod(o);
                    } else {
                        o.setCodRefundPending(true);
                        audit.record(EventCode.COD_REFUND_PENDING, "ORDER", o.getId(), o.getCode(),
                                "Trả hàng COD chờ sàn nhận tiền đối soát", "total", o.getTotal());
                    }
                }
                // Trả hàng: sách chưa chắc còn nguyên vẹn nên không tự cộng lại tồn kho (shop tự chỉnh tồn sau khi kiểm sách).
                if (e.to() != OrderStatus.RETURNED) {
                    o.getItems().forEach(i -> listingRepository.restoreStock(i.getListingId(), i.getQuantity()));
                }
            }
            default -> {
            }
        }
    }

    /** Phí sàn (%) chụp lúc đặt; đơn cũ chưa có thì dùng cấu hình hiện tại. */
    private BigDecimal feePercentOf(Order o) {
        return o.getFeePercent() != null ? o.getFeePercent() : config.decimal(SystemConfigService.FIXED_PRICE_FEE);
    }

    /** Trả tiền COD cho shop sau khi sàn đã nhận tiền đối soát: trả đủ tiền hàng + ship rồi thu phí. Chỉ chạy một lần. */
    public void payOutCod(Order o) {
        if (o.getCodPaidOutAt() != null) {
            return;
        }
        Long sellerId = shopRepository.findById(o.getShopId()).orElseThrow().getUserId();
        BigDecimal gross = o.getSubtotal().add(o.getShippingFee());
        BigDecimal pct = feePercentOf(o);
        BigDecimal fee = Money.percent(o.getSubtotal(), pct);
        walletService.debit(null, WalletTxType.COD_PAYOUT, gross, REF, o.getId(), "Trả tiền COD đơn " + o.getCode());
        walletService.credit(sellerId, WalletTxType.SALE_RELEASE, gross, REF, o.getId(), "Tiền COD đã đối soát đơn " + o.getCode());
        walletService.debit(sellerId, WalletTxType.FEE, fee, REF, o.getId(), "Phí sàn đơn " + o.getCode());
        walletService.credit(null, WalletTxType.FEE, fee, REF, o.getId(), "Phí sàn đơn " + o.getCode());
        o.setCodPaidOutAt(Instant.now());
        audit.record(EventCode.COD_PAID_OUT, "ORDER", o.getId(), o.getCode(), "Trả tiền COD cho shop",
                "gross", gross, "fee", fee, "feePercent", pct, "sellerId", sellerId);
    }

    /** Hoàn tiền COD cho người mua vào ví sau khi sàn đã nhận tiền đối soát. Chỉ chạy một lần (cờ chờ hoàn được xoá). */
    public void refundCod(Order o) {
        walletService.debit(null, WalletTxType.REFUND, o.getTotal(), REF, o.getId(), "Hoàn tiền COD trả hàng đơn " + o.getCode());
        walletService.credit(o.getBuyerId(), WalletTxType.REFUND, o.getTotal(), REF, o.getId(), "Hoàn tiền trả hàng đơn " + o.getCode());
        o.setCodRefundPending(false);
        audit.record(EventCode.COD_REFUNDED, "ORDER", o.getId(), o.getCode(), "Hoàn tiền COD cho người mua",
                "total", o.getTotal(), "buyerId", o.getBuyerId());
    }
}
