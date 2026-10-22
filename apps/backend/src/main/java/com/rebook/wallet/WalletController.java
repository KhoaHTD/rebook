package com.rebook.wallet;

import com.rebook.common.PageResponse;
import com.rebook.security.UserPrincipal;
import com.rebook.wallet.PaymentService.PaymentResponse;
import com.rebook.wallet.WalletDtos.TopUpRequest;
import com.rebook.wallet.WalletDtos.TransactionResponse;
import com.rebook.wallet.WalletDtos.WalletResponse;
import com.rebook.wallet.WalletDtos.WithdrawCreateRequest;
import com.rebook.wallet.WalletDtos.WithdrawResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.util.List;
import java.util.Map;

@Tag(name = "Wallet")
@RestController
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;
    private final PaymentService paymentService;

    @Operation(summary = "Số dư ví")
    @GetMapping("/wallet")
    public WalletResponse wallet(@AuthenticationPrincipal UserPrincipal me) {
        return walletService.summary(me.id());
    }

    @Operation(summary = "Lịch sử giao dịch ví (sổ cái)")
    @GetMapping("/wallet/transactions")
    public PageResponse<TransactionResponse> transactions(@AuthenticationPrincipal UserPrincipal me,
                                                          @RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        return walletService.transactions(me.id(), page, size);
    }

    @Operation(summary = "Nạp tiền qua VNPay sandbox — trả về paymentUrl để mở trình duyệt")
    @PostMapping("/wallet/top-up")
    @ResponseStatus(HttpStatus.CREATED)
    public PaymentResponse topUp(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody TopUpRequest req,
                                 HttpServletRequest http) {
        return paymentService.createVnpay(me.id(), Payment.Purpose.TOP_UP, req.amount(), Duration.ofMinutes(15),
                "Nap tien vi ReBook", http.getRemoteAddr());
    }

    @Operation(summary = "Tạo yêu cầu rút tiền (Admin duyệt)")
    @PostMapping("/wallet/withdrawals")
    @ResponseStatus(HttpStatus.CREATED)
    public WithdrawResponse withdraw(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody WithdrawCreateRequest req) {
        return walletService.requestWithdraw(me.id(), req);
    }

    @GetMapping("/wallet/withdrawals")
    public List<WithdrawResponse> myWithdrawals(@AuthenticationPrincipal UserPrincipal me) {
        return walletService.myWithdrawals(me.id());
    }

    @Operation(summary = "Trạng thái một thanh toán")
    @GetMapping("/payments/{code}")
    public PaymentResponse payment(@AuthenticationPrincipal UserPrincipal me, @PathVariable String code) {
        return paymentService.get(me.id(), code);
    }

    @Operation(summary = "[DEV] Giả lập VNPay trả về thành công (chỉ khi app.payment.simulate-enabled=true)")
    @PostMapping("/payments/{code}/simulate")
    public PaymentResponse simulate(@AuthenticationPrincipal UserPrincipal me, @PathVariable String code) {
        return paymentService.simulateSuccess(me.id(), code);
    }

    @Operation(summary = "IPN VNPay gọi về (server-to-server)")
    @GetMapping("/payments/vnpay/ipn")
    public Map<String, String> vnpayIpn(@RequestParam Map<String, String> params) {
        return paymentService.handleVnpayCallback(params);
    }

    /**
     * Trình duyệt quay về sau khi thanh toán. Khi chạy localhost VNPay không gọi được IPN,
     * nên return URL cũng xác nhận giao dịch (idempotent, có kiểm chữ ký).
     */
    @Operation(summary = "Return URL của VNPay")
    @GetMapping("/payments/vnpay/return")
    public Map<String, String> vnpayReturn(@RequestParam Map<String, String> params) {
        Map<String, String> rsp = paymentService.handleVnpayCallback(params);
        boolean success = "00".equals(params.get("vnp_ResponseCode"))
                && ("00".equals(rsp.get("RspCode")) || "02".equals(rsp.get("RspCode")));
        return Map.of("paymentCode", String.valueOf(params.get("vnp_TxnRef")),
                "result", success ? "SUCCESS" : "FAILED",
                "message", success ? "Thanh toán thành công, bạn có thể quay lại ứng dụng" : "Thanh toán không thành công");
    }
}
