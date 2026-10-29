package com.rebook.admin;

import com.rebook.admin.AdminService.DashboardResponse;
import com.rebook.audit.ActivityLogService;
import com.rebook.audit.ActivityLogService.ActivityLogResponse;
import com.rebook.common.PageResponse;
import com.rebook.security.UserPrincipal;
import com.rebook.system.SystemConfig;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Role;
import com.rebook.user.UserDtos.ShopResponse;
import com.rebook.user.UserDtos.UserResponse;
import com.rebook.user.UserStatus;
import com.rebook.wallet.WalletDtos.ProcessRequest;
import com.rebook.wallet.WalletDtos.WalletResponse;
import com.rebook.wallet.WalletDtos.WithdrawResponse;
import com.rebook.wallet.WithdrawRequest;
import com.rebook.wallet.WalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Admin")
@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final SystemConfigService configService;
    private final WalletService walletService;
    private final ActivityLogService activityLogService;

    public record LockRequest(@NotBlank @Size(max = 500) String reason) {
    }

    public record RoleRequest(@NotNull Role role) {
    }

    public record TrustedRequest(boolean trusted) {
    }

    public record ConfigRequest(@NotBlank @Size(max = 500) String value) {
    }

    @Operation(summary = "Dashboard: doanh thu, số đơn, tỷ lệ lô bán được")
    @GetMapping("/dashboard")
    public DashboardResponse dashboard() {
        return adminService.dashboard();
    }

    @GetMapping("/users")
    public PageResponse<UserResponse> users(@RequestParam(required = false) String q,
                                            @RequestParam(required = false) Role role,
                                            @RequestParam(required = false) UserStatus status,
                                            @RequestParam(defaultValue = "0") int page,
                                            @RequestParam(defaultValue = "20") int size) {
        return adminService.users(q, role, status, page, size);
    }

    @Operation(summary = "Khoá tài khoản vi phạm")
    @PostMapping("/users/{id}/lock")
    public UserResponse lock(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id, @Valid @RequestBody LockRequest req) {
        return adminService.lock(me.id(), id, req.reason());
    }

    @PostMapping("/users/{id}/unlock")
    public UserResponse unlock(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return adminService.unlock(me.id(), id);
    }

    @Operation(summary = "Đổi role (USER / STAFF / ADMIN)")
    @PutMapping("/users/{id}/role")
    public UserResponse role(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id, @Valid @RequestBody RoleRequest req) {
        return adminService.changeRole(me.id(), id, req.role());
    }

    @PostMapping("/users/{id}/lift-auction-ban")
    public UserResponse liftBan(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return adminService.liftAuctionBan(me.id(), id);
    }

    @Operation(summary = "Đánh dấu shop uy tín (tin đăng được tự duyệt)")
    @PutMapping("/shops/{id}/trusted")
    public ShopResponse trusted(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id, @RequestBody TrustedRequest req) {
        return adminService.setShopTrusted(me.id(), id, req.trusted());
    }

    @Operation(summary = "Cấu hình phí sàn, hoa hồng, bước giá, thời hạn")
    @GetMapping("/configs")
    public List<SystemConfig> configs() {
        return configService.all();
    }

    @PutMapping("/configs/{key}")
    public SystemConfig updateConfig(@AuthenticationPrincipal UserPrincipal me, @PathVariable String key,
                                     @Valid @RequestBody ConfigRequest req) {
        SystemConfig updated = configService.update(key, req.value());
        adminService.logConfigChange(me.id(), key, req.value());
        return updated;
    }

    @Operation(summary = "Yêu cầu rút tiền theo trạng thái (mặc định PENDING; APPROVED / REJECTED để xem lịch sử duyệt)")
    @GetMapping("/withdrawals")
    public PageResponse<WithdrawResponse> withdrawals(@RequestParam(required = false) WithdrawRequest.Status status,
                                                      @RequestParam(defaultValue = "0") int page,
                                                      @RequestParam(defaultValue = "20") int size) {
        return walletService.withdrawals(status, page, size);
    }

    @Operation(summary = "Duyệt rút tiền (kèm biên lai chuyển khoản thủ công) hoặc từ chối")
    @PostMapping("/withdrawals/{id}")
    public WithdrawResponse processWithdrawal(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                              @Valid @RequestBody ProcessRequest req) {
        return walletService.processWithdraw(me.id(), id, req);
    }

    @Operation(summary = "Lịch sử thao tác của Admin (duyệt tin, duyệt rút tiền, khoá tài khoản, đổi cấu hình...)")
    @GetMapping("/activity-logs")
    public PageResponse<ActivityLogResponse> activityLogs(@RequestParam(required = false) String targetType,
                                                          @RequestParam(required = false) String action,
                                                          @RequestParam(required = false) Long adminId,
                                                          @RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        return activityLogService.search(targetType, action, adminId, page, size);
    }

    @Operation(summary = "Số dư ví sàn (phí đã thu)")
    @GetMapping("/platform-wallet")
    public WalletResponse platformWallet() {
        return walletService.platformSummary();
    }
}
