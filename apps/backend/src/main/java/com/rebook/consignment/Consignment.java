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

/** Yêu cầu ký gửi + lịch hẹn mang sách tới kho. */
@Entity
@Table(name = "consignments")
@Getter
@Setter
@NoArgsConstructor
public class Consignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String code;
    private Long sellerId;
    private Long bookId;
    private BigDecimal expectedPrice;
    /** Câu chuyện / nguồn gốc, vd "bản in lần đầu 1965, có chữ ký tác giả". */
    private String provenance;

    @Enumerated(EnumType.STRING)
    private ConsignmentStatus status = ConsignmentStatus.SUBMITTED;

    private String reviewNote;
    private Instant appointmentAt;
    /** Mã in trên QR của lịch hẹn, Staff quét khi nhận sách. */
    private String appointmentCode;
    private Instant approvedAt;
    private Instant receivedAt;
    private Long receivedBy;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;
}
