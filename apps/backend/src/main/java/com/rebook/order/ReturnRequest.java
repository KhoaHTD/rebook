package com.rebook.order;

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
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Yêu cầu trả hàng — chỉ khi sách khác mô tả, không nhận trả vì "đổi ý".
 * PENDING → APPROVED (shop đồng ý) | DISPUTED (shop từ chối, chờ Admin) → APPROVED | REJECTED.
 */
@Entity
@Table(name = "return_requests")
@Getter
@Setter
@NoArgsConstructor
public class ReturnRequest {

    @Schema(name = "ReturnReason", enumAsRef = true)
    /** NOT_RECEIVED: đơn bị coi là đã giao mà người mua không nhận được sách; không có hàng để gửi trả. */
    public enum Reason { WRONG_CONDITION, MISSING_PAGES, WRONG_EDITION, OTHER_NOT_AS_DESCRIBED, NOT_RECEIVED }

    @Schema(name = "ReturnStatus", enumAsRef = true)
    public enum Status { PENDING, APPROVED, DISPUTED, REJECTED, AWAITING_GOODS, EXPIRED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long orderId;

    @Enumerated(EnumType.STRING)
    private Reason reason;

    private String description;

    @JdbcTypeCode(SqlTypes.JSON)
    private List<String> images = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    private Status status = Status.PENDING;

    private String sellerNote;
    private String resolution;
    private Long resolvedBy;
    private Instant resolvedAt;

    /** Được đồng ý trả (AWAITING_GOODS) lúc nào; người mua gửi trả kèm mã vận đơn; shop / kho xác nhận đã nhận. */
    private Instant approvedAt;
    private String returnTrackingCode;
    private Instant returnShippedAt;
    private Instant returnReceivedAt;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;
}
