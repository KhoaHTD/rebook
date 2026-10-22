package com.rebook.wallet;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

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

    public record WithdrawResponse(Long id, Long userId, BigDecimal amount, String bankName, String accountNumber,
                                   String accountHolder, WithdrawRequest.Status status, String note,
                                   Instant processedAt, Instant createdAt) {

        public static WithdrawResponse of(WithdrawRequest w) {
            return new WithdrawResponse(w.getId(), w.getUserId(), w.getAmount(), w.getBankName(), w.getAccountNumber(),
                    w.getAccountHolder(), w.getStatus(), w.getNote(), w.getProcessedAt(), w.getCreatedAt());
        }
    }

    public record ProcessRequest(boolean approve, String note) {
    }
}
