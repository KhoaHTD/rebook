package com.rebook.catalog;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Ảnh sách. source = STAFF là ảnh chuẩn do nhân viên chụp khi kiểm định. */
@Entity
@Table(name = "book_images")
@Getter
@Setter
@NoArgsConstructor
public class BookImage {

    public enum Source { SELLER, STAFF }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "book_id")
    private Book book;

    private String url;
    private int sortOrder;

    @Enumerated(EnumType.STRING)
    private Source source;

    public BookImage(Book book, String url, int sortOrder, Source source) {
        this.book = book;
        this.url = url;
        this.sortOrder = sortOrder;
        this.source = source;
    }
}
