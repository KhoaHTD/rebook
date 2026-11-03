package com.rebook.auction;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.time.Instant;

/** Người dùng theo dõi cả phiên (phiên yêu thích), khác với theo dõi từng lô. */
@Entity
@Table(name = "session_watchers")
@IdClass(SessionWatcher.Key.class)
@Getter
@Setter
@NoArgsConstructor
public class SessionWatcher {

    public record Key(Long userId, Long sessionId) implements Serializable {
        public Key() {
            this(null, null);
        }
    }

    @Id
    private Long userId;

    @Id
    private Long sessionId;

    @CreationTimestamp
    private Instant createdAt;

    public SessionWatcher(Long userId, Long sessionId) {
        this.userId = userId;
        this.sessionId = sessionId;
    }
}
