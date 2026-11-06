package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Role;
import com.rebook.wallet.WalletReconciliationJob;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Luật tiền (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần E): COD đối soát với hãng vận chuyển, khoá tiền mới nạp, trả hàng theo bước,
 * xác nhận giao hàng, chụp tỷ lệ phí, đối soát ví, ghi sự kiện.
 */
class MoneyRulesTest extends IntegrationTest {

    @Autowired
    OrderJobs jobs;
    @Autowired
    WalletReconciliationJob reconciliation;
    @Autowired
    SystemConfigService config;

    private long shopOwner;
    private long shop;
    private long buyer;

    private void setUpShop() {
        buyer = createUser(Role.USER, "Người Mua", 0);
        shopOwner = createUser(Role.USER, "Chủ shop", 0);
        shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, shopOwner, "Shop " + UUID.randomUUID());
    }

    /** Đơn NORMAL: tiền sách 100.000 + ship 20.000 = 120.000, phí sàn đã chụp 5%. */
    private long order(String status, String method, String extraColumns, String extraValues) {
        return jdbc.queryForObject("INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, subtotal, "
                        + "shipping_fee, total, fee_percent, delivered_at, shipped_at" + extraColumns + ") VALUES (?, ?, ?, 'NORMAL', ?, ?, "
                        + "100000, 20000, 120000, 5, now() - interval '1 day', now() - interval '2 day'" + extraValues + ") RETURNING id",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer, shop, status, method);
    }

    private long platformBalance() {
        return jdbc.queryForObject("SELECT available_balance FROM wallets WHERE user_id IS NULL", Long.class);
    }

    private String orderStatus(long order) {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, order);
    }

    private String returnStatus(long order) {
        return jdbc.queryForObject("SELECT status FROM return_requests WHERE order_id = ?", String.class, order);
    }

    private long auditCount(String code, String targetId) {
        // Chỉ đếm sự kiện thành công; lần bị từ chối (vd nhập sai số tiền) được ghi riêng với result = DENIED.
        return jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = ? AND target_id = ? AND result = 'SUCCESS'",
                Long.class, code, targetId);
    }

    // ---- COD ----

    @Test
    void codMoneyReachesTheSellerOnlyAfterTheCarrierRemitsToThePlatform() throws Exception {
        setUpShop();
        long admin = createUser(Role.ADMIN, "Admin đối soát", 0);
        long id = order("DELIVERED", "COD", "", "");
        long platformBefore = platformBalance();

        mvc.perform(post("/orders/" + id + "/confirm-received").with(as(buyer, Role.USER))).andExpect(status().isOk());
        // Hoàn tất nhưng sàn chưa nhận tiền từ hãng vận chuyển: ví shop và ví sàn không đổi.
        assertThat(walletAvailable(shopOwner)).isZero();
        assertThat(platformBalance()).isEqualTo(platformBefore);

        mvc.perform(post("/admin/cod/" + id + "/remit").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\":100000}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("COD_AMOUNT_MISMATCH"));
        mvc.perform(post("/admin/cod/" + id + "/remit").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\":120000,\"reference\":\"GHN-0001\"}"))
                .andExpect(status().isOk());

        // Shop nhận 120.000 − phí 5% trên tiền sách (5.000); sàn giữ đúng 5.000 phí.
        assertThat(walletAvailable(shopOwner)).isEqualTo(115_000);
        assertThat(platformBalance()).isEqualTo(platformBefore + 5_000);
        mvc.perform(post("/admin/cod/" + id + "/remit").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\":120000}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_REMITTED"));
        assertThat(auditCount("COD.REMITTED", String.valueOf(id))).isEqualTo(1);
        assertThat(auditCount("COD.PAID_OUT", String.valueOf(id))).isEqualTo(1);
    }

    @Test
    void codRemittedBeforeCompletionIsPaidOutWhenTheOrderCompletes() throws Exception {
        setUpShop();
        long admin = createUser(Role.ADMIN, "Admin đối soát", 0);
        long id = order("DELIVERED", "COD", "", "");

        mvc.perform(post("/admin/cod/" + id + "/remit").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":120000}")).andExpect(status().isOk());
        assertThat(walletAvailable(shopOwner)).isZero(); // còn trong thời hạn khiếu nại, chưa trả shop
        mvc.perform(post("/orders/" + id + "/confirm-received").with(as(buyer, Role.USER))).andExpect(status().isOk());
        assertThat(walletAvailable(shopOwner)).isEqualTo(115_000);
    }

    @Test
    void codCannotBeRemittedBeforeDelivery() throws Exception {
        setUpShop();
        long admin = createUser(Role.ADMIN, "Admin đối soát", 0);
        long id = order("SHIPPING", "COD", "", "");
        mvc.perform(post("/admin/cod/" + id + "/remit").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\":120000}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("COD_NOT_COLLECTED"));
    }

    @Test
    void codReturnRefundWaitsForTheCarrierMoney() throws Exception {
        setUpShop();
        long admin = createUser(Role.ADMIN, "Admin đối soát", 0);
        long id = order("DELIVERED", "COD", "", "");
        long platformBefore = platformBalance();

        mvc.perform(post("/orders/" + id + "/return").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"MISSING_PAGES\",\"description\":\"Thiếu trang 10-20\",\"images\":[\"/files/a.png\"]}"))
                .andExpect(status().isOk());
        mvc.perform(post("/seller/orders/" + id + "/return-decision").with(as(shopOwner, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approve\":true}"))
                .andExpect(status().isOk());
        // Đồng ý trả chưa hoàn tiền: chờ người mua gửi hàng về.
        assertThat(orderStatus(id)).isEqualTo("RETURN_REQUESTED");
        assertThat(returnStatus(id)).isEqualTo("AWAITING_GOODS");

        mvc.perform(post("/seller/orders/" + id + "/return-received").with(as(shopOwner, Role.USER)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("RETURN_NOT_SHIPPED"));
        mvc.perform(post("/orders/" + id + "/return/shipment").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"trackingCode\":\"GHN123456\"}"))
                .andExpect(status().isOk());
        mvc.perform(post("/seller/orders/" + id + "/return-received").with(as(shopOwner, Role.USER)))
                .andExpect(status().isOk());

        // Sàn chưa nhận tiền COD từ hãng vận chuyển nên chưa có gì để hoàn: đánh dấu chờ.
        assertThat(orderStatus(id)).isEqualTo("RETURNED");
        assertThat(walletAvailable(buyer)).isZero();
        assertThat(jdbc.queryForObject("SELECT cod_refund_pending FROM orders WHERE id = ?", Boolean.class, id)).isTrue();

        mvc.perform(post("/admin/cod/" + id + "/remit").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":120000}")).andExpect(status().isOk());
        assertThat(walletAvailable(buyer)).isEqualTo(120_000);
        assertThat(walletAvailable(shopOwner)).isZero();
        assertThat(platformBalance()).isEqualTo(platformBefore); // nhận 120.000 rồi hoàn đúng 120.000
        assertThat(jdbc.queryForObject("SELECT cod_refund_pending FROM orders WHERE id = ?", Boolean.class, id)).isFalse();
    }

    @Test
    void newBuyerCannotPlaceABigCodOrder() throws Exception {
        setUpShop();
        long address = jdbc.queryForObject("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người Mua', '0900000000', 'Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi') RETURNING id""", Long.class, buyer);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "cod-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, shopOwner, "Sách quý " + UUID.randomUUID(), category);
        long listing = jdbc.queryForObject("INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 800000, 2, 'ACTIVE') RETURNING id",
                Long.class, book, shop);
        mvc.perform(post("/cart").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"listingId\":" + listing + ",\"quantity\":1}")).andExpect(status().isOk());

        mvc.perform(post("/orders/checkout").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"addressId\":" + address + ",\"paymentMethod\":\"COD\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("COD_NOT_ALLOWED"));
        // Đơn bị huỷ nguyên giao dịch: tồn kho không bị giữ; việc bị chặn vẫn có dấu vết.
        assertThat(jdbc.queryForObject("SELECT stock FROM listings WHERE id = ?", Integer.class, listing)).isEqualTo(2);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'COD.BLOCKED' AND target_id = ?",
                Long.class, String.valueOf(buyer))).isEqualTo(1);
    }

    @Test
    void orderRemembersTheFeeRateItWasPlacedWith() throws Exception {
        setUpShop();
        // Đơn đã trả bằng ví, tiền shop đang chờ trong held. Phí chụp lúc đặt là 10%, cấu hình hiện tại 5%.
        long id = order("DELIVERED", "WALLET", ", paid_at", ", now()");
        jdbc.update("UPDATE orders SET fee_percent = 10 WHERE id = ?", id);
        jdbc.update("UPDATE wallets SET held_balance = 120000 WHERE user_id = ?", shopOwner);

        mvc.perform(post("/orders/" + id + "/confirm-received").with(as(buyer, Role.USER))).andExpect(status().isOk());

        assertThat(walletAvailable(shopOwner)).isEqualTo(110_000); // 120.000 − 10% × 100.000
    }

    // ---- Rút tiền ----

    private void topUpLedger(long user, long amount) {
        jdbc.update("""
                INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after)
                VALUES ((SELECT id FROM wallets WHERE user_id = ?), 'TOP_UP', ?, 0, ?, 0)""", user, amount, amount);
    }

    private String withdrawJson(long amount) {
        return "{\"amount\":" + amount + ",\"bankName\":\"VCB\",\"accountNumber\":\"123456789\",\"accountHolder\":\"NGUOI RUT\"}";
    }

    @Test
    void freshTopUpCannotBeWithdrawnUntilTheHoldPasses() throws Exception {
        long me = createUser(Role.USER, "Người rút", 500_000);
        topUpLedger(me, 300_000);

        mvc.perform(get("/wallet/withdrawable").with(as(me, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.locked").value(300000))
                .andExpect(jsonPath("$.withdrawable").value(200000));
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content(withdrawJson(300_000)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TOPUP_LOCKED"));
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content(withdrawJson(200_000)))
                .andExpect(status().isCreated());
        assertThat(jdbc.queryForObject("SELECT topup_locked FROM withdraw_requests WHERE user_id = ?", Long.class, me)).isEqualTo(300_000);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = 'WITHDRAW.BLOCKED' AND target_id = ?",
                Long.class, String.valueOf(me))).isEqualTo(1);

        // Sau 25 giờ tiền nạp hết bị khoá.
        jdbc.update("UPDATE wallet_transactions SET created_at = now() - interval '25 hours' "
                + "WHERE type = 'TOP_UP' AND wallet_id = (SELECT id FROM wallets WHERE user_id = ?)", me);
        mvc.perform(get("/wallet/withdrawable").with(as(me, Role.USER)))
                .andExpect(jsonPath("$.locked").value(0))
                .andExpect(jsonPath("$.withdrawable").value(300000));
    }

    @Test
    void topUpThatWasAlreadySpentDoesNotStayLocked() throws Exception {
        long me = createUser(Role.USER, "Người đã tiêu", 500_000);
        topUpLedger(me, 300_000);
        jdbc.update("""
                INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after)
                VALUES ((SELECT id FROM wallets WHERE user_id = ?), 'PAYMENT', -300000, 0, 500000, 0)""", me);

        mvc.perform(get("/wallet/withdrawable").with(as(me, Role.USER)))
                .andExpect(jsonPath("$.locked").value(0))
                .andExpect(jsonPath("$.withdrawable").value(500000));
    }

    @Test
    void withdrawalsAreCappedPerDay() throws Exception {
        long me = createUser(Role.USER, "Người rút nhiều", 500_000);
        config.update("wallet.withdraw_daily_limit", "150000");
        try {
            mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                    .content(withdrawJson(100_000))).andExpect(status().isCreated());
            mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                            .content(withdrawJson(100_000)))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.code").value("WITHDRAW_DAILY_LIMIT"));
        } finally {
            config.update("wallet.withdraw_daily_limit", "20000000");
        }
    }

    // ---- Giao hàng và trả hàng tự động ----

    @Test
    void buyerCanConfirmReceiptWhileTheOrderIsStillShipping() throws Exception {
        setUpShop();
        long id = order("SHIPPING", "COD", "", "");
        mvc.perform(post("/orders/" + id + "/confirm-received").with(as(buyer, Role.USER))).andExpect(status().isOk());
        assertThat(orderStatus(id)).isEqualTo("COMPLETED");
        assertThat(auditCount("ORDER.DELIVERY.CONFIRMED", String.valueOf(id))).isEqualTo(1);
    }

    @Test
    void shippedOrderIsTreatedAsDeliveredAfterTheConfiguredDays() {
        setUpShop();
        // Đơn trả trước tự coi là đã giao; đơn COD thì không (tiền mặt chưa chắc đã thu): chờ Staff đối chiếu hãng vận chuyển.
        long late = order("SHIPPING", "WALLET", ", paid_at", ", now()");
        jdbc.update("UPDATE orders SET shipped_at = now() - interval '8 days' WHERE id = ?", late);
        long recent = order("SHIPPING", "WALLET", ", paid_at", ", now()");
        jdbc.update("UPDATE orders SET shipped_at = now() - interval '2 days' WHERE id = ?", recent);
        long codLate = order("SHIPPING", "COD", "", "");
        jdbc.update("UPDATE orders SET shipped_at = now() - interval '8 days' WHERE id = ?", codLate);

        jobs.run();

        assertThat(orderStatus(late)).isEqualTo("DELIVERED");
        assertThat(orderStatus(recent)).isEqualTo("SHIPPING");
        assertThat(orderStatus(codLate)).isEqualTo("SHIPPING");
    }

    @Test
    void returnExpiresWhenTheBuyerNeverShipsTheBookBack() {
        setUpShop();
        long id = order("RETURN_REQUESTED", "COD", "", "");
        jdbc.update("INSERT INTO return_requests (order_id, reason, description, status, approved_at) "
                + "VALUES (?, 'MISSING_PAGES', 'Thiếu trang', 'AWAITING_GOODS', now() - interval '8 days')", id);

        jobs.run();

        assertThat(returnStatus(id)).isEqualTo("EXPIRED");
        assertThat(orderStatus(id)).isEqualTo("COMPLETED");
    }

    @Test
    void returnGoesToAdminWhenTheShopNeverConfirmsTheGoods() {
        setUpShop();
        long id = order("RETURN_REQUESTED", "COD", "", "");
        jdbc.update("INSERT INTO return_requests (order_id, reason, description, status, approved_at, return_shipped_at) "
                + "VALUES (?, 'MISSING_PAGES', 'Thiếu trang', 'AWAITING_GOODS', now() - interval '10 days', now() - interval '8 days')", id);

        jobs.run();

        assertThat(returnStatus(id)).isEqualTo("DISPUTED");
        assertThat(orderStatus(id)).isEqualTo("RETURN_REQUESTED");
    }

    // ---- Sổ cái và đối soát ----

    @Test
    void everyLedgerRowLeavesAnAuditEventAndReconciliationFlagsDrift() throws Exception {
        setUpShop();
        long id = order("DELIVERED", "WALLET", ", paid_at", ", now()");
        jdbc.update("UPDATE wallets SET held_balance = 120000 WHERE user_id = ?", shopOwner);
        mvc.perform(post("/orders/" + id + "/confirm-received").with(as(buyer, Role.USER))).andExpect(status().isOk());

        long walletId = jdbc.queryForObject("SELECT id FROM wallets WHERE user_id = ?", Long.class, shopOwner);
        long ledgerRows = jdbc.queryForObject("SELECT count(*) FROM wallet_transactions WHERE wallet_id = ?", Long.class, walletId);
        assertThat(ledgerRows).isGreaterThan(0);
        assertThat(auditCount("WALLET.TX.POSTED", String.valueOf(walletId))).isEqualTo(ledgerRows);

        // Ví của shop này có held 120.000 nạp thẳng bằng SQL, không có dòng sổ cái: phải bị báo lệch.
        reconciliation.reconcile();
        assertThat(auditCount("RECONCILE.MISMATCH", String.valueOf(walletId))).isGreaterThan(0);
    }
}
