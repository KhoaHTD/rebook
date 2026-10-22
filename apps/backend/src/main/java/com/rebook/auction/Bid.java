package com.rebook.auction;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

/** Lượt trả giá. Chỉ thêm, không sửa / xoá. */
@Entity
@Immutable
@Table(name = "bids")
@Getter
@Setter
@NoArgsConstructor
public class Bid {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long lotId;
    private Long userId;
    private Long registrationId;
    private BigDecimal amount;

    /** true = do hệ thống trả hộ (proxy bid). */
    @Column(name = "is_auto")
    private boolean auto;

    @CreationTimestamp
    private Instant createdAt;
}
