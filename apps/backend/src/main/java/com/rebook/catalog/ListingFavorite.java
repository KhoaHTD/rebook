package com.rebook.catalog;

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

/** Sách (tin bán) người dùng thả tim. */
@Entity
@Table(name = "listing_favorites")
@IdClass(ListingFavorite.Key.class)
@Getter
@Setter
@NoArgsConstructor
public class ListingFavorite {

    public record Key(Long userId, Long listingId) implements Serializable {
        public Key() {
            this(null, null);
        }
    }

    @Id
    private Long userId;

    @Id
    private Long listingId;

    @CreationTimestamp
    private Instant createdAt;

    public ListingFavorite(Long userId, Long listingId) {
        this.userId = userId;
        this.listingId = listingId;
    }
}
