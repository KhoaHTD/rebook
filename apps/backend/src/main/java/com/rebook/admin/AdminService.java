package com.rebook.admin;

import com.rebook.audit.ActivityLogService;
import com.rebook.auction.AuctionSessionRepository;
import com.rebook.auction.LotRepository;
import com.rebook.auction.SessionStatus;
import com.rebook.auth.RefreshTokenRepository;
import com.rebook.catalog.ListingRepository;
import com.rebook.catalog.ListingStatus;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.common.PageResponse;
import com.rebook.order.OrderRepository;
import com.rebook.order.OrderStatus;
import com.rebook.user.Role;
import com.rebook.user.Shop;
import com.rebook.user.ShopRepository;
import com.rebook.user.User;
import com.rebook.user.UserDtos.ShopResponse;
import com.rebook.user.UserDtos.UserResponse;
import com.rebook.user.UserRepository;
import com.rebook.user.UserStatus;
import com.rebook.wallet.WalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.EnumSet;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final ShopRepository shopRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final ListingRepository listingRepository;
    private final OrderRepository orderRepository;
    private final LotRepository lotRepository;
    private final AuctionSessionRepository sessionRepository;
    private final WalletService walletService;
    private final ActivityLogService activityLog;

    public record DashboardResponse(BigDecimal revenueThisMonth, long ordersThisMonth, long ordersInProgress,
                                    long pendingListings, long activeListings, long liveSessions,
                                    long upcomingSessions, double lotSellThroughRate, BigDecimal platformBalance) {
    }

    @Transactional(readOnly = true)
    public PageResponse<UserResponse> users(String q, Role role, UserStatus status, int page, int size) {
        return PageResponse.of(userRepository.search(q == null ? "" : q.trim(), role, status,
                        PageRequest.of(page, size, Sort.by("id").descending())),
                u -> UserResponse.of(u, shopRepository.findByUserId(u.getId()).map(Shop::getId).orElse(null)));
    }

    /** Khoá tài khoản vi phạm: thu hồi mọi refresh token để đăng xuất ngay. */
    @Transactional
    public UserResponse lock(Long adminId, Long userId, String reason) {
        if (adminId.equals(userId)) {
            throw ApiException.badRequest("SELF_LOCK", "Không thể tự khoá tài khoản của mình");
        }
        User u = user(userId);
        u.setStatus(UserStatus.LOCKED);
        u.setLockReason(reason);
        refreshTokenRepository.revokeAllForUser(userId);
        activityLog.record(adminId, "LOCK_USER", ActivityLogService.USER, userId, "Khoá " + u.getEmail() + ": " + reason);
        return UserResponse.of(u, null);
    }

    @Transactional
    public UserResponse unlock(Long adminId, Long userId) {
        User u = user(userId);
        u.setStatus(UserStatus.ACTIVE);
        u.setLockReason(null);
        activityLog.record(adminId, "UNLOCK_USER", ActivityLogService.USER, userId, "Mở khoá " + u.getEmail());
        return UserResponse.of(u, null);
    }

    @Transactional
    public UserResponse changeRole(Long adminId, Long userId, Role role) {
        if (adminId.equals(userId)) {
            throw ApiException.badRequest("SELF_ROLE", "Không thể đổi quyền của chính mình");
        }
        User u = user(userId);
        Role old = u.getRole();
        u.setRole(role);
        refreshTokenRepository.revokeAllForUser(userId); // token cũ còn role cũ
        activityLog.record(adminId, "CHANGE_ROLE", ActivityLogService.USER, userId,
                "Đổi quyền " + u.getEmail() + ": " + old + " → " + role);
        return UserResponse.of(u, null);
    }

    @Transactional
    public UserResponse liftAuctionBan(Long adminId, Long userId) {
        User u = user(userId);
        u.setAuctionBannedUntil(null);
        activityLog.record(adminId, "LIFT_AUCTION_BAN", ActivityLogService.USER, userId, "Gỡ cấm đấu giá " + u.getEmail());
        return UserResponse.of(u, null);
    }

    /** Shop uy tín được tự duyệt tin đăng. */
    @Transactional
    public ShopResponse setShopTrusted(Long adminId, Long shopId, boolean trusted) {
        Shop s = shopRepository.findById(shopId).orElseThrow(() -> ApiException.notFound("shop"));
        s.setTrusted(trusted);
        activityLog.record(adminId, trusted ? "TRUST_SHOP" : "UNTRUST_SHOP", ActivityLogService.SHOP, shopId,
                (trusted ? "Đánh dấu uy tín shop " : "Bỏ uy tín shop ") + s.getName());
        return ShopResponse.ownerView(s);
    }

    @Transactional
    public void logConfigChange(Long adminId, String key, String value) {
        activityLog.record(adminId, "UPDATE_CONFIG", ActivityLogService.CONFIG, key, "Đặt " + key + " = " + value);
    }

    @Transactional(readOnly = true)
    public DashboardResponse dashboard() {
        Instant monthStart = LocalDate.now(CodeGenerator.VN).withDayOfMonth(1).atStartOfDay(CodeGenerator.VN).toInstant();
        long closed = lotRepository.countClosedEver();
        double rate = closed == 0 ? 0 : BigDecimal.valueOf(lotRepository.countSoldEver() * 100.0 / closed)
                .setScale(1, RoundingMode.HALF_UP).doubleValue();
        return new DashboardResponse(
                orderRepository.sumCompletedSince(monthStart),
                orderRepository.countCreatedSince(monthStart),
                orderRepository.countByStatusIn(EnumSet.of(OrderStatus.PENDING_CONFIRM, OrderStatus.PREPARING,
                        OrderStatus.SHIPPING, OrderStatus.DELIVERED, OrderStatus.RETURN_REQUESTED)),
                listingRepository.countByStatus(ListingStatus.PENDING_REVIEW),
                listingRepository.countByStatus(ListingStatus.ACTIVE),
                sessionRepository.countByStatus(SessionStatus.LIVE),
                sessionRepository.countByStatus(SessionStatus.PUBLISHED) + sessionRepository.countByStatus(SessionStatus.CONFIRMED),
                rate,
                walletService.platformSummary().availableBalance());
    }

    private User user(Long id) {
        return userRepository.findById(id).orElseThrow(() -> ApiException.notFound("người dùng"));
    }
}
