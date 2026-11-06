package com.rebook.journey;

import com.rebook.consignment.ConsignmentJobs;
import com.rebook.order.OrderJobs;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Các lỗ hổng thuần backend trong docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần A (mục 10, 11, 12, 13, 27). */
class BaReviewGapsTest extends IntegrationTest {

    @Autowired
    ConsignmentJobs consignmentJobs;
    @Autowired
    OrderJobs orderJobs;

    private static String code(String prefix) {
        return prefix + UUID.randomUUID().toString().substring(0, 18);
    }

    private long consignment(long seller, String status) {
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class,
                "ba-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, seller, "Sách " + UUID.randomUUID(), category);
        return jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 500000, ?) RETURNING id""", Long.class, code("KG-"), seller, book, status);
    }

    private long warehouseItem(long consignment, String returnNotifiedAgo) {
        return jdbc.queryForObject("INSERT INTO warehouse_items (consignment_id, code, return_notified_at) VALUES (?, ?, "
                + (returnNotifiedAgo == null ? "NULL" : "now() - interval '" + returnNotifiedAgo + "'") + ") RETURNING id",
                Long.class, consignment, code("WH"));
    }

    private String one(String sql, long id) {
        return jdbc.queryForObject(sql, String.class, id);
    }

    // ---- Mục 10: khoá tài khoản người thắng đấu giá ----

    @Test
    void lockingAWinnerCancelsTheInvoiceWithoutPenaltyAndInvitesTheRunnerUp() throws Exception {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long winner = createUser(Role.USER, "Người thắng", 0);
        long runner = createUser(Role.USER, "Người về nhì", 0);
        long admin = createUser(Role.ADMIN, "Admin", 0);
        jdbc.update("UPDATE wallets SET held_balance = 50000 WHERE user_id = ?", winner);
        long c = consignment(seller, "ACCEPTED");
        long book = jdbc.queryForObject("SELECT book_id FROM consignments WHERE id = ?", Long.class, c);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên test', now() - interval '1 day', now() - interval '2 day', 50000, 'ENDED') RETURNING id""", Long.class);
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low,
                                  estimate_high, current_price, opened_at, closed_at, status, close_result, hammer_price, winner_id, rounds)
                VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, 300000, now() - interval '1 day', now() - interval '1 day',
                        'SOLD', 'SOLD', 300000, ?, 1) RETURNING id""", Long.class, session, c, book, winner);
        long winnerReg = jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, 1, 50000, 10000000, 'APPROVED') RETURNING id""", Long.class, session, winner);
        long runnerReg = jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, 2, 50000, 10000000, 'REFUNDED') RETURNING id""", Long.class, session, runner);
        jdbc.update("INSERT INTO bids (lot_id, user_id, registration_id, amount) VALUES (?, ?, ?, 250000)", lot, runner, runnerReg);
        long invoice = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, lot_id, order_type, status, subtotal, total, deposit_applied, payment_due_at,
                                    pickup_at_warehouse)
                VALUES (?, ?, ?, 'AUCTION', 'PENDING_PAYMENT', 300000, 300000, 50000, now() + interval '40 hour', TRUE) RETURNING id""",
                Long.class, code("OD-"), winner, lot);

        mvc.perform(post("/admin/users/" + winner + "/lock").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Gian lận\"}")).andExpect(status().isOk());

        assertThat(one("SELECT status FROM orders WHERE id = ?", invoice)).isEqualTo("CANCELLED");
        assertThat(one("SELECT status FROM auction_registrations WHERE id = ?", winnerReg)).isEqualTo("REFUNDED");
        assertThat(walletHeld(winner)).isZero();
        assertThat(walletAvailable(winner)).as("cọc được hoàn, không bị phạt").isEqualTo(50_000);
        assertThat(jdbc.queryForObject("SELECT auction_banned_until IS NULL FROM users WHERE id = ?", Boolean.class, winner)).isTrue();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE buyer_id = ? AND second_chance AND status = 'PENDING_PAYMENT'",
                Long.class, runner)).as("người về nhì được mời mua lần hai").isEqualTo(1);
    }

    // ---- Mục 11: người bán không quyết định sau kiểm định ----

    @Test
    void sellerWhoNeverAnswersTheOfferIsTreatedAsWithdrawn() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long staff = createUser(Role.STAFF, "Kiểm định viên", 0);
        long c = consignment(seller, "AWAITING_SELLER");
        jdbc.update("""
                INSERT INTO inspections (consignment_id, inspector_id, result, condition_report, estimate_low, estimate_high,
                                         proposed_start, proposed_reserve, created_at)
                VALUES (?, ?, 'PASS', 'Tốt', 400000, 600000, 200000, 300000, now() - interval '8 day')""", c, staff);
        long w = warehouseItem(c, null);

        consignmentJobs.expireAppointments();

        assertThat(one("SELECT status FROM consignments WHERE id = ?", c)).isEqualTo("WITHDRAWN");
        assertThat(jdbc.queryForObject("SELECT return_notified_at IS NOT NULL FROM warehouse_items WHERE id = ?", Boolean.class, w))
                .as("bắt đầu tính hạn nhận lại sách").isTrue();
    }

    // ---- Mục 12: sách vô chủ ----

    @Test
    void unclaimedBookIsWarnedFirstThenDisposedAndTheStorageFeeBecomesADebt() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long c = consignment(seller, "WITHDRAWN");
        long w = warehouseItem(c, "70 day");

        consignmentJobs.expireAppointments();
        assertThat(one("SELECT status FROM warehouse_items WHERE id = ?", w)).as("lần đầu chỉ nhắc").isEqualTo("IN_STOCK");
        assertThat(jdbc.queryForObject("SELECT abandon_warned_at IS NOT NULL FROM warehouse_items WHERE id = ?", Boolean.class, w)).isTrue();

        jdbc.update("UPDATE warehouse_items SET abandon_warned_at = now() - interval '8 day' WHERE id = ?", w);
        consignmentJobs.expireAppointments();

        assertThat(jdbc.queryForMap("SELECT status, checkout_reason FROM warehouse_items WHERE id = ?", w))
                .containsEntry("status", "RETURNED").containsEntry("checkout_reason", "ABANDONED");
        assertThat(one("SELECT status FROM consignments WHERE id = ?", c)).isEqualTo("RETURNED");
        long perDay = Long.parseLong(jdbc.queryForObject("SELECT value FROM system_configs WHERE key = 'fee.storage_per_day'", String.class));
        long free = Long.parseLong(jdbc.queryForObject("SELECT value FROM system_configs WHERE key = 'fee.storage_free_days'", String.class));
        assertThat(jdbc.queryForObject("SELECT amount::bigint FROM account_debts WHERE user_id = ? AND type = 'STORAGE_FEE'", Long.class, seller))
                .isEqualTo((70 - free) * perDay);
    }

    // ---- Mục 13: kho quá hạn xử lý hoá đơn đấu giá ----

    @Test
    void paidAuctionInvoiceLeftUnconfirmedAlertsStaffOnce() {
        long buyer = createUser(Role.USER, "Người mua", 0);
        long staff = createUser(Role.STAFF, "Nhân viên kho", 0);
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, order_type, status, payment_method, subtotal, total, paid_at)
                VALUES (?, ?, 'AUCTION', 'PENDING_CONFIRM', 'WALLET', 100000, 100000, now() - interval '3 day') RETURNING id""",
                Long.class, code("OD-"), buyer);

        orderJobs.run();
        orderJobs.run();

        assertThat(jdbc.queryForObject("SELECT sla_alerted_at IS NOT NULL FROM orders WHERE id = ?", Boolean.class, order)).isTrue();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM notifications WHERE user_id = ? AND body LIKE ?", Long.class, staff,
                "%" + one("SELECT code FROM orders WHERE id = ?", order) + "%")).isEqualTo(1);
    }

    // ---- Mục 27: cấu hình không được phá luật ----

    @Test
    void configValuesThatWouldBreakTheRulesAreRejected() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin", 0);
        mvc.perform(put("/admin/configs/order.payment_timeout_minutes").with(as(admin, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"value\":\"0\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_CONFIG"));
        mvc.perform(put("/admin/configs/order.auto_complete_days").with(as(admin, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"value\":\"0\"}"))
                .andExpect(status().isBadRequest());
    }
}
