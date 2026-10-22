package com.rebook.catalog;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class CatalogDtos {

    private CatalogDtos() {
    }

    // ---- Category ----

    public record CategoryResponse(Long id, String name, String slug, Long parentId, int sortOrder,
                                   List<CategoryResponse> children) {
    }

    public record CategoryRequest(@NotBlank @Size(max = 100) String name,
                                  @NotBlank @Size(max = 120) String slug,
                                  Long parentId,
                                  int sortOrder) {
    }

    // ---- Book ----

    /** Thông tin sách dùng chung cho đăng bán và yêu cầu ký gửi. */
    public record BookRequest(
            @NotBlank @Size(max = 300) String title,
            @NotBlank @Size(max = 200) String author,
            @Size(max = 200) String publisher,
            @Min(1500) @Max(2100) Integer publishYear,
            @Size(max = 20) String isbn,
            @Size(max = 50) String language,
            @Min(1) Integer pages,
            @NotNull Long categoryId,
            @NotNull ConditionGrade conditionGrade,
            @Size(max = 5000) String description,
            @NotNull @Min(1) Integer weightGram,
            @NotNull @Size(min = 3, max = 10, message = "Cần từ 3 đến 10 ảnh thật") List<@NotBlank String> imageUrls) {
    }

    public record ImageResponse(String url, BookImage.Source source) {
    }

    public record BookResponse(Long id, String title, String author, String publisher, Integer publishYear,
                               String isbn, String language, Integer pages, Long categoryId,
                               ConditionGrade conditionGrade, String description, int weightGram,
                               String coverUrl, List<ImageResponse> images) {

        public static BookResponse of(Book b) {
            return new BookResponse(b.getId(), b.getTitle(), b.getAuthor(), b.getPublisher(), b.getPublishYear(),
                    b.getIsbn(), b.getLanguage(), b.getPages(), b.getCategoryId(), b.getConditionGrade(),
                    b.getDescription(), b.getWeightGram(), b.coverUrl(),
                    b.getImages().stream().map(i -> new ImageResponse(i.getUrl(), i.getSource())).toList());
        }
    }

    // ---- Listing ----

    public record ListingRequest(
            @NotNull @Valid BookRequest book,
            @NotNull @DecimalMin(value = "1000", message = "Giá tối thiểu 1.000đ") BigDecimal price,
            @NotNull @Min(0) Integer stock) {
    }

    public record StockRequest(@NotNull @Min(0) Integer stock) {
    }

    public record RejectRequest(@NotBlank @Size(max = 500) String reason) {
    }

    public record ShopBrief(Long id, String name, String pickupProvince, BigDecimal ratingAvg, int ratingCount) {
    }

    public record ListingSummary(Long id, String title, String author, String coverUrl, ConditionGrade conditionGrade,
                                 BigDecimal price, int stock, int soldCount, ListingStatus status, ShopBrief shop,
                                 Instant createdAt) {

        public static ListingSummary of(Listing l) {
            Book b = l.getBook();
            var s = l.getShop();
            return new ListingSummary(l.getId(), b.getTitle(), b.getAuthor(), b.coverUrl(), b.getConditionGrade(),
                    l.getPrice(), l.getStock(), l.getSoldCount(), l.getStatus(),
                    new ShopBrief(s.getId(), s.getName(), s.getPickupProvince(), s.getRatingAvg(), s.getRatingCount()),
                    l.getCreatedAt());
        }
    }

    public record ListingDetail(Long id, BigDecimal price, int stock, int soldCount, ListingStatus status,
                                String rejectReason, BookResponse book, ShopBrief shop, Instant createdAt,
                                Instant updatedAt) {

        public static ListingDetail of(Listing l) {
            var s = l.getShop();
            return new ListingDetail(l.getId(), l.getPrice(), l.getStock(), l.getSoldCount(), l.getStatus(),
                    l.getRejectReason(), BookResponse.of(l.getBook()),
                    new ShopBrief(s.getId(), s.getName(), s.getPickupProvince(), s.getRatingAvg(), s.getRatingCount()),
                    l.getCreatedAt(), l.getUpdatedAt());
        }
    }

    /** Tham số tìm kiếm / lọc / sắp xếp. sort: newest | price_asc | price_desc | best_selling */
    public record ListingQuery(String q, Long categoryId, String author, ConditionGrade condition,
                               BigDecimal minPrice, BigDecimal maxPrice, Long shopId, String sort) {
    }
}
