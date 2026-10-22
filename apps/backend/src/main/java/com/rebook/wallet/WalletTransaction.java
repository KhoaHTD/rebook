package com.rebook.wallet;

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
import org.hibernate.annotations.Immutable;

import java.math.BigDecimal;
import java.time.Instant;

/** Một dòng sổ cái. Không bao giờ sửa / xoá. */
@Entity
@Immutable
@Table(name = "wallet_transactions")
@Getter
@Setter
@NoArgsConstructor
public class WalletTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long walletId;

    @Enumerated(EnumType.STRING)
    private WalletTxType type;

    private BigDecimal availableChange;
    private BigDecimal heldChange;
    private BigDecimal availableAfter;
    private BigDecimal heldAfter;
    private String refType;
    private Long refId;
    private String note;

    @CreationTimestamp
    private Instant createdAt;
}
