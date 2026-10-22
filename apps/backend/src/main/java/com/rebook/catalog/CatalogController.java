package com.rebook.catalog;

import com.rebook.catalog.CatalogDtos.CategoryRequest;
import com.rebook.catalog.CatalogDtos.CategoryResponse;
import com.rebook.catalog.CatalogDtos.ListingDetail;
import com.rebook.catalog.CatalogDtos.ListingQuery;
import com.rebook.catalog.CatalogDtos.ListingRequest;
import com.rebook.catalog.CatalogDtos.ListingSummary;
import com.rebook.catalog.CatalogDtos.RejectRequest;
import com.rebook.catalog.CatalogDtos.StockRequest;
import com.rebook.common.PageResponse;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;

@Tag(name = "Catalog")
@RestController
@RequiredArgsConstructor
public class CatalogController {

    private final CategoryService categoryService;
    private final ListingService listingService;

    // ---- Công khai ----

    @Operation(summary = "Cây danh mục thể loại")
    @GetMapping("/categories")
    public List<CategoryResponse> categories() {
        return categoryService.tree();
    }

    @Operation(summary = "Tìm kiếm / lọc sách đang bán",
            description = "sort: newest | price_asc | price_desc | best_selling. category lọc cả danh mục con.")
    @GetMapping("/listings")
    public PageResponse<ListingSummary> search(@RequestParam(required = false) String q,
                                               @RequestParam(required = false) Long category,
                                               @RequestParam(required = false) String author,
                                               @RequestParam(required = false) ConditionGrade condition,
                                               @RequestParam(required = false) BigDecimal minPrice,
                                               @RequestParam(required = false) BigDecimal maxPrice,
                                               @RequestParam(required = false) Long shopId,
                                               @RequestParam(defaultValue = "newest") String sort,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "20") int size) {
        return listingService.search(new ListingQuery(q, category, author, condition, minPrice, maxPrice, shopId, sort),
                page, size);
    }

    @Operation(summary = "Chi tiết sách đang bán")
    @GetMapping("/listings/{id}")
    public ListingDetail detail(@PathVariable Long id, @AuthenticationPrincipal UserPrincipal me) {
        return listingService.publicDetail(id, me == null ? null : me.id());
    }

    // ---- Người bán ----

    @Operation(summary = "Tin đăng của shop tôi")
    @GetMapping("/seller/listings")
    public PageResponse<ListingSummary> myListings(@AuthenticationPrincipal UserPrincipal me,
                                                   @RequestParam(required = false) ListingStatus status,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        return listingService.myListings(me.id(), status, page, size);
    }

    @Operation(summary = "Đăng bán sách giá cố định (tối thiểu 3 ảnh)")
    @PostMapping("/seller/listings")
    @ResponseStatus(HttpStatus.CREATED)
    public ListingDetail create(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ListingRequest req) {
        return listingService.create(me.id(), req);
    }

    @PutMapping("/seller/listings/{id}")
    public ListingDetail update(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                @Valid @RequestBody ListingRequest req) {
        return listingService.update(me.id(), id, req);
    }

    @Operation(summary = "Cập nhật tồn kho")
    @PutMapping("/seller/listings/{id}/stock")
    public ListingDetail updateStock(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                     @Valid @RequestBody StockRequest req) {
        return listingService.updateStock(me.id(), id, req.stock());
    }

    @Operation(summary = "Ẩn tin đăng")
    @DeleteMapping("/seller/listings/{id}")
    public ListingDetail hide(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return listingService.hide(me.id(), id);
    }

    @Operation(summary = "Hiện lại tin đã ẩn")
    @PostMapping("/seller/listings/{id}/show")
    public ListingDetail show(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return listingService.show(me.id(), id);
    }

    // ---- Admin ----

    @Operation(summary = "[Admin] Tin chờ duyệt")
    @GetMapping("/admin/listings/pending")
    public PageResponse<ListingSummary> pending(@RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "20") int size) {
        return listingService.pendingReview(page, size);
    }

    @Operation(summary = "[Admin] Chi tiết tin (mọi trạng thái)")
    @GetMapping("/admin/listings/{id}")
    public ListingDetail adminDetail(@PathVariable Long id) {
        return ListingDetail.of(listingService.getDetailed(id));
    }

    @PostMapping("/admin/listings/{id}/approve")
    public ListingDetail approve(@PathVariable Long id) {
        return listingService.approve(id);
    }

    @PostMapping("/admin/listings/{id}/reject")
    public ListingDetail reject(@PathVariable Long id, @Valid @RequestBody RejectRequest req) {
        return listingService.reject(id, req.reason());
    }

    @PostMapping("/admin/categories")
    @ResponseStatus(HttpStatus.CREATED)
    public CategoryResponse createCategory(@Valid @RequestBody CategoryRequest req) {
        return categoryService.create(req);
    }

    @PutMapping("/admin/categories/{id}")
    public CategoryResponse updateCategory(@PathVariable Long id, @Valid @RequestBody CategoryRequest req) {
        return categoryService.update(id, req);
    }

    @DeleteMapping("/admin/categories/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCategory(@PathVariable Long id) {
        categoryService.delete(id);
    }
}
