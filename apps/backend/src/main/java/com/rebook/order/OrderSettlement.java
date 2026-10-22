package com.rebook.order;

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
                } else { // COD: sàn đã thu hộ tiền mặt khi giao
                    walletService.credit(sellerId, WalletTxType.SALE_RELEASE, gross, REF, o.getId(), "Tiền thu hộ COD đơn " + o.getCode());
                }
                BigDecimal fee = Money.percent(o.getSubtotal(), config.decimal(SystemConfigService.FIXED_PRICE_FEE));
                walletService.debit(sellerId, WalletTxType.FEE, fee, REF, o.getId(), "Phí sàn đơn " + o.getCode());
                walletService.credit(null, WalletTxType.FEE, fee, REF, o.getId(), "Phí sàn đơn " + o.getCode());
            }
            case CANCELLED, FAILED_DELIVERY, RETURNED -> {
                if (o.isPaidOnline()) {
                    walletService.removeHeld(sellerId, WalletTxType.REFUND, gross, REF, o.getId(), "Huỷ tiền chờ đơn " + o.getCode());
                    walletService.credit(o.getBuyerId(), WalletTxType.REFUND, o.getTotal(), REF, o.getId(), "Hoàn tiền đơn " + o.getCode());
                } else if (e.to() == OrderStatus.RETURNED && o.getPaymentMethod() == Payment.Method.COD) {
                    // COD đã trả tiền mặt khi nhận hàng → hoàn vào ví
                    walletService.credit(o.getBuyerId(), WalletTxType.REFUND, o.getTotal(), REF, o.getId(), "Hoàn tiền trả hàng đơn " + o.getCode());
                }
                o.getItems().forEach(i -> listingRepository.restoreStock(i.getListingId(), i.getQuantity()));
            }
            default -> {
            }
        }
    }
}
