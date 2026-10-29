package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Mua nhiều cuốn của nhiều shop trong cùng một giỏ, và chỉ thanh toán những cuốn được chọn. */
class MultiShopCheckoutTest extends IntegrationTest {

    private long buyerId;
    private long addressId;
    private long listingA; // shop 1, còn 5 cuốn
    private long listingB; // shop 2, còn 3 cuốn
    private long listingC; // shop 2, còn 1 cuốn

    @BeforeEach
    void setUp() {
        buyerId = createUser(Role.USER, "Người Mua", 0);
        addressId = jdbc.queryForObject("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người Mua', '0900000000', 'Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi') RETURNING id""",
                Long.class, buyerId);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "test-" + UUID.randomUUID());
        long shop1 = createShop("Hồ Chí Minh");
        long shop2 = createShop("Hà Nội");
        listingA = createListing(category, shop1, 45_000, 5);
        listingB = createListing(category, shop2, 60_000, 3);
        listingC = createListing(category, shop2, 30_000, 1);
    }

    private long createShop(String province) {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        return jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', ?, 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID(), province);
    }

    private long createListing(long category, long shop, long price, int stock) {
        long owner = jdbc.queryForObject("SELECT user_id FROM shops WHERE id = ?", Long.class, shop);
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, owner, "Sách " + UUID.randomUUID(), category);
        return jdbc.queryForObject("""
                INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, ?, ?, 'ACTIVE') RETURNING id""",
                Long.class, book, shop, price, stock);
    }

    private void addToCart(long listing, int qty) throws Exception {
        mvc.perform(post("/cart").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"listingId\":" + listing + ",\"quantity\":" + qty + "}")).andExpect(status().isOk());
    }

    private int stock(long listing) {
        return jdbc.queryForObject("SELECT stock FROM listings WHERE id = ?", Integer.class, listing);
    }

    private String checkoutJson(String listingIds) {
        return "{\"addressId\":" + addressId + ",\"paymentMethod\":\"COD\"" + (listingIds == null ? "" : ",\"listingIds\":" + listingIds) + "}";
    }

    @Test
    void cartGroupsBooksByShopWithQuantities() throws Exception {
        addToCart(listingA, 2);
        addToCart(listingB, 1);

        mvc.perform(get("/cart").with(as(buyerId, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.shops.length()").value(2))
                .andExpect(jsonPath("$.totalQuantity").value(3))
                .andExpect(jsonPath("$.shops[0].items[0].quantity").value(1))
                .andExpect(jsonPath("$.shops[0].items[0].stock").value(3))
                .andExpect(jsonPath("$.shops[1].items[0].quantity").value(2))
                .andExpect(jsonPath("$.shops[1].items[0].stock").value(5));
    }

    @Test
    void cannotAddMoreThanStock() throws Exception {
        mvc.perform(post("/cart").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"listingId\":" + listingC + ",\"quantity\":2}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("OUT_OF_STOCK"));
        addToCart(listingC, 1);
        mvc.perform(put("/cart/" + listingC).with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\":2}"))
                .andExpect(status().isConflict());
    }

    @Test
    void wholeCartBecomesOneOrderPerShop() throws Exception {
        addToCart(listingA, 2);
        addToCart(listingB, 1);

        mvc.perform(post("/orders/checkout").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content(checkoutJson(null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.orders.length()").value(2));

        assertThat(stock(listingA)).isEqualTo(3);
        assertThat(stock(listingB)).isEqualTo(2);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM cart_items WHERE user_id = ?", Long.class, buyerId)).isZero();
    }

    @Test
    void onlySelectedBooksAreOrderedAndTheRestStayInCart() throws Exception {
        addToCart(listingA, 2);
        addToCart(listingB, 1);
        addToCart(listingC, 1);

        mvc.perform(post("/orders/checkout").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content(checkoutJson("[" + listingB + "," + listingC + "]")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.orders.length()").value(1)); // B và C cùng shop 2 → một đơn

        assertThat(stock(listingA)).isEqualTo(5);
        assertThat(stock(listingB)).isEqualTo(2);
        assertThat(stock(listingC)).isZero();
        assertThat(jdbc.queryForList("SELECT listing_id FROM cart_items WHERE user_id = ?", Long.class, buyerId))
                .containsExactly(listingA);
        assertThat(jdbc.queryForObject("""
                SELECT sum(oi.quantity) FROM order_items oi JOIN orders o ON o.id = oi.order_id
                WHERE o.buyer_id = ?""", Long.class, buyerId)).isEqualTo(2);
    }

    @Test
    void previewOfSelectedBooksOnlyQuotesThoseShops() throws Exception {
        addToCart(listingA, 2);
        addToCart(listingB, 1);

        mvc.perform(post("/orders/checkout/preview").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"addressId\":" + addressId + ",\"listingIds\":[" + listingA + "]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.shops.length()").value(1))
                .andExpect(jsonPath("$.subtotal").value(90000));
    }
}
