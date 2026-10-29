package com.rebook.wallet;

import jakarta.persistence.Entity;
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

/** Biên lai chuyển khoản thủ công của một yêu cầu rút tiền đã duyệt. */
@Entity
@Table(name = "withdraw_transfers")
@Getter
@Setter
@NoArgsConstructor
public class WithdrawTransfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long withdrawId;
    private Long adminId;
    private String senderName;
    private Instant transferTime;
    private BigDecimal amount;
    private String proofImageUrl;

    @CreationTimestamp
    private Instant createdAt;
}
