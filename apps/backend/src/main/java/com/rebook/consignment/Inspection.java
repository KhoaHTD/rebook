package com.rebook.consignment;

import io.swagger.v3.oas.annotations.media.Schema;
import com.rebook.catalog.ConditionGrade;
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
import java.util.Map;

/** Phiếu kiểm định: checklist, báo cáo tình trạng, đề xuất giá. */
@Entity
@Table(name = "inspections")
@Getter
@Setter
@NoArgsConstructor
public class Inspection {

    @Schema(name = "InspectionResult", enumAsRef = true)
    public enum Result { PASS, FAIL }

    @Schema(name = "SellerDecision", enumAsRef = true)
    public enum SellerDecision { PENDING, ACCEPTED, COUNTER, WITHDRAWN }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long consignmentId;
    private Long inspectorId;

    @Enumerated(EnumType.STRING)
    private Result result;

    /** vd {"fullPages": true, "editionVerified": true, "mold": false, "signature": "chưa xác thực"} */
    @JdbcTypeCode(SqlTypes.JSON)
    private Map<String, Object> checklist;

    @Enumerated(EnumType.STRING)
    private ConditionGrade conditionGrade;

    private String conditionReport;
    private BigDecimal estimateLow;
    private BigDecimal estimateHigh;
    private BigDecimal proposedStart;
    private BigDecimal proposedReserve;

    @Enumerated(EnumType.STRING)
    private SellerDecision sellerDecision = SellerDecision.PENDING;

    private BigDecimal sellerCounterReserve;
    private Instant decidedAt;

    @CreationTimestamp
    private Instant createdAt;
}
