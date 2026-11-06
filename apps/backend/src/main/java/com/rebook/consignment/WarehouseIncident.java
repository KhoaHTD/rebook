package com.rebook.consignment;

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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** Sự cố kho: mất / hỏng sách ký gửi. Staff khai báo, Admin duyệt rồi mới chi bồi thường (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần C 4.2). */
@Entity
@Table(name = "warehouse_incidents")
@Getter
@Setter
@NoArgsConstructor
public class WarehouseIncident {

    @Schema(name = "IncidentType", enumAsRef = true)
    public enum Type { LOST, DAMAGED }

    @Schema(name = "IncidentStatus", enumAsRef = true)
    public enum Status { PENDING, APPROVED, REJECTED }

    /** Giai đoạn lúc duyệt, quyết định mức bồi thường. */
    @Schema(name = "IncidentStage", enumAsRef = true)
    public enum Stage { UNINSPECTED, INSPECTED, SOLD_PAID }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long warehouseItemId;
    private Long consignmentId;

    @Enumerated(EnumType.STRING)
    private Type type;

    private String description;

    @JdbcTypeCode(SqlTypes.JSON)
    private List<String> images = new ArrayList<>();

    private Long reportedBy;

    @Enumerated(EnumType.STRING)
    private Status status = Status.PENDING;

    @Enumerated(EnumType.STRING)
    private Stage stage;

    private BigDecimal baseAmount;
    private Integer sellerPercent;
    private BigDecimal sellerAmount;
    private Long buyerId;
    private BigDecimal buyerAmount;
    private Long orderId;
    private Long decidedBy;
    private Instant decidedAt;
    private String decisionNote;

    @CreationTimestamp
    private Instant createdAt;
}
