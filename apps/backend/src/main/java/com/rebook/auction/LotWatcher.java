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

/** Người dùng bấm "Theo dõi" lô để nhận nhắc trước phiên. */
@Entity
@Table(name = "lot_watchers")
@IdClass(LotWatcher.Key.class)
@Getter
@Setter
@NoArgsConstructor
public class LotWatcher {

    public record Key(Long userId, Long lotId) implements Serializable {
        public Key() {
            this(null, null);
        }
    }

    @Id
    private Long userId;

    @Id
    private Long lotId;

    @CreationTimestamp
    private Instant createdAt;

    public LotWatcher(Long userId, Long lotId) {
        this.userId = userId;
        this.lotId = lotId;
    }
}
