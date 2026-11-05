package com.rebook.wallet;

import com.rebook.security.UserPrincipal;
import com.rebook.wallet.DebtService.CollectResult;
import com.rebook.wallet.DebtService.DebtResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Debts")
@RestController
@RequiredArgsConstructor
public class DebtController {

    private final DebtService debtService;

    public record WaiveRequest(@NotBlank @Size(min = 5, max = 500) String reason) {
    }

    @Operation(summary = "Nợ phạt / phí kho của tôi")
    @GetMapping("/me/debts")
    public List<DebtResponse> mine(@AuthenticationPrincipal UserPrincipal me) {
        return debtService.mine(me.id());
    }

    @Operation(summary = "Thu nợ ngay từ số dư dùng được của ví (cũ nhất trước)")
    @PostMapping("/me/debts/collect")
    public CollectResult collect(@AuthenticationPrincipal UserPrincipal me) {
        return debtService.collectNow(me.id());
    }

    @Operation(summary = "[Admin] Miễn một khoản nợ (không gỡ lệnh cấm đấu giá)")
    @PostMapping("/admin/debts/{id}/waive")
    public DebtResponse waive(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                              @Valid @RequestBody WaiveRequest req) {
        return debtService.waive(me.id(), id, req.reason());
    }
}
