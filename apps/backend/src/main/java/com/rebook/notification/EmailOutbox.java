package com.rebook.notification;

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

import java.time.Instant;

/** Một thư chờ gửi: ghi cùng giao dịch với thông báo, {@link EmailOutboxJob} gửi và thử lại. */
@Entity
@Table(name = "email_outbox")
@Getter
@Setter
@NoArgsConstructor
public class EmailOutbox {

    public enum Status { PENDING, SENT, FAILED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long notificationId;
    private Long userId;
    private String toEmail;
    private String subject;
    private String body;

    @Enumerated(EnumType.STRING)
    private Status status = Status.PENDING;

    private int attempts;
    private Instant nextAttemptAt = Instant.now();
    private String lastError;

    @CreationTimestamp
    private Instant createdAt;

    private Instant sentAt;
}
