package com.rebook.journey;

import com.jayway.jsonpath.JsonPath;
import com.rebook.auction.AuctionSettlement;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Đợt 2 của bản đánh giá BA / tester (docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần A mục 7, 8, 15, 17, 23). */
class BaReviewBatch2Test extends IntegrationTest {

    @Autowired
    AuctionSettlement settlement;

    private static String code(String prefix) {
        return prefix + UUID.randomUUID().toString().substring(0, 18);
    }

    private long shopOf(long owner) {
        return jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
    }

    private long book(long owner) {
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class,
                "b2-" + UUID.randomUUID());
        return jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, owner, "Sách " + UUID.randomUUID(), category);
    }

    // ---- Mục 7: giá đổi lúc đặt hàng ----

    @Test
    void checkoutIsRejectedWhenTheTotalChangedSinceThePreview() throws Exception {
        long buyer = createUser(Role.USER, "Người mua", 1_000_000);
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = shopOf(owner);
        long address = jdbc.queryForObject("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người Mua', '0900000000', 'Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi') RETURNING id""", Long.class, buyer);
        long listing = jdbc.queryForObject("INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 50000, 2, 'ACTIVE') RETURNING id",
                Long.class, book(owner), shop);
        mvc.perform(post("/cart").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"listingId\":" + listing + ",\"quantity\":1}")).andExpect(status().isOk());
        String preview = mvc.perform(post("/orders/checkout/preview").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"addressId\":" + address + "}")).andReturn().getResponse().getContentAsString();
        long seen = ((Number) JsonPath.read(preview, "$.total")).longValue();

        jdbc.update("UPDATE listings SET price = 500000 WHERE id = ?", listing); // shop đổi giá đúng lúc người mua bấm đặt
        mvc.perform(post("/orders/checkout").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"addressId\":" + address + ",\"paymentMethod\":\"WALLET\",\"expectedTotal\":" + seen + "}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("PRICE_CHANGED"));
        assertThat(walletAvailable(buyer)).as("không bị trừ tiền").isEqualTo(1_000_000);
        assertThat(jdbc.queryForObject("SELECT stock FROM listings WHERE id = ?", Integer.class, listing)).isEqualTo(2);

        jdbc.update("UPDATE listings SET price = 50000 WHERE id = ?", listing);
        mvc.perform(post("/orders/checkout").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"addressId\":" + address + ",\"paymentMethod\":\"WALLET\",\"expectedTotal\":" + seen + "}"))
                .andExpect(status().isCreated());
    }

    // ---- Mục 8: giao thất bại đơn thường ----

    private long[] shippingOrder() {
        long buyer = createUser(Role.USER, "Người mua", 0);
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = shopOf(owner);
        jdbc.update("UPDATE wallets SET held_balance = 120000 WHERE user_id = ?", owner);
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, paid_at, subtotal, shipping_fee, total,
                                    shipped_at)
                VALUES (?, ?, ?, 'NORMAL', 'SHIPPING', 'WALLET', now(), 100000, 20000, 120000, now() - interval '1 day') RETURNING id""",
                Long.class, code("OD-"), buyer, shop);
        return new long[]{order, buyer, owner, createUser(Role.STAFF, "Nhân viên", 0), shop};
    }

    private void carrierFailed(long[] s, String fault) throws Exception {
        mvc.perform(post("/staff/orders/" + s[0] + "/carrier-failed").with(as(s[3], Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Giao thất bại\"" + (fault == null ? "" : ",\"fault\":\"" + fault + "\"") + "}"))
                .andExpect(status().isOk());
    }

    @Test
    void buyerCausedFailedDeliveryRefundsTheBookAndPaysTheShopItsShipping() throws Exception {
        long[] s = shippingOrder();
        carrierFailed(s, "BUYER");
        assertThat(walletAvailable(s[1])).as("hoàn tiền sách, trừ phí giao chiều đi").isEqualTo(100_000);
        assertThat(walletAvailable(s[2])).as("shop nhận phí giao đã trả hãng").isEqualTo(20_000);
        assertThat(walletHeld(s[2])).isZero();
    }

    @Test
    void carrierCausedFailedDeliveryRefundsInFull() throws Exception {
        long[] s = shippingOrder();
        carrierFailed(s, "CARRIER");
        assertThat(walletAvailable(s[1])).isEqualTo(120_000);
        assertThat(walletAvailable(s[2])).isZero();
        assertThat(jdbc.queryForObject("SELECT seller_fault FROM orders WHERE id = ?", Boolean.class, s[0])).isFalse();
    }

    @Test
    void shopCausedFailedDeliveryCountsAgainstTheShop() throws Exception {
        long[] s = shippingOrder();
        carrierFailed(s, "SHOP");
        assertThat(walletAvailable(s[1])).isEqualTo(120_000);
        assertThat(jdbc.queryForObject("SELECT seller_fault FROM orders WHERE id = ?", Boolean.class, s[0])).isTrue();
    }

    // ---- Mục 15 và 23: lô cao giá, cấm luỹ tiến ----

    private record Live(long session, long lot, long bidder, long reg) {
    }

    private Live liveHighValueLot() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long bidder = createUser(Role.USER, "Người trả giá", 10_000_000);
        long b = book(seller);
        long c = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 20000000, 'ACCEPTED') RETURNING id""", Long.class, code("KG-"), seller, b);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status, started_at)
                VALUES ('Phiên lô quý', now() - interval '1 hour', now() - interval '2 hour', 500000, 'LIVE', now()) RETURNING id""", Long.class);
        // Ước tính 15–20 triệu: lô cao giá, cần cọc 500.000 + 10% × 15.000.000 = 2.000.000
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                                  status, opened_at, ends_at, rounds)
                VALUES (?, ?, ?, 1, 5000000, 10000000, 15000000, 20000000, 'OPEN', now(), now() + interval '60 seconds', 1) RETURNING id""",
                Long.class, session, c, b);
        jdbc.update("UPDATE auction_sessions SET current_lot_id = ? WHERE id = ?", lot, session);
        long reg = jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, 1, 500000, 50000000, 'APPROVED') RETURNING id""", Long.class, session, bidder);
        return new Live(session, lot, bidder, reg);
    }

    @Test
    void highValueLotNeedsTheExtraDepositBeforeBidding() throws Exception {
        Live l = liveHighValueLot();
        mvc.perform(post("/lots/" + l.lot() + "/bids").with(as(l.bidder(), Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\":5000000}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("LOT_DEPOSIT_REQUIRED"));
        mvc.perform(MockMvcRequestBuilders.put("/lots/" + l.lot() + "/proxy-bid").with(as(l.bidder(), Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"maxAmount\":12000000}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("LOT_DEPOSIT_REQUIRED"));

        jdbc.update("UPDATE auction_registrations SET deposit_amount = 2000000 WHERE id = ?", l.reg()); // đã cọc thêm
        mvc.perform(post("/lots/" + l.lot() + "/bids").with(as(l.bidder(), Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":5000000}")).andExpect(status().isOk());
    }

    @Test
    void repeatedDefaultsAreBannedLongerEachTime() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long buyer = createUser(Role.USER, "Người hay bỏ", 10_000_000);
        long[] bannedDays = new long[3];
        for (int i = 0; i < 3; i++) {
            jdbc.update("UPDATE users SET auction_banned_until = NULL WHERE id = ?", buyer); // Admin gỡ cấm giữa các lần
            long b = book(seller);
            long c = jdbc.queryForObject("""
                    INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                    VALUES (?, ?, ?, 500000, 'ACCEPTED') RETURNING id""", Long.class, code("KG-"), seller, b);
            long session = jdbc.queryForObject("""
                    INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                    VALUES ('Phiên', now() - interval '1 day', now() - interval '2 day', 50000, 'ENDED') RETURNING id""", Long.class);
            long lot = jdbc.queryForObject("""
                    INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                                      current_price, opened_at, closed_at, status, close_result, hammer_price, winner_id, rounds)
                    VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, 120000, now() - interval '1 day', now() - interval '1 day',
                            'SOLD', 'SOLD', 120000, ?, 1) RETURNING id""", Long.class, session, c, b, buyer);
            long order = jdbc.queryForObject("""
                    INSERT INTO orders (code, buyer_id, lot_id, order_type, status, subtotal, total, payment_due_at, pickup_at_warehouse)
                    VALUES (?, ?, ?, 'AUCTION', 'PENDING_PAYMENT', 120000, 120000, now() - interval '1 hour', TRUE) RETURNING id""",
                    Long.class, code("OD-"), buyer, lot);
            settlement.handleOverdue(order);
            bannedDays[i] = jdbc.queryForObject("SELECT extract(day FROM auction_banned_until - now())::bigint FROM users WHERE id = ?",
                    Long.class, buyer);
        }
        assertThat(bannedDays[0]).isBetween(89L, 90L);
        assertThat(bannedDays[1]).isBetween(364L, 365L);
        assertThat(bannedDays[2]).as("lần 3: vĩnh viễn").isGreaterThan(100_000L);
        assertThat(jdbc.queryForObject("SELECT auction_strikes FROM users WHERE id = ?", Integer.class, buyer)).isEqualTo(3);
    }

    // ---- Mục 17: khoá đăng nhập không bị lợi dụng ----

    @Test
    void failedLoginsFromOneAddressDoNotLockTheOwnerOnAnotherAddress() throws Exception {
        String email = "victim-" + UUID.randomUUID() + "@test.local";
        long user = createUser(Role.USER, "Nạn nhân", 0);
        String hash = new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode("Matkhau123!");
        jdbc.update("UPDATE users SET email = ?, password_hash = ? WHERE id = ?", email, hash, user);
        for (int i = 0; i < 10; i++) {
            mvc.perform(post("/auth/login").with(r -> { r.setRemoteAddr("10.0.0.66"); return r; }).contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"" + email + "\",\"password\":\"saimatkhau\"}"));
        }
        mvc.perform(post("/auth/login").with(r -> { r.setRemoteAddr("10.0.0.66"); return r; }).contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"Matkhau123!\"}")).andExpect(status().isTooManyRequests());
        mvc.perform(post("/auth/login").with(r -> { r.setRemoteAddr("10.0.0.7"); return r; }).contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"Matkhau123!\"}")).andExpect(status().isOk());
    }
}
