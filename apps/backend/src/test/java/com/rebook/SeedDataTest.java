package com.rebook;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/** Dữ liệu mẫu của profile dev (migration + seed) chạy được từ đầu và đủ tồn kho để thử mua nhiều cuốn / nhiều shop. */
@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:postgresql://localhost:5432/rebook_dev?currentSchema=rebook_seedtest,public",
        "spring.flyway.schemas=rebook_seedtest",
        "spring.flyway.default-schema=rebook_seedtest",
        "spring.flyway.locations=classpath:db/migration,classpath:db/seed",
        "spring.flyway.clean-disabled=false"
})
class SeedDataTest {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void activeListingsOfBothShopsHaveEnoughStockToBuyMoreThanOne() {
        Integer shop1 = jdbc.queryForObject("SELECT max(stock) FROM listings WHERE shop_id = 1 AND status = 'ACTIVE'", Integer.class);
        Integer shop2 = jdbc.queryForObject("SELECT max(stock) FROM listings WHERE shop_id = 2 AND status = 'ACTIVE'", Integer.class);
        assertThat(shop1).isGreaterThanOrEqualTo(3);
        assertThat(shop2).isGreaterThanOrEqualTo(3);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM listings WHERE status = 'ACTIVE' AND stock >= 3", Long.class))
                .isGreaterThanOrEqualTo(8);
    }

    /** Thể loại chia hai cấp (nhóm cha → thể loại con) và có đủ các thể loại sách phổ biến. */
    @Test
    void categoriesAreAFullTwoLevelTree() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM categories WHERE parent_id IS NULL", Long.class))
                .isGreaterThanOrEqualTo(10);
        // Văn học và Giáo trình có thể loại con; không có cấp thứ ba.
        assertThat(jdbc.queryForObject("SELECT count(*) FROM categories c WHERE c.parent_id = (SELECT id FROM categories WHERE slug = 'van-hoc')", Long.class))
                .isGreaterThanOrEqualTo(6);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM categories c WHERE c.parent_id = (SELECT id FROM categories WHERE slug = 'giao-trinh')", Long.class))
                .isGreaterThanOrEqualTo(6);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM categories c JOIN categories p ON p.id = c.parent_id WHERE p.parent_id IS NOT NULL", Long.class))
                .isZero();
    }

    /** 70 sách từ file Excel thành tin đăng bán giá cố định, mỗi sách một ảnh bìa Cloudinary; không còn dữ liệu nghiệp vụ cũ. */
    @Test
    void booksFromTheSheetAreLoadedAndOldBusinessDataIsGone() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM books", Long.class)).isEqualTo(70);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM listings WHERE status = 'ACTIVE'", Long.class)).isEqualTo(70);
        // Mỗi sách có đúng một ảnh bìa trên Cloudinary (URL https), không có ảnh lưu cục bộ.
        assertThat(jdbc.queryForObject("SELECT count(*) FROM book_images WHERE url LIKE 'https://res.cloudinary.com/%'", Long.class)).isEqualTo(70);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM book_images", Long.class)).isEqualTo(70);
        for (String t : new String[]{"orders", "consignments", "lots", "auction_sessions", "cart_items", "notifications"}) {
            assertThat(jdbc.queryForObject("SELECT count(*) FROM " + t, Long.class)).as(t).isZero();
        }
        // Tài khoản và hai shop vẫn còn.
        assertThat(jdbc.queryForObject("SELECT count(*) FROM users", Long.class)).isEqualTo(7);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM shops", Long.class)).isEqualTo(2);
    }

    /** ISBN đúng chữ số kiểm tra, không trùng; mỗi sách thuộc thể loại con (hoặc thể loại cha không có con). */
    @Test
    void isbnsAreValidAndCategoriesAreLeaves() {
        assertThat(jdbc.queryForObject("SELECT count(DISTINCT isbn) FROM books", Long.class)).isEqualTo(70);
        for (String isbn : jdbc.queryForList("SELECT isbn FROM books", String.class)) {
            assertThat(com.rebook.common.Isbn.normalize(isbn)).isEqualTo(isbn);
        }
        assertThat(jdbc.queryForObject("SELECT count(*) FROM books b WHERE EXISTS (SELECT 1 FROM categories c WHERE c.parent_id = b.category_id)", Long.class))
                .isZero();
    }

    /** Ví về số dư mẫu và sổ cái khớp số dư. */
    @Test
    void walletsMatchTheirLedger() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM wallets w WHERE w.available_balance <> COALESCE((SELECT sum(available_change) FROM wallet_transactions t WHERE t.wallet_id = w.id), 0) OR w.held_balance <> COALESCE((SELECT sum(held_change) FROM wallet_transactions t WHERE t.wallet_id = w.id), 0)", Long.class))
                .isZero();
        assertThat(jdbc.queryForObject("SELECT sum(available_balance) FROM wallets", Long.class)).isEqualTo(13000000L);
    }
}
