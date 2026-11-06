package com.rebook.admin;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.auction.AuctionSettlement;
import com.rebook.catalog.ListingRepository;
import com.rebook.order.OrderRepository;
import com.rebook.order.OrderService;
import com.rebook.user.Shop;
import com.rebook.user.ShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Dọn việc dở khi khoá tài khoản: ẩn tin đang bán, huỷ và hoàn tiền đơn shop chưa giao cho vận chuyển,
 * huỷ đơn chưa thanh toán của người mua, hoàn cọc các phiên đấu giá chưa chốt. Đơn đã giao cho vận chuyển,
 * hoá đơn lô thắng (đi theo luồng phạt riêng) và yêu cầu rút tiền (Admin quyết) giữ nguyên.
 */
@Service
@RequiredArgsConstructor
public class AccountLockService {

    private final ShopRepository shopRepository;
    private final ListingRepository listingRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final AuctionSettlement auctionSettlement;
    private final AuditLog audit;

    @Transactional
    public void cleanUp(Long userId) {
        int hidden = 0;
        int sellerOrders = 0;
        Shop shop = shopRepository.findByUserId(userId).orElse(null);
        if (shop != null) {
            hidden = listingRepository.hideLiveListings(shop.getId());
            List<Long> open = orderRepository.findOpenSellerOrderIds(shop.getId());
            for (Long id : open) {
                orderService.cancelBySystem(id, "Tài khoản người bán bị khoá");
            }
            sellerOrders = open.size();
        }
        List<Long> unpaid = orderRepository.findUnpaidNormalOrderIdsOfBuyer(userId);
        for (Long id : unpaid) {
            orderService.cancelBySystem(id, "Tài khoản người mua bị khoá");
        }
        int registrations = auctionSettlement.releaseFutureRegistrations(userId, "Tài khoản bị khoá");
        audit.record(EventCode.ACCOUNT_LOCK_CLEANUP, "USER", userId, null, "Dọn việc dở khi khoá tài khoản",
                "listingsHidden", hidden, "sellerOrdersCancelled", sellerOrders, "buyerOrdersCancelled", unpaid.size(),
                "auctionRegistrationsReleased", registrations);
    }
}
