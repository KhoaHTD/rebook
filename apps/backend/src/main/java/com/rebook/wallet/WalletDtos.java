package com.rebook.wallet;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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

    public record TopUpRequest(@NotNull @DecimalMin(value = "10000", message = "Nạp tối thiểu 10.000đ") BigDecimal amount) {
    }

    public record WithdrawCreateRequest(
            @NotNull @DecimalMin(value = "50000", message = "Rút tối thiểu 50.000đ") BigDecimal amount,
            @NotBlank String bankName,
            @NotBlank String accountNumber,
            @NotBlank String accountHolder) {
    }

    public record TransferReceipt(String senderName, Instant transferTime, BigDecimal amount, String proofImageUrl) {

        public static TransferReceipt of(WithdrawTransfer t) {
            return t == null ? null : new TransferReceipt(t.getSenderName(), t.getTransferTime(), t.getAmount(), t.getProofImageUrl());
        }
    }

    public record WithdrawResponse(Long id, Long userId, String userName, BigDecimal amount, String bankName,
                                   String accountNumber, String accountHolder, WithdrawRequest.Status status,
                                   String note, Long processedBy, String processedByName, Instant processedAt,
                                   Instant createdAt, TransferReceipt transfer) {

        public static WithdrawResponse of(WithdrawRequest w, String userName, String processedByName, WithdrawTransfer transfer) {
            return new WithdrawResponse(w.getId(), w.getUserId(), userName, w.getAmount(), w.getBankName(),
                    w.getAccountNumber(), w.getAccountHolder(), w.getStatus(), w.getNote(), w.getProcessedBy(),
                    processedByName, w.getProcessedAt(), w.getCreatedAt(), TransferReceipt.of(transfer));
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
