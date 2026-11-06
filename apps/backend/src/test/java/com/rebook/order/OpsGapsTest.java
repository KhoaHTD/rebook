package com.rebook.order;

import com.rebook.auction.AuctionMaintenanceJob;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Vận hành COD khi chưa có hãng vận chuyển tích hợp, địa chỉ nhận hàng trả, danh sách kiểm định lại, nhắc trước hạn. */
class OpsGapsTest extends IntegrationTest {

    @Autowired
    OrderJobs jobs;
    @Autowired
    AuctionMaintenanceJob maintenance;

    private long buyer;
    private long shopOwner;
    private long shop;

    private void setUpShop() {
        buyer = createUser(Role.USER, "Người Mua", 0);
        shopOwner = createUser(Role.USER, "Chủ shop", 0);
        shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Số 1 Lê Lợi, Quận 1', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, shopOwner, "Shop " + UUID.randomUUID());
    }

    private long order(String type, String status, String method, String paidAt, String extra) {
        String[] kv = extra.isEmpty() ? new String[]{null, null} : extra.split("=", 2);
        return jdbc.queryForObject("INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, paid_at, subtotal, "
                        + "shipping_fee, total" + (kv[0] == null ? "" : ", " + kv[0]) + ") VALUES (?, ?, ?, ?, ?, ?, " + paidAt
                        + ", 100000, 20000, 120000" + (kv[1] == null ? "" : ", " + kv[1]) + ") RETURNING id",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer, "AUCTION".equals(type) ? null : shop, type, status, method);
    }

    private String orderStatus(long id) {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, id);
    }

    private long notifications(long user, String bodyLike) {
        return jdbc.queryForObject("SELECT count(*) FROM notifications WHERE user_id = ? AND body LIKE ?", Long.class, user, bodyLike);
    }

    // ---- COD khi chưa có hãng vận chuyển ----

    @Test
    void staffConfirmsTheCarrierResultOfAShippingOrder() throws Exception {
        setUpShop();
        long staff = createUser(Role.STAFF, "Nhân viên kho", 0);
        long delivered = order("NORMAL", "SHIPPING", "COD", "NULL", "shipped_at=now() - interval '2 days'");
        long failedCod = order("NORMAL", "SHIPPING", "COD", "NULL", "shipped_at=now() - interval '2 days'");
        long failedPaid = order("NORMAL", "SHIPPING", "WALLET", "now()", "shipped_at=now() - interval '2 days'");
        jdbc.update("UPDATE wallets SET held_balance = 120000 WHERE user_id = ?", shopOwner);

        mvc.perform(post("/staff/orders/" + delivered + "/carrier-delivered").with(as(staff, Role.STAFF))).andExpect(status().isOk());
        mvc.perform(post("/staff/orders/" + failedCod + "/carrier-failed").with(as(staff, Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Người nhận từ chối\"}")).andExpect(status().isOk());
        mvc.perform(post("/staff/orders/" + failedPaid + "/carrier-failed").with(as(staff, Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Thất lạc\"}")).andExpect(status().isOk());

        assertThat(orderStatus(delivered)).isEqualTo("DELIVERED");
        assertThat(orderStatus(failedCod)).isEqualTo("FAILED_DELIVERY");
        assertThat(orderStatus(failedPaid)).isEqualTo("FAILED_DELIVERY");
        assertThat(walletAvailable(buyer)).isEqualTo(120_000); // đơn trả trước được hoàn tiền
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'ORDER.DELIVERY.MARKED' AND target_id = ? "
                + "AND details->>'source' = 'CARRIER_CHECK'", Long.class, String.valueOf(delivered))).isEqualTo(1);

        // Người dùng thường không dùng được; đơn đã giao rồi không đánh dấu lại được.
        mvc.perform(post("/staff/orders/" + delivered + "/carrier-failed").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"x\"}")).andExpect(status().isForbidden());
        mvc.perform(post("/staff/orders/" + delivered + "/carrier-delivered").with(as(staff, Role.STAFF))).andExpect(status().isConflict());
    }

    @Test
    void codOrdersAreNeverTreatedAsDeliveredByTheTimerAndAreListedForStaff() throws Exception {
        setUpShop();
        long staff = createUser(Role.STAFF, "Nhân viên kho", 0);
        long codLate = order("NORMAL", "SHIPPING", "COD", "NULL", "shipped_at=now() - interval '10 days'");
        long paidLate = order("NORMAL", "SHIPPING", "WALLET", "now()", "shipped_at=now() - interval '10 days'");

        jobs.run();

        assertThat(orderStatus(codLate)).isEqualTo("SHIPPING"); // chờ Staff đối chiếu: tiền mặt chưa chắc đã thu
        assertThat(orderStatus(paidLate)).isEqualTo("DELIVERED");
        mvc.perform(get("/staff/orders/in-transit").param("size", "200").with(as(staff, Role.STAFF)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.orderId == " + codLate + ")].overdue").value(true));
        mvc.perform(get("/staff/orders/in-transit").with(as(buyer, Role.USER))).andExpect(status().isForbidden());
    }

    @Test
    void buyerWithTwoFailedCodDeliveriesCannotPlaceAnotherCodOrder() throws Exception {
        setUpShop();
        long staff = createUser(Role.STAFF, "Nhân viên kho", 0);
        for (int i = 0; i < 2; i++) {
            long id = order("NORMAL", "SHIPPING", "COD", "NULL", "shipped_at=now() - interval '2 days'");
            mvc.perform(post("/staff/orders/" + id + "/carrier-failed").with(as(staff, Role.STAFF)).contentType(MediaType.APPLICATION_JSON)
                    .content("{\"reason\":\"Bom hàng\"}")).andExpect(status().isOk());
        }
        long address = jdbc.queryForObject("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người Mua', '0900000000', 'Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi') RETURNING id""", Long.class, buyer);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "og-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, shopOwner, "Sách " + UUID.randomUUID(), category);
        long listing = jdbc.queryForObject("INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 45000, 3, 'ACTIVE') RETURNING id",
                Long.class, book, shop);
        mvc.perform(post("/cart").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"listingId\":" + listing + ",\"quantity\":1}")).andExpect(status().isOk());

        mvc.perform(post("/orders/checkout").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"addressId\":" + address + ",\"paymentMethod\":\"COD\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("COD_NOT_ALLOWED"));
    }

    // ---- Địa chỉ nhận hàng trả ----

    @Test
    void approvedReturnTellsTheBuyerWhereToSendTheBook() throws Exception {
        setUpShop();
        long id = order("NORMAL", "DELIVERED", "COD", "NULL", "delivered_at=now() - interval '1 day'");
        mvc.perform(post("/orders/" + id + "/return").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"MISSING_PAGES\",\"description\":\"Thiếu trang 10-20\",\"images\":[\"/files/a.png\"]}"))
                .andExpect(status().isOk());
        mvc.perform(post("/seller/orders/" + id + "/return-decision").with(as(shopOwner, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"approve\":true}")).andExpect(status().isOk());

        mvc.perform(get("/orders/" + id).with(as(buyer, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.returnRequest.returnToAddress").value("Số 1 Lê Lợi, Quận 1"))
                .andExpect(jsonPath("$.returnRequest.returnToName").isNotEmpty());
        assertThat(notifications(buyer, "%Số 1 Lê Lợi, Quận 1%")).isEqualTo(1);
    }

    // ---- Danh sách lô chờ kiểm định lại ----

    @Test
    void staffCanListLotsWaitingForReinspection() throws Exception {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long staff = createUser(Role.STAFF, "Nhân viên kiểm định", 0);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "ins-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, 'Sách chờ kiểm lại', 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, seller, category);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, "KG-" + UUID.randomUUID().toString().substring(0, 18), seller, book);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên test', now() - interval '1 day', now() - interval '2 day', 50000, 'ENDED') RETURNING id""", Long.class);
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                                  status, hammer_price, rounds)
                VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, 'INSPECTING', 150000, 1) RETURNING id""", Long.class, session, consignment, book);

        mvc.perform(get("/staff/lots/inspecting").param("size", "200").with(as(staff, Role.STAFF)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.lotId == " + lot + ")].bookTitle").value("Sách chờ kiểm lại"));
        mvc.perform(get("/staff/lots/inspecting").with(as(seller, Role.USER))).andExpect(status().isForbidden());
    }

    // ---- Nhắc trước hạn (mỗi loại một lần) ----

    @Test
    void shopIsRemindedOnceBeforeTheShippingDeadline() {
        setUpShop();
        long near = order("NORMAL", "PREPARING", "COD", "NULL", "ship_due_at=now() + interval '10 hours'");
        long far = order("NORMAL", "PREPARING", "COD", "NULL", "ship_due_at=now() + interval '2 days'");

        jobs.run();
        jobs.run(); // chạy lại không nhắc trùng

        assertThat(notifications(shopOwner, "%cần giao cho vận chuyển trước%")).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT ship_reminder_sent FROM orders WHERE id = ?", Boolean.class, near)).isTrue();
        assertThat(jdbc.queryForObject("SELECT ship_reminder_sent FROM orders WHERE id = ?", Boolean.class, far)).isFalse();
    }

    @Test
    void shopIsRemindedHalfwayThroughTheCancelRequestWindow() {
        setUpShop();
        long id = order("NORMAL", "PREPARING", "COD", "NULL", "cancel_requested_at=now() - interval '13 hours'");
        jdbc.update("UPDATE orders SET cancel_requested = TRUE WHERE id = ?", id);

        jobs.run();

        assertThat(notifications(shopOwner, "%đang chờ bạn trả lời yêu cầu huỷ%")).isEqualTo(1);
        assertThat(orderStatus(id)).isEqualTo("PREPARING"); // chưa tới hạn 24 giờ nên chưa tự huỷ
    }

    @Test
    void winnerIsRemindedAboutTheInvoiceDeadlineAndTheConsequences() {
        setUpShop();
        long id = order("AUCTION", "PENDING_PAYMENT", "WALLET", "NULL", "payment_due_at=now() + interval '10 hours'");

        jobs.run();
        jobs.run();

        assertThat(notifications(buyer, "%Quá hạn bạn bị phạt%")).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT payment_reminder_sent FROM orders WHERE id = ?", Boolean.class, id)).isTrue();
    }

    @Test
    void sellerIsRemindedBeforeAnUnsoldLotIsReturned() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "rm-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, seller, "Sách " + UUID.randomUUID(), category);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, "KG-" + UUID.randomUUID().toString().substring(0, 18), seller, book);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên test', now() - interval '7 days', now() - interval '8 day', 50000, 'ENDED') RETURNING id""", Long.class);
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                                  status, close_result, closed_at, rounds)
                VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, 'UNSOLD', 'NO_BIDS', now() - interval '6 days 12 hours', 1) RETURNING id""",
                Long.class, session, consignment, book);

        maintenance.runOnce();
        maintenance.runOnce();

        assertThat(notifications(seller, "%chưa có hướng xử lý%")).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot)).isEqualTo("UNSOLD"); // chưa tới hạn tự trả
    }
}
