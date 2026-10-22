package com.rebook.catalog;

import com.rebook.catalog.CatalogDtos.CategoryRequest;
import com.rebook.catalog.CatalogDtos.CategoryResponse;
import com.rebook.common.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository repository;

    /** Trả về cây danh mục. */
    public List<CategoryResponse> tree() {
        List<Category> all = repository.findAllByOrderBySortOrderAscNameAsc();
        Map<Long, List<Category>> byParent = all.stream()
                .filter(c -> c.getParentId() != null)
                .collect(Collectors.groupingBy(Category::getParentId));
        return all.stream().filter(c -> c.getParentId() == null).map(c -> toTree(c, byParent)).toList();
    }

    private CategoryResponse toTree(Category c, Map<Long, List<Category>> byParent) {
        List<CategoryResponse> children = byParent.getOrDefault(c.getId(), List.of()).stream()
                .map(x -> toTree(x, byParent)).toList();
        return new CategoryResponse(c.getId(), c.getName(), c.getSlug(), c.getParentId(), c.getSortOrder(), children);
    }

    /** id của danh mục và mọi danh mục con (để lọc theo danh mục cha). */
    public Set<Long> withDescendants(Long id) {
        Set<Long> result = new HashSet<>();
        List<Long> queue = new ArrayList<>(List.of(id));
        while (!queue.isEmpty()) {
            Long current = queue.removeFirst();
            if (result.add(current)) {
                repository.findByParentId(current).forEach(c -> queue.add(c.getId()));
            }
        }
        return result;
    }

    public void ensureExists(Long id) {
        if (!repository.existsById(id)) {
            throw ApiException.badRequest("INVALID_CATEGORY", "Danh mục không tồn tại");
        }
    }

    @Transactional
    public CategoryResponse create(CategoryRequest req) {
        if (repository.existsBySlug(req.slug())) {
            throw ApiException.conflict("SLUG_TAKEN", "Slug đã tồn tại");
        }
        Category c = new Category();
        apply(c, req);
        c = repository.save(c);
        return new CategoryResponse(c.getId(), c.getName(), c.getSlug(), c.getParentId(), c.getSortOrder(), List.of());
    }

    @Transactional
    public CategoryResponse update(Long id, CategoryRequest req) {
        Category c = repository.findById(id).orElseThrow(() -> ApiException.notFound("danh mục"));
        if (!c.getSlug().equals(req.slug()) && repository.existsBySlug(req.slug())) {
            throw ApiException.conflict("SLUG_TAKEN", "Slug đã tồn tại");
        }
        if (req.parentId() != null && withDescendants(id).contains(req.parentId())) {
            throw ApiException.badRequest("INVALID_PARENT", "Không thể chọn danh mục con làm cha");
        }
        apply(c, req);
        return new CategoryResponse(c.getId(), c.getName(), c.getSlug(), c.getParentId(), c.getSortOrder(), List.of());
    }

    @Transactional
    public void delete(Long id) {
        if (!repository.findByParentId(id).isEmpty()) {
            throw ApiException.conflict("HAS_CHILDREN", "Hãy xoá danh mục con trước");
        }
        repository.deleteById(id); // còn sách tham chiếu → DataIntegrityViolation → 409
        repository.flush();
    }

    private void apply(Category c, CategoryRequest req) {
        if (req.parentId() != null) {
            ensureExists(req.parentId());
        }
        c.setName(req.name().trim());
        c.setSlug(req.slug().trim());
        c.setParentId(req.parentId());
        c.setSortOrder(req.sortOrder());
    }
}
