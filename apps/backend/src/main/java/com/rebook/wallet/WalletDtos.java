package com.rebook.wallet;

import com.rebook.common.WholeVnd;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public final class WalletDtos {

    private WalletDtos() {
    }

    public record WalletResponse(BigDecimal availableBalance, BigDecimal heldBalance) {

        public static WalletResponse of(Wallet w) {
            return new WalletResponse(w.getAvailableBalance(), w.getHeldBalance());
        }
    }

    public record TransactionResponse(Long id, WalletTxType type, BigDecimal availableChange, BigDecimal heldChange,
                                      BigDecimal availableAfter, BigDecimal heldAfter, String refType, Long refId,
                                      String note, Instant createdAt) {

        public static TransactionResponse of(WalletTransaction t) {
            return new TransactionResponse(t.getId(), t.getType(), t.getAvailableChange(), t.getHeldChange(),
                    t.getAvailableAfter(), t.getHeldAfter(), t.getRefType(), t.getRefId(), t.getNote(), t.getCreatedAt());
        }
    }

    /**
     * Số tiền rút được ngay: tiền mới nạp chưa dùng bị khoá tới {@code unlockAt}; tiền bán hàng của shop mới bị giữ
     * ({@code saleHeld}) tới {@code saleUnlockAt} (xem WalletService.withdrawable).
     */
    public record WithdrawableResponse(BigDecimal available, BigDecimal locked, BigDecimal withdrawable, Instant unlockAt,
                                       BigDecimal saleHeld, Instant saleUnlockAt) {
    }

    public record TopUpRequest(@NotNull @WholeVnd @DecimalMin(value = "10000", message = "Nạp tối thiểu 10.000đ") BigDecimal amount) {
    }

    public record WithdrawCreateRequest(
            @NotNull @WholeVnd @DecimalMin(value = "50000", message = "Rút tối thiểu 50.000đ") BigDecimal amount,
            @NotBlank String bankName,
            @NotBlank @Pattern(regexp = "\\d{6,19}", message = "Số tài khoản gồm 6–19 chữ số") String accountNumber,
            @NotBlank String accountHolder,
            @Size(max = 200) String note) {
    }

    public record TransferReceipt(String senderName, Instant transferTime, BigDecimal amount, String proofImageUrl) {

        public static TransferReceipt of(WithdrawTransfer t) {
            return t == null ? null : new TransferReceipt(t.getSenderName(), t.getTransferTime(), t.getAmount(), t.getProofImageUrl());
        }
    }

    public record BankAccountResponse(Long id, String bankName, String accountNumber, String accountHolder,
                                      boolean favorite, Instant lastUsedAt) {

        public static BankAccountResponse of(BankAccount a) {
            return new BankAccountResponse(a.getId(), a.getBankName(), a.getAccountNumber(), a.getAccountHolder(),
                    a.isFavorite(), a.getLastUsedAt());
        }
    }

    public record WithdrawResponse(Long id, Long userId, String userName, BigDecimal amount, String bankName,
                                   String accountNumber, String accountHolder, WithdrawRequest.Status status,
                                   String note, Long processedBy, String processedByName, Instant processedAt,
                                   Instant createdAt, TransferReceipt transfer, String userNote) {

        public static WithdrawResponse of(WithdrawRequest w, String userName, String processedByName, WithdrawTransfer transfer) {
            return new WithdrawResponse(w.getId(), w.getUserId(), userName, w.getAmount(), w.getBankName(),
                    w.getAccountNumber(), w.getAccountHolder(), w.getStatus(), w.getNote(), w.getProcessedBy(),
                    processedByName, w.getProcessedAt(), w.getCreatedAt(), TransferReceipt.of(transfer),
                    w.getUserNote());
        }
    }

    /**
     * Duyệt (approve = true) cần đủ thông tin chuyển khoản thủ công: người chuyển, giờ chuyển,
     * số tiền thực chuyển và ảnh biên lai (URL lấy từ {@code POST /files}). Từ chối chỉ cần ghi chú.
     */
    public record ProcessRequest(boolean approve, @Size(max = 500) String note,
                                 @Size(max = 120) String senderName, Instant transferTime,
                                 BigDecimal transferAmount, @Size(max = 500) String proofImageUrl) {
    }
}
