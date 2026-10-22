package com.rebook.catalog;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Thông tin cuốn sách, tách khỏi Listing (bán giá cố định) và Lot (đấu giá)
 * để một cuốn không bán được ở đấu giá có thể chuyển sang bán thường mà không nhập lại.
 */
@Entity
@Table(name = "books")
@Getter
@Setter
@NoArgsConstructor
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long ownerId;
    private String title;
    private String author;
    private String publisher;
    private Integer publishYear;
    private String isbn;
    private String language;
    private Integer pages;
    private Long categoryId;

    @Enumerated(EnumType.STRING)
    private ConditionGrade conditionGrade;

    private String description;
    private int weightGram;

    @OneToMany(mappedBy = "book", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("source DESC, sortOrder ASC")
    private List<BookImage> images = new ArrayList<>();

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    public void replaceSellerImages(List<String> urls) {
        images.removeIf(i -> i.getSource() == BookImage.Source.SELLER);
        for (int i = 0; i < urls.size(); i++) {
            images.add(new BookImage(this, urls.get(i), i, BookImage.Source.SELLER));
        }
    }

    public void addStaffImages(List<String> urls) {
        int base = (int) images.stream().filter(i -> i.getSource() == BookImage.Source.STAFF).count();
        for (int i = 0; i < urls.size(); i++) {
            images.add(new BookImage(this, urls.get(i), base + i, BookImage.Source.STAFF));
        }
    }

    /** Ảnh bìa: ưu tiên ảnh staff chụp khi kiểm định. */
    public String coverUrl() {
        return images.stream()
                .sorted((a, b) -> a.getSource() == b.getSource()
                        ? Integer.compare(a.getSortOrder(), b.getSortOrder())
                        : (a.getSource() == BookImage.Source.STAFF ? -1 : 1))
                .map(BookImage::getUrl).findFirst().orElse(null);
    }
}
