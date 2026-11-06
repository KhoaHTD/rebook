package com.rebook.audit;

import jakarta.persistence.Entity;
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

import java.time.Instant;
import java.util.Map;

/** Một sự kiện nghiệp vụ / bảo mật. Chỉ thêm, không sửa, không xoá (xem docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D). */
@Entity
@Table(name = "audit_events")
@Getter
@Setter
@NoArgsConstructor
public class AuditEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreationTimestamp
    private Instant occurredAt;

    private String eventCode;
    private String category;
    private String result;
    private String reasonCode;
    private String actorType;
    private Long actorId;
    private String actorRole;
    private String targetType;
    private String targetId;
    private String refCode;
    private String requestId;
    private String channel;
    private String ip;
    private String summary;

    @JdbcTypeCode(SqlTypes.JSON)
    private Map<String, Object> details;
}
