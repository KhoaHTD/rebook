package com.rebook.auction;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;

/** Trả giá uỷ quyền: người dùng đặt mức tối đa, hệ thống tự trả hộ từng bước. */
@Entity
@Table(name = "proxy_bids")
@Getter
@Setter
@NoArgsConstructor
public class ProxyBid {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long lotId;
    private Long userId;
    private BigDecimal maxAmount;
    private boolean active = true;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;
}
