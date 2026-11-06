package com.rebook.catalog;

import com.rebook.catalog.CatalogDtos.BookRequest;
import com.rebook.common.ApiException;
import com.rebook.common.Isbn;
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
        apply(book, req, isbnFor(book, req.isbn()));
        return bookRepository.save(book);
    }

    /** Cập nhật thông tin sách; trả về true nếu nội dung thay đổi (cần duyệt lại). */
    @Transactional
    public boolean update(Book book, BookRequest req) {
        String isbn = isbnFor(book, req.isbn());
        // Đổi ISBN / NXB / năm xuất bản là đổi ấn bản → duyệt lại (BR-2.5)
        boolean changed = !java.util.Objects.equals(isbn, book.getIsbn())
                || !java.util.Objects.equals(blankToNull(req.publisher()), blankToNull(book.getPublisher()))
                || !java.util.Objects.equals(req.publishYear(), book.getPublishYear())
                || !req.title().trim().equals(book.getTitle())
                || !req.author().trim().equals(book.getAuthor())
                || req.conditionGrade() != book.getConditionGrade()
                || !java.util.Objects.equals(req.description(), book.getDescription())
                || !req.imageUrls().equals(book.getImages().stream()
                .filter(i -> i.getSource() == BookImage.Source.SELLER).map(BookImage::getUrl).toList());
        apply(book, req, isbn);
        return changed;
    }

    /** ISBN mới thì chuẩn hoá + kiểm số kiểm tra; ISBN giữ nguyên (kể cả dữ liệu cũ sai số kiểm tra) thì không kiểm lại. */
    private static String isbnFor(Book book, String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String old = book.getIsbn();
        String stripped = raw.replaceAll("[\\s-]", "").toUpperCase();
        if (old != null && (stripped.equals(old) || old.equals(Isbn.toIsbn13(stripped)))) {
            return old;
        }
        return Isbn.normalize(raw);
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }

    private void apply(Book book, BookRequest req, String isbn) {
        categoryService.ensureExists(req.categoryId());
        book.setTitle(req.title().trim());
        book.setAuthor(req.author().trim());
        book.setPublisher(req.publisher());
        book.setPublishYear(req.publishYear());
        book.setIsbn(isbn);
        book.setLanguage(req.language() == null || req.language().isBlank() ? "Tiếng Việt" : req.language());
        book.setPages(req.pages());
        book.setCategoryId(req.categoryId());
        book.setConditionGrade(req.conditionGrade());
        book.setDescription(req.description());
        book.setWeightGram(req.weightGram());
        book.replaceSellerImages(req.imageUrls());
    }
}
