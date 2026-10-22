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

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "withdraw_requests")
@Getter
@Setter
@NoArgsConstructor
public class WithdrawRequest {

    public enum Status { PENDING, APPROVED, REJECTED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private BigDecimal amount;
    private String bankName;
    private String accountNumber;
    private String accountHolder;

    @Enumerated(EnumType.STRING)
    private Status status = Status.PENDING;

    private String note;
    private Long processedBy;
    private Instant processedAt;

    @CreationTimestamp
    private Instant createdAt;
}
