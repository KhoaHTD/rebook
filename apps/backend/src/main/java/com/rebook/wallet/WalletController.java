package com.rebook.wallet;

import com.rebook.common.PageResponse;
import com.rebook.config.AppProperties;
import com.rebook.security.UserPrincipal;
import com.rebook.wallet.PaymentService.PaymentResponse;
import com.rebook.wallet.WalletDtos.BankAccountResponse;
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
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
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
    private final AppProperties props;

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

    @Operation(summary = "Nạp tiền qua ZaloPay sandbox — trả về paymentUrl để mở trình duyệt")
    @PostMapping("/wallet/top-up")
    @ResponseStatus(HttpStatus.CREATED)
    public PaymentResponse topUp(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody TopUpRequest req,
                                 HttpServletRequest http) {
        return paymentService.createZaloPay(me.id(), Payment.Purpose.TOP_UP, req.amount(), Duration.ofMinutes(15),
                "ReBook - Nạp tiền vào ví");
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

    @Operation(summary = "Tài khoản ngân hàng đã dùng để rút tiền (yêu thích trước, rồi mới dùng gần nhất)")
    @GetMapping("/wallet/bank-accounts")
    public List<BankAccountResponse> bankAccounts(@AuthenticationPrincipal UserPrincipal me) {
        return walletService.bankAccounts(me.id());
    }

    @Operation(summary = "Đánh dấu yêu thích một tài khoản ngân hàng đã lưu")
    @PostMapping("/wallet/bank-accounts/{id}/favorite")
    public BankAccountResponse favoriteBankAccount(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return walletService.setBankAccountFavorite(me.id(), id, true);
    }

    @DeleteMapping("/wallet/bank-accounts/{id}/favorite")
    public BankAccountResponse unfavoriteBankAccount(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return walletService.setBankAccountFavorite(me.id(), id, false);
    }

    @Operation(summary = "Trạng thái một thanh toán")
    @GetMapping("/payments/{code}")
    public PaymentResponse payment(@AuthenticationPrincipal UserPrincipal me, @PathVariable String code) {
        return paymentService.get(me.id(), code);
    }

    @Operation(summary = "[DEV] Giả lập cổng thanh toán trả về thành công (chỉ khi app.payment.simulate-enabled=true)")
    @PostMapping("/payments/{code}/simulate")
    public PaymentResponse simulate(@AuthenticationPrincipal UserPrincipal me, @PathVariable String code) {
        return paymentService.simulateSuccess(me.id(), code);
    }

    /** Callback server-to-server của ZaloPay (chỉ tới được khi backend có địa chỉ công khai, đặt ZALOPAY_CALLBACK_URL). */
    @Operation(summary = "Callback ZaloPay (server-to-server)")
    @PostMapping("/payments/zalopay/callback")
    public Map<String, Object> zalopayCallback(@RequestBody Map<String, Object> body) {
        return paymentService.handleZaloPayCallback(String.valueOf(body.get("data")), String.valueOf(body.get("mac")));
    }

    /**
     * Trình duyệt quay về sau khi thanh toán ZaloPay. Máy dev chạy localhost ZaloPay không gọi callback được,
     * nên trang này kiểm checksum rồi hỏi ZaloPay để chốt giao dịch (idempotent).
     */
    @Operation(summary = "Redirect URL của ZaloPay: xác nhận giao dịch rồi hiện trang kết quả cho người dùng")
    @GetMapping(value = "/payments/zalopay/return", produces = MediaType.TEXT_HTML_VALUE)
    public String zalopayReturn(@RequestParam Map<String, String> params) {
        PaymentService.ReturnResult r = paymentService.handleZaloPayReturn(params);
        return PaymentReturnPage.render(r.status(), r.code(), props.payment().appUrl());
    }
}
