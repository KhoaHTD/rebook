package com.rebook.consignment;

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
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;

/** Sách đang nằm trong kho của sàn (vị trí kệ, nhập / xuất). */
@Entity
@Table(name = "warehouse_items")
@Getter
@Setter
@NoArgsConstructor
public class WarehouseItem {

    public enum Status { IN_STOCK, RESERVED, SHIPPED, RETURNED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long consignmentId;
    private String code;
    private String shelfCode;

    @Enumerated(EnumType.STRING)
    private Status status = Status.IN_STOCK;

    @CreationTimestamp
    private Instant checkedInAt;

    private Instant checkedOutAt;
    /** SHIPPED_TO_WINNER | RETURNED_TO_SELLER */
    private String checkoutReason;
    private Instant returnNotifiedAt;
    private BigDecimal storageFee;

    @UpdateTimestamp
    private Instant updatedAt;
}
