package com.rebook.catalog;

import com.rebook.catalog.CatalogDtos.ListingDetail;
import com.rebook.catalog.CatalogDtos.ListingQuery;
import com.rebook.catalog.CatalogDtos.ListingRequest;
import com.rebook.catalog.CatalogDtos.ListingSummary;
import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.notification.NotificationService;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Shop;
import com.rebook.user.UserService;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ListingService {

    private final ListingRepository listingRepository;
    private final BookService bookService;
    private final CategoryService categoryService;
    private final UserService userService;
    private final SystemConfigService config;
    private final NotificationService notifications;

    // ---- Người mua / khách ----

    @Transactional(readOnly = true)
    public PageResponse<ListingSummary> search(ListingQuery query, int page, int size) {
        Specification<Listing> spec = buildSpec(query, List.of(ListingStatus.ACTIVE), null);
        return PageResponse.of(listingRepository.findAll(spec, pageable(query.sort(), page, size)), ListingSummary::of);
    }

    @Transactional(readOnly = true)
    public ListingDetail publicDetail(Long id, Long viewerId) {
        Listing l = getDetailed(id);
        boolean owner = viewerId != null && l.getShop().getUserId().equals(viewerId);
        // Hết hàng vẫn xem được; tin chưa duyệt / bị ẩn chỉ chủ shop xem
        if (!owner && l.getStatus() != ListingStatus.ACTIVE && l.getStatus() != ListingStatus.OUT_OF_STOCK) {
            throw ApiException.notFound("tin đăng");
        }
        return ListingDetail.of(l);
    }

    public Listing getDetailed(Long id) {
        return listingRepository.findWithDetailsById(id).orElseThrow(() -> ApiException.notFound("tin đăng"));
    }

    // ---- Người bán ----

    @Transactional(readOnly = true)
    public PageResponse<ListingSummary> myListings(Long userId, ListingStatus status, int page, int size) {
        Shop shop = userService.requireShop(userId);
        Specification<Listing> spec = buildSpec(new ListingQuery(null, null, null, null, null, null, shop.getId(), "newest"),
                status == null ? null : List.of(status), null);
        return PageResponse.of(listingRepository.findAll(spec, pageable("newest", page, size)), ListingSummary::of);
    }

    @Transactional
    public ListingDetail create(Long userId, ListingRequest req) {
        Shop shop = userService.requireShop(userId);
        Book book = bookService.create(userId, req.book());
        Listing l = new Listing();
        l.setBook(book);
        l.setShop(shop);
        l.setPrice(req.price());
        l.setStock(req.stock());
        l.setStatus(autoApprove(shop) ? activeOrOut(req.stock()) : ListingStatus.PENDING_REVIEW);
        return ListingDetail.of(listingRepository.save(l));
    }

    @Transactional
    public ListingDetail update(Long userId, Long id, ListingRequest req) {
        Listing l = getOwned(userId, id);
        boolean contentChanged = bookService.update(l.getBook(), req.book());
        l.setPrice(req.price());
        l.setStock(req.stock());
        if (l.getStatus() == ListingStatus.REJECTED || (contentChanged && !autoApprove(l.getShop())
                && l.getStatus() != ListingStatus.PENDING_REVIEW)) {
            l.setStatus(l.getStatus().moveTo(ListingStatus.PENDING_REVIEW));
            l.setRejectReason(null);
        } else {
            syncStockStatus(l);
        }
        return ListingDetail.of(l);
    }

    @Transactional
    public ListingDetail updateStock(Long userId, Long id, int stock) {
        Listing l = getOwned(userId, id);
        l.setStock(stock);
        syncStockStatus(l);
        return ListingDetail.of(l);
    }

    @Transactional
    public ListingDetail hide(Long userId, Long id) {
        Listing l = getOwned(userId, id);
        l.setStatus(l.getStatus().moveTo(ListingStatus.HIDDEN));
        return ListingDetail.of(l);
    }

    /** Hiện lại tin đã ẩn (chỉ tin đã duyệt mới ẩn được, nên không cần duyệt lại). */
    @Transactional
    public ListingDetail show(Long userId, Long id) {
        Listing l = getOwned(userId, id);
        if (l.getStatus() != ListingStatus.HIDDEN) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Tin không ở trạng thái ẩn");
        }
        l.setStatus(activeOrOut(l.getStock()));
        return ListingDetail.of(l);
    }

    // ---- Admin duyệt tin ----

    @Transactional(readOnly = true)
    public PageResponse<ListingSummary> pendingReview(int page, int size) {
        Specification<Listing> spec = buildSpec(new ListingQuery(null, null, null, null, null, null, null, null),
                List.of(ListingStatus.PENDING_REVIEW), null);
        return PageResponse.of(listingRepository.findAll(spec, PageRequest.of(page, size, Sort.by("createdAt"))),
                ListingSummary::of);
    }

    @Transactional
    public ListingDetail approve(Long id) {
        Listing l = getDetailed(id);
        l.setStatus(l.getStatus().moveTo(activeOrOut(l.getStock())));
        l.setRejectReason(null);
        notifications.notify(l.getShop().getUserId(), NotificationService.LISTING, "Tin đăng đã được duyệt",
                "\"" + l.getBook().getTitle() + "\" đã được duyệt và đang bán", Map.of("listingId", l.getId()));
        return ListingDetail.of(l);
    }

    @Transactional
    public ListingDetail reject(Long id, String reason) {
        Listing l = getDetailed(id);
        l.setStatus(l.getStatus().moveTo(ListingStatus.REJECTED));
        l.setRejectReason(reason);
        notifications.notify(l.getShop().getUserId(), NotificationService.LISTING, "Tin đăng bị từ chối",
                "\"" + l.getBook().getTitle() + "\": " + reason, Map.of("listingId", l.getId()));
        return ListingDetail.of(l);
    }

    // ---- Nội bộ ----

    private Listing getOwned(Long userId, Long id) {
        Listing l = getDetailed(id);
        if (!l.getShop().getUserId().equals(userId)) {
            throw ApiException.forbidden("Không phải tin đăng của bạn");
        }
        return l;
    }

    private boolean autoApprove(Shop shop) {
        return shop.isTrusted() && config.bool(SystemConfigService.AUTO_APPROVE_TRUSTED);
    }

    private static ListingStatus activeOrOut(int stock) {
        return stock > 0 ? ListingStatus.ACTIVE : ListingStatus.OUT_OF_STOCK;
    }

    private static void syncStockStatus(Listing l) {
        if (l.getStatus() == ListingStatus.ACTIVE && l.getStock() == 0) {
            l.setStatus(ListingStatus.OUT_OF_STOCK);
        } else if (l.getStatus() == ListingStatus.OUT_OF_STOCK && l.getStock() > 0) {
            l.setStatus(ListingStatus.ACTIVE);
        }
    }

    private Pageable pageable(String sort, int page, int size) {
        Sort s = switch (sort == null ? "newest" : sort) {
            case "price_asc" -> Sort.by("price").ascending();
            case "price_desc" -> Sort.by("price").descending();
            case "best_selling" -> Sort.by("soldCount").descending();
            default -> Sort.by("createdAt").descending();
        };
        return PageRequest.of(page, Math.min(size, 100), s.and(Sort.by("id").descending()));
    }

    private Specification<Listing> buildSpec(ListingQuery q, List<ListingStatus> statuses, Long unused) {
        return (root, cq, cb) -> {
            List<Predicate> ps = new ArrayList<>();
            Join<Listing, Book> book = root.join("book");
            if (statuses != null) {
                ps.add(root.get("status").in(statuses));
            }
            if (q.q() != null && !q.q().isBlank()) {
                String like = "%" + q.q().trim().toLowerCase() + "%";
                ps.add(cb.or(cb.like(cb.lower(book.get("title")), like),
                        cb.like(cb.lower(book.get("author")), like),
                        cb.like(cb.lower(book.get("isbn")), like)));
            }
            if (q.author() != null && !q.author().isBlank()) {
                ps.add(cb.like(cb.lower(book.get("author")), "%" + q.author().trim().toLowerCase() + "%"));
            }
            if (q.categoryId() != null) {
                ps.add(book.get("categoryId").in(categoryService.withDescendants(q.categoryId())));
            }
            if (q.condition() != null) {
                ps.add(cb.equal(book.get("conditionGrade"), q.condition()));
            }
            if (q.minPrice() != null) {
                ps.add(cb.greaterThanOrEqualTo(root.<BigDecimal>get("price"), q.minPrice()));
            }
            if (q.maxPrice() != null) {
                ps.add(cb.lessThanOrEqualTo(root.<BigDecimal>get("price"), q.maxPrice()));
            }
            if (q.shopId() != null) {
                ps.add(cb.equal(root.get("shop").get("id"), q.shopId()));
            }
            return cb.and(ps.toArray(Predicate[]::new));
        };
    }
}
