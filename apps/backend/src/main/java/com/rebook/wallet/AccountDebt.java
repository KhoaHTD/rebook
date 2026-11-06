package com.rebook.wallet;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Nợ của người dùng với sàn: phạt bỏ thanh toán lô đấu giá hoặc phí lưu kho chưa thu đủ.
 * Còn nợ OPEN thì không đăng ký phiên, không trả giá, không rút tiền (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần B mục 3.2).
 */
@Entity
@Table(name = "account_debts")
@Getter
@Setter
@NoArgsConstructor
public class AccountDebt {

    @Schema(name = "DebtType", enumAsRef = true)
    public enum Type { AUCTION_PENALTY, STORAGE_FEE, CHARGEBACK }

    @Schema(name = "DebtStatus", enumAsRef = true)
    public enum Status { OPEN, PAID, WAIVED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    @Enumerated(EnumType.STRING)
    private Type type;

    private BigDecimal amount;
    private BigDecimal paidAmount = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    private Status status = Status.OPEN;

    private String refType;
    private Long refId;

    /** Người nhận phần chia khi thu nợ (người bán của lô). Null = cả khoản về ví sàn. */
    private Long beneficiaryId;
    private BigDecimal beneficiaryPercent = BigDecimal.ZERO;

    private String note;
    private Long waivedBy;

    @CreationTimestamp
    private Instant createdAt;

    private Instant settledAt;

    public BigDecimal remaining() {
        return amount.subtract(paidAmount);
    }
}
