package com.rebook.auction;

import com.rebook.order.ShippingCalculator;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Luồng tiền đấu giá (docs/AUCTION_MONEY_FLOW.md): phạt bỏ thanh toán, nợ, huỷ đăng ký, lô không bán, gộp ship, kiểm định lại. */
class AuctionMoneyTest extends IntegrationTest {

    private static final long RESERVE = 100_000;

    @Autowired
    AuctionSettlement settlement;
    @Autowired
    AuctionMaintenanceJob maintenance;
    @Autowired
    AuctionSessionRepository sessions;
    @Autowired
    ShippingCalculator shipping;
    @Autowired
    org.springframework.transaction.support.TransactionTemplate tx;

    private static String code(String prefix) {
        return prefix + UUID.randomUUID().toString().substring(0, 18);
    }

    /** Một lô đã bán trong phiên đã kết thúc, người thắng đã đăng ký với cọc 50.000. */
    private record Scene(long seller, long winner, long session, long lot, long registration) {
    }

    private long category() {
        return jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class,
                "am-" + UUID.randomUUID());
    }

    private long book(long owner, long category, int weightGram) {
        return jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade, weight_gram)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD', ?) RETURNING id""", Long.class, owner, "Sách " + UUID.randomUUID(), category, weightGram);
    }

    private long consignment(long seller, long book) {
        return jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, code("KG-"), seller, book);
    }

    private long endedSession() {
        return jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên test', now() - interval '1 day', now() - interval '2 day', 50000, 'ENDED') RETURNING id""", Long.class);
    }

    private long soldLot(long session, long consignment, long book, int number, long hammer, long winner) {
        return jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price,
                                  estimate_low, estimate_high, current_price, opened_at, closed_at, status, close_result,
                                  hammer_price, winner_id, rounds)
                VALUES (?, ?, ?, ?, 50000, ?, 100000, 200000, ?, now() - interval '1 day', now() - interval '1 day',
                        'SOLD', 'SOLD', ?, ?, 1) RETURNING id""", Long.class,
                session, consignment, book, number, RESERVE, hammer, hammer, winner);
    }

    private long registration(long session, long user, int paddle, String status) {
        return jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, ?, 50000, 10000000, ?) RETURNING id""", Long.class, session, user, paddle, status);
    }

    private Scene scene(long hammer, long winnerAvailable, long winnerHeld, String registrationStatus) {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long winner = createUser(Role.USER, "Người thắng", winnerAvailable);
        jdbc.update("UPDATE wallets SET held_balance = ? WHERE user_id = ?", winnerHeld, winner);
        long book = book(seller, category(), 300);
        long session = endedSession();
        long lot = soldLot(session, consignment(seller, book), book, 1, hammer, winner);
        return new Scene(seller, winner, session, lot, registration(session, winner, 1, registrationStatus));
    }

    /** Hoá đơn lô thắng đã quá hạn thanh toán. */
    private long overdueInvoice(Scene s, long hammer) {
        return jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, lot_id, order_type, status, subtotal, total, payment_due_at, pickup_at_warehouse)
                VALUES (?, ?, ?, 'AUCTION', 'PENDING_PAYMENT', ?, ?, now() - interval '1 hour', TRUE) RETURNING id""",
                Long.class, code("OD-"), s.winner(), s.lot(), hammer, hammer);
    }

    private long platform() {
        return jdbc.queryForObject("SELECT available_balance FROM wallets WHERE user_id IS NULL", Long.class);
    }

    private long held(long user) {
        return jdbc.queryForObject("SELECT held_balance FROM wallets WHERE user_id = ?", Long.class, user);
    }

    private String regStatus(long reg) {
        return jdbc.queryForObject("SELECT status FROM auction_registrations WHERE id = ?", String.class, reg);
    }

    private long debtCount(long user, String status) {
        return jdbc.queryForObject("SELECT count(*) FROM account_debts WHERE user_id = ? AND status = ?", Long.class, user, status);
    }

    // ---- Phạt bỏ thanh toán ----

    @Test
    void firstDefaultLosesTheWholeDepositWhenItIsLargerThanThePercentPenalty() {
        Scene s = scene(120_000, 0, 50_000, "APPROVED"); // phạt 10% = 12.000 < cọc 50.000 → mất cọc
        long order = overdueInvoice(s, 120_000);
        long platformBefore = platform();

        settlement.handleOverdue(order);

        assertThat(regStatus(s.registration())).isEqualTo("FORFEITED");
        assertThat(held(s.winner())).isZero();
        assertThat(walletAvailable(s.seller())).isEqualTo(25_000);
        assertThat(platform()).isEqualTo(platformBefore + 25_000);
        assertThat(debtCount(s.winner(), "OPEN")).isZero();
        assertThat(jdbc.queryForObject("SELECT auction_banned_until IS NOT NULL FROM users WHERE id = ?", Boolean.class, s.winner())).isTrue();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'AUCTION.DEFAULT.PENALIZED' AND target_id = ?",
                Long.class, String.valueOf(order))).isEqualTo(1);
    }

    @Test
    void penaltyBeyondTheDepositIsChargedToTheWallet() {
        Scene s = scene(1_000_000, 80_000, 50_000, "APPROVED"); // phạt 10% = 100.000 = cọc 50.000 + 50.000 từ ví
        long platformBefore = platform();

        settlement.handleOverdue(overdueInvoice(s, 1_000_000));

        assertThat(walletAvailable(s.winner())).isEqualTo(30_000);
        assertThat(walletAvailable(s.seller())).isEqualTo(50_000);
        assertThat(platform()).isEqualTo(platformBefore + 50_000);
        assertThat(debtCount(s.winner(), "OPEN")).isZero();
    }

    @Test
    void shortfallBecomesADebtThatBlocksUntilItIsPaid() throws Exception {
        Scene s = scene(1_000_000, 20_000, 50_000, "APPROVED"); // cần thêm 50.000, ví chỉ có 20.000
        long platformBefore = platform();
        settlement.handleOverdue(overdueInvoice(s, 1_000_000));

        assertThat(walletAvailable(s.winner())).isZero();
        assertThat(debtCount(s.winner(), "OPEN")).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT amount - paid_amount FROM account_debts WHERE user_id = ?", Long.class, s.winner()))
                .isEqualTo(30_000);

        // Còn nợ: không rút tiền được.
        mvcWithdraw(s.winner(), 50_000).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("DEBT_OPEN"));
        // Còn nợ: không đăng ký phiên mới được (gỡ lệnh cấm để thấy đúng lý do nợ).
        jdbc.update("UPDATE users SET auction_banned_until = NULL, phone_verified = TRUE WHERE id = ?", s.winner());
        long open = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên mở', now() + interval '2 days', now() + interval '1 day', 50000, 'PUBLISHED') RETURNING id""", Long.class);
        mvc.perform(post("/sessions/" + open + "/register").with(as(s.winner(), Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"agreeRules\":true}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DEBT_OPEN"));

        // Nạp tiền rồi thu nợ: hết chặn, tiền phạt chia người bán / sàn như phần cọc.
        jdbc.update("UPDATE wallets SET available_balance = available_balance + 100000 WHERE user_id = ?", s.winner());
        mvc.perform(post("/me/debts/collect").with(as(s.winner(), Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collected").value(30000))
                .andExpect(jsonPath("$.stillOwed").value(0));
        assertThat(debtCount(s.winner(), "PAID")).isEqualTo(1);
        assertThat(walletAvailable(s.seller())).isEqualTo(50_000); // 25.000 từ cọc + 10.000 + 15.000 từ nợ
        assertThat(platform()).isEqualTo(platformBefore + 50_000);
        mvcWithdraw(s.winner(), 50_000).andExpect(status().isCreated());
    }

    private org.springframework.test.web.servlet.ResultActions mvcWithdraw(long user, long amount) throws Exception {
        return mvc.perform(post("/wallet/withdrawals").with(as(user, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"bankName\":\"VCB\",\"accountNumber\":\"123456789\",\"accountHolder\":\"NGUOI RUT\"}"));
    }

    @Test
    void laterDefaultAfterTheDepositWasAlreadyUsedChargesOnlyThePercent() {
        Scene s = scene(2_000_000, 500_000, 0, "APPLIED"); // cọc đã trừ vào hoá đơn lô khác
        long platformBefore = platform();

        settlement.handleOverdue(overdueInvoice(s, 2_000_000));

        assertThat(regStatus(s.registration())).isEqualTo("APPLIED"); // không còn cọc để thu
        assertThat(walletAvailable(s.winner())).isEqualTo(300_000);    // phạt 10% × 2.000.000 = 200.000
        assertThat(walletAvailable(s.seller())).isEqualTo(100_000);
        assertThat(platform()).isEqualTo(platformBefore + 100_000);
        assertThat(debtCount(s.winner(), "OPEN")).isZero();
    }

    @Test
    void secondChanceSkipsARunnerUpWhoIsBannedAndOffersTheNextOne() {
        Scene s = scene(300_000, 0, 50_000, "APPROVED");
        long banned = createUser(Role.USER, "Người bị cấm", 0);
        long good = createUser(Role.USER, "Người hợp lệ", 0);
        jdbc.update("UPDATE users SET auction_banned_until = now() + interval '30 days' WHERE id = ?", banned);
        long bannedReg = registration(s.session(), banned, 2, "REFUNDED");
        long goodReg = registration(s.session(), good, 3, "REFUNDED");
        jdbc.update("INSERT INTO bids (lot_id, user_id, registration_id, amount) VALUES (?, ?, ?, 250000)", s.lot(), banned, bannedReg);
        jdbc.update("INSERT INTO bids (lot_id, user_id, registration_id, amount) VALUES (?, ?, ?, 150000)", s.lot(), good, goodReg);

        settlement.handleOverdue(overdueInvoice(s, 300_000));

        assertThat(jdbc.queryForObject("SELECT buyer_id FROM orders WHERE lot_id = ? AND second_chance", Long.class, s.lot()))
                .isEqualTo(good);
        assertThat(jdbc.queryForObject("SELECT hammer_price FROM lots WHERE id = ?", Long.class, s.lot())).isEqualTo(150_000);
    }

    // ---- Huỷ đăng ký ----

    @Test
    void registrationCanBeCancelledBeforeTheDeadlineAndTheDepositComesBack() throws Exception {
        long me = createUser(Role.USER, "Người đăng ký", 800_000);
        jdbc.update("UPDATE users SET phone_verified = TRUE WHERE id = ?", me);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên mở đăng ký', now() + interval '2 days', now() + interval '1 day', 500000, 'PUBLISHED') RETURNING id""", Long.class);

        mvc.perform(post("/sessions/" + session + "/register").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"agreeRules\":true}")).andExpect(status().isCreated());
        assertThat(walletAvailable(me)).isEqualTo(300_000);
        assertThat(held(me)).isEqualTo(500_000);
        mvc.perform(get("/sessions/" + session)).andExpect(jsonPath("$.session.registeredCount").value(1));

        mvc.perform(delete("/sessions/" + session + "/register").with(as(me, Role.USER))).andExpect(status().isOk());
        assertThat(walletAvailable(me)).isEqualTo(800_000);
        assertThat(held(me)).isZero();
        mvc.perform(get("/sessions/" + session)).andExpect(jsonPath("$.session.registeredCount").value(0));

        // Đăng ký lại trong hạn: dùng lại dòng cũ, giữ số bài.
        mvc.perform(post("/sessions/" + session + "/register").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"agreeRules\":true}")).andExpect(status().isCreated());
        assertThat(held(me)).isEqualTo(500_000);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM auction_registrations WHERE session_id = ? AND user_id = ?",
                Long.class, session, me)).isEqualTo(1);

        // Sau hạn đăng ký thì không huỷ được.
        jdbc.update("UPDATE auction_sessions SET registration_deadline = now() - interval '1 minute', start_at = now() + interval '1 hour' WHERE id = ?", session);
        mvc.perform(delete("/sessions/" + session + "/register").with(as(me, Role.USER)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("REGISTRATION_CLOSED"));
        assertThat(held(me)).isEqualTo(500_000);
    }

    // ---- Lô không bán, phí kho ----

    private record Unsold(long lot, long consignment, long warehouse, long seller) {
    }

    private Unsold unsoldLot(int closedDaysAgo, String lotStatus) {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long book = book(seller, category(), 300);
        long consignment = consignment(seller, book);
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low,
                                  estimate_high, status, close_result, closed_at, rounds)
                VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, ?, 'NO_BIDS', now() - (? * interval '1 day'), 1) RETURNING id""",
                Long.class, endedSession(), consignment, book, lotStatus, closedDaysAgo);
        long warehouse = jdbc.queryForObject("INSERT INTO warehouse_items (consignment_id, code) VALUES (?, ?) RETURNING id",
                Long.class, consignment, code("WH"));
        return new Unsold(lot, consignment, warehouse, seller);
    }

    @Test
    void unsoldLotIsReturnedToTheSellerWhenNoDecisionIsMadeInTime() {
        Unsold late = unsoldLot(8, "UNSOLD");
        Unsold recent = unsoldLot(2, "UNSOLD");

        maintenance.runOnce();

        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, late.lot())).isEqualTo("RETURNED");
        assertThat(jdbc.queryForObject("SELECT return_notified_at IS NOT NULL FROM warehouse_items WHERE id = ?", Boolean.class, late.warehouse())).isTrue();
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, recent.lot())).isEqualTo("UNSOLD");
    }

    @Test
    void storageFeeIsADebtWhenTheSellerCannotPayAndTheBookIsStillReturned() throws Exception {
        Unsold u = unsoldLot(30, "RETURNED");
        jdbc.update("UPDATE warehouse_items SET return_notified_at = now() - interval '20 days' WHERE id = ?", u.warehouse());
        long staff = createUser(Role.STAFF, "Nhân viên kho", 0);

        mvc.perform(post("/staff/warehouse/" + u.warehouse() + "/return").with(as(staff, Role.STAFF))).andExpect(status().isOk());

        assertThat(jdbc.queryForObject("SELECT status FROM warehouse_items WHERE id = ?", String.class, u.warehouse())).isEqualTo("RETURNED");
        assertThat(jdbc.queryForObject("SELECT status FROM consignments WHERE id = ?", String.class, u.consignment())).isEqualTo("RETURNED");
        // 20 ngày − 14 ngày miễn phí = 6 ngày × 5.000
        assertThat(jdbc.queryForObject("SELECT amount FROM account_debts WHERE user_id = ? AND type = 'STORAGE_FEE'", Long.class, u.seller()))
                .isEqualTo(30_000);
        assertThat(debtCount(u.seller(), "OPEN")).isEqualTo(1);
    }

    // ---- Gộp phí giao ----

    @Test
    void shippingForSeveralWonLotsIsChargedAsOneParcel() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long winner = createUser(Role.USER, "Người thắng 2 lô", 0);
        jdbc.update("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người thắng', '0900000000', 'TP. Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi')""", winner);
        long category = category();
        long session = endedSession();
        long bookA = book(seller, category, 600);
        long bookB = book(seller, category, 700);
        long lotA = soldLot(session, consignment(seller, bookA), bookA, 1, 100_000, winner);
        long lotB = soldLot(session, consignment(seller, bookB), bookB, 2, 100_000, winner);
        registration(session, winner, 1, "APPROVED");

        // Trong sản phẩm hàm này chạy bên trong giao dịch của bộ máy chạy phiên (AuctionRunner.tick)
        tx.executeWithoutResult(st -> settlement.afterSessionEnded(sessions.findById(session).orElseThrow()));

        String province = "TP. Hồ Chí Minh";
        long feeA = jdbc.queryForObject("SELECT shipping_fee FROM orders WHERE lot_id = ?", Long.class, lotA);
        long feeB = jdbc.queryForObject("SELECT shipping_fee FROM orders WHERE lot_id = ?", Long.class, lotB);
        assertThat(feeA).isEqualTo(shipping.fee(shipping.warehouseProvince(), province, 600).longValue());
        assertThat(feeA + feeB).isEqualTo(shipping.fee(shipping.warehouseProvince(), province, 1300).longValue());
        assertThat(feeB).isLessThan(feeA);
    }

    // ---- Trả hàng → kiểm định lại ----

    private long returnedOrderLot() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long buyer = createUser(Role.USER, "Người mua", 0);
        long book = book(seller, category(), 300);
        long consignment = consignment(seller, book);
        long session = endedSession();
        long lot = soldLot(session, consignment, book, 1, 100_000, buyer);
        jdbc.update("UPDATE lots SET status = 'PAID' WHERE id = ?", lot);
        jdbc.update("INSERT INTO warehouse_items (consignment_id, code, status) VALUES (?, ?, 'SHIPPED')", consignment, code("WH"));
        jdbc.update("UPDATE wallets SET held_balance = 100000 WHERE user_id = ?", seller);
        jdbc.update("UPDATE wallets SET available_balance = available_balance + 200000 WHERE user_id IS NULL"); // ví sàn đủ để hoàn phí
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, lot_id, order_type, status, payment_method, paid_at, subtotal, buyer_premium,
                                    shipping_fee, total, delivered_at)
                VALUES (?, ?, ?, 'AUCTION', 'RETURN_REQUESTED', 'WALLET', now(), 100000, 10000, 20000, 130000, now() - interval '1 day')
                RETURNING id""", Long.class, code("OD-"), buyer, lot);
        jdbc.update("""
                INSERT INTO return_requests (order_id, reason, description, status, approved_at, return_shipped_at)
                VALUES (?, 'WRONG_CONDITION', 'Khác báo cáo tình trạng', 'AWAITING_GOODS', now() - interval '2 days', now() - interval '1 day')""", order);
        long staff = createUser(Role.STAFF, "Nhân viên kho", 0);
        try {
            mvc.perform(post("/staff/orders/" + order + "/return-received").with(as(staff, Role.STAFF))).andExpect(status().isOk());
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
        assertThat(walletAvailable(buyer)).isEqualTo(130_000); // hoàn đủ tổng hoá đơn
        assertThat(held(seller)).isZero();
        return lot;
    }

    @Test
    void returnedLotMustBeReinspectedAndGoesBackToTheQueueWhenItPasses() throws Exception {
        long lot = returnedOrderLot();
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot)).isEqualTo("INSPECTING");
        long staff = createUser(Role.STAFF, "Nhân viên kiểm định", 0);

        mvc.perform(post("/staff/lots/" + lot + "/reinspect").with(as(staff, Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"passed\":true,\"report\":\"Sách còn nguyên vẹn, đủ trang\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("READY"));
        assertThat(jdbc.queryForObject("SELECT session_id IS NULL FROM lots WHERE id = ?", Boolean.class, lot)).isTrue();
    }

    @Test
    void returnedLotThatFailsReinspectionIsReturnedToTheSeller() throws Exception {
        long lot = returnedOrderLot();
        long staff = createUser(Role.STAFF, "Nhân viên kiểm định", 0);

        mvc.perform(post("/staff/lots/" + lot + "/reinspect").with(as(staff, Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"passed\":false,\"report\":\"Thiếu nhiều trang, không đấu giá được\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RETURNED"));
        mvc.perform(post("/staff/lots/" + lot + "/reinspect").with(as(staff, Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"passed\":true,\"report\":\"Kiểm lần hai không hợp lệ\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LOT_NOT_INSPECTING"));
    }
}
