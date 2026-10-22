package com.rebook.catalog;

import com.rebook.catalog.CatalogDtos.BookRequest;
import com.rebook.common.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;
    private final CategoryService categoryService;

    public Book get(Long id) {
        return bookRepository.findById(id).orElseThrow(() -> ApiException.notFound("sách"));
    }

    @Transactional
    public Book create(Long ownerId, BookRequest req) {
        Book book = new Book();
        book.setOwnerId(ownerId);
        apply(book, req);
        return bookRepository.save(book);
    }

    /** Cập nhật thông tin sách; trả về true nếu nội dung thay đổi (cần duyệt lại). */
    @Transactional
    public boolean update(Book book, BookRequest req) {
        boolean changed = !req.title().trim().equals(book.getTitle())
                || !req.author().trim().equals(book.getAuthor())
                || req.conditionGrade() != book.getConditionGrade()
                || !java.util.Objects.equals(req.description(), book.getDescription())
                || !req.imageUrls().equals(book.getImages().stream()
                .filter(i -> i.getSource() == BookImage.Source.SELLER).map(BookImage::getUrl).toList());
        apply(book, req);
        return changed;
    }

    private void apply(Book book, BookRequest req) {
        categoryService.ensureExists(req.categoryId());
        book.setTitle(req.title().trim());
        book.setAuthor(req.author().trim());
        book.setPublisher(req.publisher());
        book.setPublishYear(req.publishYear());
        book.setIsbn(req.isbn());
        book.setLanguage(req.language() == null || req.language().isBlank() ? "Tiếng Việt" : req.language());
        book.setPages(req.pages());
        book.setCategoryId(req.categoryId());
        book.setConditionGrade(req.conditionGrade());
        book.setDescription(req.description());
        book.setWeightGram(req.weightGram());
        book.replaceSellerImages(req.imageUrls());
    }
}
