package com.rebook.journey;

import com.rebook.auction.AuctionRunner;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/** Ca ngắn: dữ liệu sai, sai quyền, sai trạng thái (docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần B mục B). */
class JourneyEdgeCasesTest extends JourneySupport {

    @Autowired
    AuctionRunner runner;

    private void status(Res r, int... allowed) {
        assertThat(r.status()).as(r.body().toString()).isIn(java.util.Arrays.stream(allowed).boxed().toArray());
    }

    // ---------------------------------------------------------------- Số tiền

    @Test
    void walletAmountsMustBeWholeAndInRange() throws Exception {
        Actor u = user("Người dùng", 0);
        status(post(u, "/wallet/top-up", Map.of("amount", 9_999)), 400);
        status(post(u, "/wallet/top-up", "{\"amount\":10000.5}"), 400);
        status(post(u, "/wallet/top-up", "{\"amount\":10000000000000000}"), 400);
        status(post(u, "/wallet/top-up", "{\"amount\":-50000}"), 400);
        status(post(u, "/wallet/top-up", "{}"), 400);
        status(post(u, "/wallet/top-up", "{\"amount\":\"abc\"}"), 400);
        status(post(u, "/wallet/top-up", "{\"amount\":50000.0}"), 201); // frontend có thể gửi dạng này
    }

    @Test
    void bidAndProxyAmountsMustBeWhole() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b = user("Người trả giá", 0);
        topUp(b, 1_000_000);
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 1, lot);
        status(post(b, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 200, 201);
        expect(post(admin, "/admin/sessions/" + session + "/start", null), 200);
        runner.tick(session);

        status(post(b, "/lots/" + lot + "/bids", "{\"amount\":200000.4}"), 400);
        status(put(b, "/lots/" + lot + "/proxy-bid", "{\"maxAmount\":300000.7}"), 400);
        status(post(b, "/sessions/" + session + "/deposit", "{\"amount\":10000.5}"), 400);
        assertThat(jdbc.queryForObject("SELECT bid_count FROM lots WHERE id = ?", Integer.class, lot)).isZero();
        status(post(b, "/lots/" + lot + "/bids", "{\"amount\":200000.0}"), 200);
        assertThat(jdbc.queryForObject("SELECT current_price::bigint FROM lots WHERE id = ?", Long.class, lot)).isEqualTo(200_000);
    }

    @Test
    void listingAndConsignmentPricesMustBeWhole() throws Exception {
        Actor seller = user("Người bán", 0);
        openShop(seller, true);
        status(post(seller, "/seller/listings", "{\"book\":" + om.writeValueAsString(book("A")) + ",\"price\":1500.5,\"stock\":1}"), 400);
        status(post(seller, "/consignments", "{\"book\":" + om.writeValueAsString(book("B")) + ",\"expectedPrice\":400000.5}"), 400);
    }

    @Test
    void paymentSimulationCannotBeAbusedAndWithdrawalsAreChecked() throws Exception {
        Actor a = user("A", 0);
        Actor b = user("B", 0);
        Res p = expect(post(a, "/wallet/top-up", Map.of("amount", 100_000)), 201);
        status(post(b, "/payments/" + p.text("code") + "/simulate", null), 403);
        status(post(a, "/payments/" + p.text("code") + "/simulate", null), 200);
        status(post(a, "/payments/" + p.text("code") + "/simulate", null), 409);
        assertThat(walletAvailable(a.id())).as("chỉ cộng một lần").isEqualTo(100_000);

        Map<String, Object> w = Map.of("amount", 60_000, "bankName", "VCB", "accountNumber", "0123456789", "accountHolder", "A");
        status(post(a, "/wallet/withdrawals", Map.of("amount", 40_000, "bankName", "VCB", "accountNumber", "0123456789", "accountHolder", "A")), 400);
        status(post(a, "/wallet/withdrawals", Map.of("amount", 60_000, "bankName", "VCB", "accountNumber", "12", "accountHolder", "A")), 400);
        Res tooMuch = post(a, "/wallet/withdrawals", Map.of("amount", 500_000, "bankName", "VCB", "accountNumber", "0123456789", "accountHolder", "A"));
        assertThat(tooMuch.status()).isBetween(400, 409);
        assertThat(walletAvailable(a.id())).as("rút quá số dư không đổi ví").isEqualTo(100_000);
        Res fresh = post(a, "/wallet/withdrawals", w);
        assertThat(fresh.status()).as("tiền vừa nạp chưa rút ngay được").isBetween(400, 409);
        assertThat(walletAvailable(a.id())).isEqualTo(100_000);
    }

    // ---------------------------------------------------------------- Tin đăng

    @Test
    void listingValidationAndVisibility() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor other = user("Người khác", 0);
        Actor buyer = user("Người mua", 0);
        Actor admin = admin();
        openShop(seller, false);
        openShop(other, false);

        Map<String, Object> two = Map.of("title", "T", "author", "A", "categoryId", category(), "conditionGrade", "GOOD", "weightGram", 100,
                "imageUrls", List.of("/files/a.png", "/files/b.png"));
        status(post(seller, "/seller/listings", Map.of("book", two, "price", 50_000, "stock", 1)), 400);
        status(post(seller, "/seller/listings", Map.of("book", book("X"), "price", 999, "stock", 1)), 400);
        status(post(seller, "/seller/listings", Map.of("book", book("X"), "price", 50_000, "stock", -1)), 400);
        status(post(null, "/seller/listings", Map.of("book", book("X"), "price", 50_000, "stock", 1)), 401, 403);

        long listing = createListing(seller, 50_000, 1);
        assertThat(listingStatus(listing)).isEqualTo("PENDING_REVIEW");
        status(get(buyer, "/listings/" + listing), 404);
        Res list = get(buyer, "/listings?size=100");
        List<Long> visible = new java.util.ArrayList<>();
        list.body().path("items").forEach(i -> visible.add(i.path("id").asLong()));
        assertThat(visible).as("tin chờ duyệt không hiện trong danh sách công khai").doesNotContain(listing);

        status(post(buyer, "/admin/listings/" + listing + "/approve", null), 403);
        status(post(seller, "/admin/listings/" + listing + "/approve", null), 403);
        status(post(admin, "/admin/listings/" + listing + "/reject", Map.of("reason", " ")), 400);
        status(put(other, "/seller/listings/" + listing + "/stock", Map.of("stock", 99)), 403, 404);
        status(delete(other, "/seller/listings/" + listing), 403, 404);

        expect(post(admin, "/admin/listings/" + listing + "/reject", Map.of("reason", "Ảnh mờ")), 200);
        assertThat(listingStatus(listing)).isEqualTo("REJECTED");
        status(post(admin, "/admin/listings/" + listing + "/approve", null), 409);
    }

    // ---------------------------------------------------------------- Giỏ và đặt hàng

    @Test
    void cartAndCheckoutRules() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor seller2 = user("Người bán 2", 0);
        Actor buyer = user("Người mua", 0);
        openShop(seller, true);
        openShop(seller2, true);
        long l1 = createListing(seller, 80_000, 1);
        long l2 = createListing(seller2, 90_000, 5);
        long addr = address(buyer);

        status(post(buyer, "/orders/checkout", Map.of("addressId", addr, "paymentMethod", "WALLET")), 400, 409);
        status(post(buyer, "/cart", Map.of("listingId", l1, "quantity", 2)), 409, 400);
        status(post(buyer, "/cart", Map.of("listingId", l1, "quantity", 0)), 400);
        status(post(seller, "/cart", Map.of("listingId", l1, "quantity", 1)), 409, 403, 400);

        status(post(buyer, "/cart", Map.of("listingId", l1, "quantity", 1)), 200);
        status(post(buyer, "/cart", Map.of("listingId", l2, "quantity", 1)), 200);
        Res poor = post(buyer, "/orders/checkout", Map.of("addressId", addr, "paymentMethod", "WALLET"));
        assertThat(poor.status()).as("ví không đủ: " + poor.body()).isBetween(400, 409);
        assertThat(stock(l1)).as("đặt hỏng không được giữ hàng").isEqualTo(1);

        topUp(buyer, 500_000);
        Res ok = post(buyer, "/orders/checkout", Map.of("addressId", addr, "paymentMethod", "WALLET"));
        status(ok, 201);
        assertThat(ok.body().path("orders")).as("hai shop thì hai đơn").hasSize(2);
        assertThat(stock(l1)).isZero();
        assertThat(listingStatus(l1)).as("hết hàng").isEqualTo("OUT_OF_STOCK");
        long sum = 0;
        for (var o : ok.body().path("orders")) {
            sum += total(o.path("id").asLong());
        }
        assertThat(walletAvailable(buyer.id())).isEqualTo(500_000 - sum);
        status(post(buyer, "/orders/checkout", Map.of("addressId", 99_999_999, "paymentMethod", "WALLET")), 400, 404, 409);
    }

    @Test
    void ordersAreProtectedAndFollowTheStatusFlow() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor shop2 = user("Shop khác", 0);
        Actor buyer = user("Người mua", 0);
        Actor stranger = user("Người lạ", 0);
        Actor admin = admin();
        openShop(seller, true);
        openShop(shop2, true);
        topUp(buyer, 400_000);
        long listing = createListing(seller, 100_000, 1);
        long order = buy(buyer, listing, 1, "WALLET", address(buyer));

        status(get(stranger, "/orders/" + order), 403, 404);
        status(post(stranger, "/orders/" + order + "/cancel", Map.of("reason", "x")), 403, 404);
        status(post(shop2, "/seller/orders/" + order + "/confirm", null), 403, 404);
        status(post(seller, "/seller/orders/" + order + "/ship", Map.of("trackingCode", "T")), 409);
        status(post(seller, "/seller/orders/" + order + "/delivered", null), 409);
        status(post(buyer, "/orders/" + order + "/confirm-received", null), 409);
        status(post(buyer, "/orders/" + order + "/review", Map.of("rating", 5)), 409);
        status(post(buyer, "/orders/" + order + "/return", Map.of("reason", "WRONG_CONDITION", "description", "x", "images", List.of("/files/x.png"))), 409);
        status(post(buyer, "/seller/orders/" + order + "/confirm", null), 403, 404);
        status(post(buyer, "/admin/disputes/" + order + "/resolve", Map.of("approve", true)), 403);
        status(post(admin, "/seller/orders/" + order + "/confirm", null), 403, 404);

        expect(post(seller, "/seller/orders/" + order + "/confirm", null), 200);
        status(post(seller, "/seller/orders/" + order + "/confirm", null), 409);
    }

    @Test
    void returnRequestIsValidatedAndOnlyAllowedOnce() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        openShop(seller, true);
        topUp(buyer, 400_000);
        long listing = createListing(seller, 100_000, 1);
        long order = buy(buyer, listing, 1, "WALLET", address(buyer));
        expect(post(seller, "/seller/orders/" + order + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + order + "/ship", Map.of("trackingCode", "T1")), 200);
        expect(post(seller, "/seller/orders/" + order + "/delivered", null), 200);

        status(post(buyer, "/orders/" + order + "/return", Map.of("reason", "CHANGED_MIND", "description", "x", "images", List.of("/files/x.png"))), 400);
        status(post(buyer, "/orders/" + order + "/return", Map.of("reason", "WRONG_CONDITION", "description", "", "images", List.of("/files/x.png"))), 400);
        status(post(buyer, "/orders/" + order + "/return", Map.of("reason", "WRONG_CONDITION", "description", "Rách", "images", List.of())), 400);
        expect(post(buyer, "/orders/" + order + "/return", Map.of("reason", "WRONG_CONDITION", "description", "Rách", "images", List.of("/files/x.png"))), 200);
        status(post(buyer, "/orders/" + order + "/return", Map.of("reason", "WRONG_CONDITION", "description", "Rách", "images", List.of("/files/x.png"))), 409);

        // Quá hạn khiếu nại
        long listing2 = createListing(seller, 100_000, 1);
        long order2 = buy(buyer, listing2, 1, "WALLET", address(buyer));
        expect(post(seller, "/seller/orders/" + order2 + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + order2 + "/ship", Map.of("trackingCode", "T2")), 200);
        expect(post(seller, "/seller/orders/" + order2 + "/delivered", null), 200);
        jdbc.update("UPDATE orders SET delivered_at = now() - interval '10 days' WHERE id = ?", order2);
        status(post(buyer, "/orders/" + order2 + "/return", Map.of("reason", "WRONG_CONDITION", "description", "Rách", "images", List.of("/files/x.png"))), 409);
    }

    // ---------------------------------------------------------------- Ký gửi

    @Test
    void consignmentGuards() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor other = user("Người khác", 0);
        Actor staff = staff();
        status(post(seller, "/consignments", Map.of("book", book("Rẻ"), "expectedPrice", 100_000)), 400);
        jdbc.update("UPDATE users SET email_verified = FALSE WHERE id = ?", other.id());
        status(post(other, "/consignments", Map.of("book", book("Chưa xác thực"), "expectedPrice", 500_000)), 403);

        long c = newConsignment(seller, 500_000);
        status(get(other, "/consignments/" + c), 403, 404);
        status(post(other, "/consignments/" + c + "/withdraw", null), 403, 404);
        status(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", Instant.now().plus(2, ChronoUnit.DAYS).toString())), 409);
        status(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 200_000, 300_000)), 409);
        status(post(seller, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 403);
        status(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", false)), 400);

        expect(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 200);
        Instant night = Instant.now().plus(2, ChronoUnit.DAYS).atZone(VN).withHour(20).withMinute(0).toInstant();
        status(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", night.toString())), 400);
        status(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", Instant.now().plus(30, ChronoUnit.DAYS).atZone(VN).withHour(10).toInstant().toString())), 400);
        status(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", Instant.now().minus(1, ChronoUnit.DAYS).toString())), 400);
        status(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 200_000, 300_000)), 409);
    }

    @Test
    void inspectionPricingAndSellerDecisionRules() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        long c = newConsignment(seller, 500_000);
        expect(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 200);
        Instant at = Instant.now().plus(2, ChronoUnit.DAYS).atZone(VN).withHour(10).toInstant();
        expect(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", at.toString())), 200);
        expect(post(staff, "/staff/consignments/" + c + "/check-in", Map.of("shelfCode", "B2")), 200);

        status(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 200_000, 450_000)), 400); // sàn > ước tính thấp
        status(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(600_000, 400_000, 200_000, 300_000)), 400); // thấp > cao
        status(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 350_000, 300_000)), 400); // khởi điểm > sàn
        status(post(staff, "/staff/consignments/" + c + "/inspection",
                Map.of("result", "PASS", "conditionReport", "ổn", "conditionGrade", "GOOD")), 400); // thiếu giá
        expect(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 200_000, 300_000)), 200);

        status(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", false)), 400);
        status(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true, "counterReserve", 450_000)), 400);
        status(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true, "counterReserve", 150_000)), 400);
        expect(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true, "counterReserve", 350_000)), 200);
        assertThat(jdbc.queryForObject("SELECT reserve_price::bigint FROM lots WHERE consignment_id = ?", Long.class, c)).isEqualTo(350_000);
        status(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true)), 409);
        status(post(seller, "/consignments/" + c + "/withdraw", null), 409);
    }

    @Test
    void failedInspectionNeverBecomesALot() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long c = newConsignment(seller, 500_000);
        expect(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 200);
        Instant at = Instant.now().plus(2, ChronoUnit.DAYS).atZone(VN).withHour(10).toInstant();
        expect(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", at.toString())), 200);
        expect(post(staff, "/staff/consignments/" + c + "/check-in", Map.of("shelfCode", "C3")), 200);
        expect(post(staff, "/staff/consignments/" + c + "/inspection",
                Map.of("result", "FAIL", "conditionReport", "Sách giả", "conditionGrade", "ACCEPTABLE")), 200);

        assertThat(jdbc.queryForObject("SELECT status FROM consignments WHERE id = ?", String.class, c)).isEqualTo("INSPECTION_FAILED");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM lots WHERE consignment_id = ?", Long.class, c)).isZero();
        status(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true)), 409);
        status(get(admin, "/admin/lots/ready"), 200);
    }

    // ---------------------------------------------------------------- Phiên đấu giá

    @Test
    void sessionSchedulingRules() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b = user("Người mua", 0);
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);

        long s = expect(post(admin, "/admin/sessions", sessionBody("Phiên A", 100_000, 2)), 201).id();
        status(post(admin, "/admin/sessions/" + s + "/publish", null), 400); // chưa có lô
        status(put(admin, "/admin/sessions/" + s + "/lots", Map.of("lotIds", List.of(lot, lot))), 400);
        status(put(admin, "/admin/sessions/" + s + "/lots", Map.of("lotIds", List.of(99_999_999L))), 404, 409);
        status(put(b, "/admin/sessions/" + s + "/lots", Map.of("lotIds", List.of(lot))), 403);
        expect(put(admin, "/admin/sessions/" + s + "/lots", Map.of("lotIds", List.of(lot))), 200);

        long s2 = expect(post(admin, "/admin/sessions", sessionBody("Phiên B", 100_000, 2)), 201).id();
        status(put(admin, "/admin/sessions/" + s2 + "/lots", Map.of("lotIds", List.of(lot))), 409); // lô đã xếp phiên khác

        jdbc.update("UPDATE auction_sessions SET registration_deadline = now() - interval '2 day', start_at = now() - interval '1 day' WHERE id = ?", s);
        status(post(admin, "/admin/sessions/" + s + "/publish", null), 400); // giờ ở quá khứ
        jdbc.update("UPDATE auction_sessions SET start_at = now() + interval '10 days', registration_deadline = now() + interval '8 days' WHERE id = ?", s);
        expect(post(admin, "/admin/sessions/" + s + "/publish", null), 200);
        status(put(admin, "/admin/sessions/" + s, sessionBody("Sửa", 100_000, 2)), 409); // phiên đã công bố
        status(put(admin, "/admin/sessions/" + s + "/lots", Map.of("lotIds", List.of(lot))), 409);
    }

    @Test
    void registrationRules() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 2, lot);

        Actor noPhone = user("Chưa xác thực SĐT", 500_000);
        jdbc.update("UPDATE users SET phone_verified = FALSE WHERE id = ?", noPhone.id());
        status(post(noPhone, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 403);

        Actor poor = user("Ví không đủ", 50_000);
        status(post(poor, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 400, 409);
        assertThat(walletHeld(poor.id())).isZero();

        Actor ok = user("Đủ điều kiện", 500_000);
        status(post(ok, "/sessions/" + session + "/register", Map.of("agreeRules", false)), 400);
        status(post(ok, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 200, 201);
        status(post(ok, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 409);
        assertThat(walletHeld(ok.id())).as("chỉ khoá cọc một lần").isEqualTo(100_000);

        status(post(seller, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 403, 409, 400);

        status(post(admin, "/admin/sessions/" + session + "/start", null), 409); // 1 người, cần 2
        Actor late = user("Đăng ký muộn", 500_000);
        jdbc.update("UPDATE auction_sessions SET registration_deadline = now() - interval '1 minute' WHERE id = ?", session);
        status(post(late, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 409);
    }

    @Test
    void biddingNeedsARegistrationAndALiveSession() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor reg = user("Đã đăng ký", 0);
        Actor outsider = user("Chưa đăng ký", 500_000);
        topUp(reg, 500_000);
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 1, lot);
        status(post(reg, "/sessions/" + session + "/register", Map.of("agreeRules", true)), 200, 201);

        status(post(reg, "/lots/" + lot + "/bids", Map.of("amount", 200_000)), 409); // phiên chưa diễn ra
        expect(post(admin, "/admin/sessions/" + session + "/start", null), 200);
        runner.tick(session);
        status(post(outsider, "/lots/" + lot + "/bids", Map.of("amount", 200_000)), 403);
        status(post(null, "/lots/" + lot + "/bids", Map.of("amount", 200_000)), 401, 403);
        status(post(reg, "/lots/" + lot + "/bids", Map.of("amount", 150_000)), 409); // dưới giá khởi điểm
        status(post(reg, "/lots/" + lot + "/bids", Map.of("amount", 200_000)), 200);
        status(post(reg, "/lots/" + lot + "/bids", Map.of("amount", 300_000)), 409); // đang dẫn đầu

        status(post(reg, "/staff/sessions/" + session + "/pause", null), 403); // USER không tạm dừng phiên
        expect(post(staff, "/staff/sessions/" + session + "/pause", null), 200);
        status(post(reg, "/lots/" + lot + "/bids", Map.of("amount", 400_000)), 409);
        expect(post(staff, "/staff/sessions/" + session + "/resume", null), 200);
    }

    // ---------------------------------------------------------------- Bảo mật

    @Test
    void protectedEndpointsNeedLoginAndTheRightRole() throws Exception {
        Actor u = user("Người dùng", 0);
        for (String url : List.of("/wallet", "/orders", "/cart", "/me", "/consignments", "/me/registrations", "/wallet/transactions")) {
            status(call(HttpMethod.GET, url, null, null), 401, 403);
        }
        for (String url : List.of("/admin/sessions", "/admin/listings/pending", "/admin/disputes", "/admin/cod/pending")) {
            status(get(u, url), 403);
        }
        for (String url : List.of("/staff/consignments", "/staff/orders", "/staff/orders/in-transit", "/staff/warehouse")) {
            status(get(u, url), 403);
        }
        status(get(staff(), "/admin/sessions"), 403);
        status(get(admin(), "/staff/consignments"), 200);
    }
}
