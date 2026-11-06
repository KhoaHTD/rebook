package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Hạn xử lý của shop, điểm uy tín, dọn việc dở khi khoá tài khoản, mã lỗi riêng, chặn duyệt tin khi sách còn trong kho. */
class ShopSlaAndLockTest extends IntegrationTest {

    @Autowired
    OrderJobs jobs;

    private record Shop(long owner, long id) {
    }

    private Shop shop(boolean trusted) {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long id = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder, trusted)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X', ?) RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID(), trusted);
        return new Shop(owner, id);
    }

    private long order(long buyer, long shop, String status, String method, String paidAt, String extraSql) {
        return jdbc.queryForObject("INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, paid_at, subtotal, "
                        + "shipping_fee, total" + (extraSql.isEmpty() ? "" : ", " + extraSql.split("=")[0]) + ") VALUES (?, ?, ?, 'NORMAL', ?, ?, " + paidAt
                        + ", 100000, 20000, 120000" + (extraSql.isEmpty() ? "" : ", " + extraSql.split("=")[1]) + ") RETURNING id",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer, shop, status, method);
    }

    private String orderStatus(long id) {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, id);
    }

    private boolean fault(long id) {
        return jdbc.queryForObject("SELECT seller_fault FROM orders WHERE id = ?", Boolean.class, id);
    }

    private boolean trusted(long shopId) {
        return jdbc.queryForObject("SELECT trusted FROM shops WHERE id = ?", Boolean.class, shopId);
    }

    // ---- Hạn giao hàng, hạn trả lời yêu cầu huỷ ----

    @Test
    void shopThatDoesNotShipInTimeIsCancelledAndTheBuyerIsRefunded() {
        Shop s = shop(false);
        long buyer = createUser(Role.USER, "Người mua", 0);
        jdbc.update("UPDATE wallets SET held_balance = 120000 WHERE user_id = ?", s.owner());
        long late = order(buyer, s.id(), "PREPARING", "WALLET", "now()", "ship_due_at=now() - interval '1 day'");
        long onTime = order(buyer, s.id(), "PREPARING", "COD", "NULL", "ship_due_at=now() + interval '2 days'");

        jobs.run();

        assertThat(orderStatus(late)).isEqualTo("CANCELLED");
        assertThat(walletAvailable(buyer)).isEqualTo(120_000);
        assertThat(jdbc.queryForObject("SELECT held_balance FROM wallets WHERE user_id = ?", Long.class, s.owner())).isZero();
        assertThat(fault(late)).isTrue();
        assertThat(orderStatus(onTime)).isEqualTo("PREPARING");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'ORDER.AUTO_CANCELLED' AND target_id = ?",
                Long.class, String.valueOf(late))).isEqualTo(1);
    }

    @Test
    void cancelRequestIsApprovedWhenTheShopStaysSilent() {
        Shop s = shop(false);
        long buyer = createUser(Role.USER, "Người mua", 0);
        long silent = order(buyer, s.id(), "PREPARING", "COD", "NULL", "cancel_requested_at=now() - interval '25 hours'");
        jdbc.update("UPDATE orders SET cancel_requested = TRUE WHERE id = ?", silent);
        long fresh = order(buyer, s.id(), "PREPARING", "COD", "NULL", "cancel_requested_at=now() - interval '1 hour'");
        jdbc.update("UPDATE orders SET cancel_requested = TRUE WHERE id = ?", fresh);

        jobs.run();

        assertThat(orderStatus(silent)).isEqualTo("CANCELLED");
        assertThat(fault(silent)).isFalse(); // người mua tự xin huỷ, không phải lỗi của shop
        assertThat(orderStatus(fresh)).isEqualTo("PREPARING");
    }

    // ---- Điểm uy tín ----

    @Test
    void trustedShopLosesTrustWhenTheFaultRateReachesTheThreshold() {
        Shop busy = shop(true);   // 10 đơn, 1 lỗi = 10%
        Shop small = shop(true);  // chỉ 4 đơn: chưa đủ số đơn tối thiểu để xét
        Shop clean = shop(true);  // 20 đơn, 1 lỗi = 5%
        long buyer = createUser(Role.USER, "Người mua", 0);
        for (int i = 0; i < 9; i++) {
            order(buyer, busy.id(), "COMPLETED", "COD", "NULL", "");
        }
        for (int i = 0; i < 3; i++) {
            order(buyer, small.id(), "COMPLETED", "COD", "NULL", "");
        }
        for (int i = 0; i < 19; i++) {
            order(buyer, clean.id(), "COMPLETED", "COD", "NULL", "");
        }
        order(buyer, busy.id(), "PREPARING", "COD", "NULL", "ship_due_at=now() - interval '1 day'");
        order(buyer, small.id(), "PREPARING", "COD", "NULL", "ship_due_at=now() - interval '1 day'");
        order(buyer, clean.id(), "PREPARING", "COD", "NULL", "ship_due_at=now() - interval '1 day'");

        jobs.run();

        assertThat(trusted(busy.id())).isFalse();
        assertThat(trusted(small.id())).isTrue();
        assertThat(trusted(clean.id())).isTrue();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'SHOP.TRUST.REVOKED' AND target_id = ?",
                Long.class, String.valueOf(busy.id()))).isEqualTo(1);
    }

    // ---- Khoá tài khoản ----

    private long listing(Shop s, String status) {
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "sl-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, s.owner(), "Sách " + UUID.randomUUID(), category);
        return jdbc.queryForObject("INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 50000, 3, ?) RETURNING id",
                Long.class, book, s.id(), status);
    }

    @Test
    void lockingASellerHidesListingsAndCancelsOrdersNotYetHandedToTheCarrier() throws Exception {
        Shop s = shop(false);
        long admin = createUser(Role.ADMIN, "Admin khoá", 0);
        long buyer = createUser(Role.USER, "Người mua", 0);
        long live = listing(s, "ACTIVE");
        long pending = listing(s, "PENDING_REVIEW");
        jdbc.update("UPDATE wallets SET held_balance = 240000 WHERE user_id = ?", s.owner());
        long waiting = order(buyer, s.id(), "PENDING_CONFIRM", "WALLET", "now()", "");
        long shipping = order(buyer, s.id(), "SHIPPING", "COD", "NULL", "");

        mvc.perform(post("/admin/users/" + s.owner() + "/lock").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Bán hàng giả\"}")).andExpect(status().isOk());

        assertThat(jdbc.queryForObject("SELECT status FROM listings WHERE id = ?", String.class, live)).isEqualTo("HIDDEN");
        assertThat(jdbc.queryForObject("SELECT status FROM listings WHERE id = ?", String.class, pending)).isEqualTo("PENDING_REVIEW");
        assertThat(orderStatus(waiting)).isEqualTo("CANCELLED");
        assertThat(walletAvailable(buyer)).isEqualTo(120_000);
        assertThat(fault(waiting)).isFalse(); // do hệ thống huỷ, không tính lỗi shop
        assertThat(orderStatus(shipping)).isEqualTo("SHIPPING"); // đã giao cho vận chuyển thì giữ nguyên
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'ACCOUNT.LOCK.CLEANUP' AND target_id = ?",
                Long.class, String.valueOf(s.owner()))).isEqualTo(1);
    }

    @Test
    void lockingABuyerCancelsUnpaidOrdersAndRefundsDepositsOfOpenSessions() throws Exception {
        Shop s = shop(false);
        long admin = createUser(Role.ADMIN, "Admin khoá", 0);
        long buyer = createUser(Role.USER, "Người mua bị khoá", 0);
        long unpaid = order(buyer, s.id(), "PENDING_PAYMENT", "ZALOPAY", "NULL", "");
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên mở', now() + interval '2 days', now() + interval '1 day', 50000, 'PUBLISHED') RETURNING id""", Long.class);
        jdbc.update("UPDATE wallets SET held_balance = 50000 WHERE user_id = ?", buyer);
        long reg = jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, 1, 50000, 500000, 'APPROVED') RETURNING id""", Long.class, session, buyer);

        mvc.perform(post("/admin/users/" + buyer + "/lock").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Gian lận\"}")).andExpect(status().isOk());

        assertThat(orderStatus(unpaid)).isEqualTo("CANCELLED");
        assertThat(jdbc.queryForObject("SELECT status FROM auction_registrations WHERE id = ?", String.class, reg)).isEqualTo("CANCELLED");
        assertThat(walletAvailable(buyer)).isEqualTo(50_000);
    }

    // ---- Mã lỗi riêng ----

    @Test
    void bannedUserGetsADedicatedErrorCode() throws Exception {
        long me = createUser(Role.USER, "Người bị cấm", 0);
        jdbc.update("UPDATE users SET phone_verified = TRUE, auction_banned_until = now() + interval '30 days' WHERE id = ?", me);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên mở', now() + interval '2 days', now() + interval '1 day', 50000, 'PUBLISHED') RETURNING id""", Long.class);

        mvc.perform(post("/sessions/" + session + "/register").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"agreeRules\":true}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("AUCTION_BANNED"));
    }

    // ---- Tin chuyển từ lô không bán ----

    @Test
    void listingOfABookStillInTheWarehouseCannotBeApprovedUntilTheSellerTookItBack() throws Exception {
        Shop s = shop(false);
        long admin = createUser(Role.ADMIN, "Admin duyệt", 0);
        long listing = listing(s, "PENDING_REVIEW");
        long book = jdbc.queryForObject("SELECT book_id FROM listings WHERE id = ?", Long.class, listing);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, "KG-" + UUID.randomUUID().toString().substring(0, 18), s.owner(), book);
        long warehouse = jdbc.queryForObject("INSERT INTO warehouse_items (consignment_id, code) VALUES (?, ?) RETURNING id", Long.class,
                consignment, "WH" + UUID.randomUUID().toString().substring(0, 12));

        mvc.perform(post("/admin/listings/" + listing + "/approve").with(as(admin, Role.ADMIN)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("BOOK_IN_WAREHOUSE"));

        jdbc.update("UPDATE warehouse_items SET status = 'RETURNED' WHERE id = ?", warehouse);
        mvc.perform(post("/admin/listings/" + listing + "/approve").with(as(admin, Role.ADMIN))).andExpect(status().isOk());
    }
}
