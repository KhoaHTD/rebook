package com.rebook.journey;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Luật nghiệp vụ đợt 2026-11-06 (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần C): chặn giá ≤ 0 (BR-4.6, BR-5.5), lịch tối thiểu và chốt
 * điều khoản lúc công bố (BR-5.1–5.3), ISBN làm tin duyệt lại (BR-2.5), sự cố kho và bồi thường (BR-4.2, BR-4.8, BR-4.9).
 */
class BusinessRulesBatchTest extends JourneySupport {

    private int status(Res r) {
        return r.status();
    }

    private long receivedConsignment(Actor seller, Actor staff, long expected) throws Exception {
        long c = newConsignment(seller, expected);
        expect(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 200);
        Instant at = Instant.now().plus(2, ChronoUnit.DAYS).atZone(VN).withHour(10).withMinute(0).withSecond(0).toInstant();
        expect(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", at.toString())), 200);
        expect(post(staff, "/staff/consignments/" + c + "/check-in", Map.of("shelfCode", "A1", "photoUrls", List.of("/files/in.png"))), 200);
        return c;
    }

    private long warehouseOf(long consignment) {
        return jdbc.queryForObject("SELECT id FROM warehouse_items WHERE consignment_id = ?", Long.class, consignment);
    }

    private long consignmentOf(long lot) {
        return jdbc.queryForObject("SELECT consignment_id FROM lots WHERE id = ?", Long.class, lot);
    }

    private void fundPlatform(long amount) {
        jdbc.update("UPDATE wallets SET available_balance = available_balance + ? WHERE user_id IS NULL", amount);
    }

    private String col(String table, String column, long id) {
        return jdbc.queryForObject("SELECT " + column + "::text FROM " + table + " WHERE id = ?", String.class, id);
    }

    // ---- BR-4.6, BR-5.5: giá ≤ 0 ----

    @Test
    void inspectionPricesAndSessionDepositMustBePositive() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long c = receivedConsignment(seller, staff, 500_000);
        Res bad = post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 0, 0));
        assertThat(status(bad)).isEqualTo(400);
        assertThat(bad.text("code")).isEqualTo("INVALID_PRICE");
        assertThat(col("consignments", "status", c)).as("Staff lập lại phiếu được").isEqualTo("RECEIVED");
        expect(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 200_000, 300_000)), 200);

        assertThat(status(post(admin, "/admin/sessions", sessionBody("Cọc 0", 0, 2)))).isEqualTo(400);
    }

    // ---- BR-5.1–5.3: lịch tối thiểu, chốt điều khoản ----

    @Test
    void publishNeedsLeadTimeAndFreezesTheTerms() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long s = expect(post(admin, "/admin/sessions", sessionBody("Phiên lịch", 100_000, 2)), 201).id();
        expect(put(admin, "/admin/sessions/" + s + "/lots", Map.of("lotIds", List.of(lot))), 200);

        jdbc.update("UPDATE auction_sessions SET start_at = now() + interval '2 days', registration_deadline = now() + interval '1 day' WHERE id = ?", s);
        Res tooSoon = post(admin, "/admin/sessions/" + s + "/publish", null);
        assertThat(status(tooSoon)).as("mở sau 48 giờ < 72 giờ").isEqualTo(400);
        jdbc.update("UPDATE auction_sessions SET start_at = now() + interval '10 days', registration_deadline = now() + interval '10 days' - interval '12 hours' WHERE id = ?", s);
        assertThat(status(post(admin, "/admin/sessions/" + s + "/publish", null))).as("hạn đăng ký 12 giờ trước giờ mở").isEqualTo(400);
        jdbc.update("UPDATE auction_sessions SET registration_deadline = now() + interval '8 days' WHERE id = ?", s);
        expect(post(admin, "/admin/sessions/" + s + "/publish", null), 200);

        Map<String, Object> terms = jdbc.queryForMap(
                "SELECT buyer_premium_percent::int AS p, bid_increment_tiers AS t, bid_limit_multiplier AS m FROM auction_sessions WHERE id = ?", s);
        assertThat(terms.get("p")).isEqualTo(10);
        assertThat((String) terms.get("t")).startsWith("0:10000");
        assertThat(terms.get("m")).isEqualTo(10);
    }

    // ---- BR-2.5: đổi ấn bản thì duyệt lại; ISBN cũ giữ nguyên không bị kiểm lại ----

    @Test
    void changingIsbnPublisherOrYearSendsTheListingBackToReview() throws Exception {
        Actor seller = user("Shop", 0);
        openShop(seller, false);
        Map<String, Object> book = new HashMap<>(book("Sách ISBN " + UUID.randomUUID()));
        book.put("isbn", "978-0-306-40615-7");
        book.put("publishYear", 1998);
        long listing = expect(post(seller, "/seller/listings", Map.of("book", book, "price", 80_000, "stock", 1)), 201).id();
        jdbc.update("UPDATE listings SET status = 'ACTIVE' WHERE id = ?", listing);

        book.put("publishYear", 1999);
        expect(put(seller, "/seller/listings/" + listing, Map.of("book", book, "price", 80_000, "stock", 1)), 200);
        assertThat(listingStatus(listing)).isEqualTo("PENDING_REVIEW");

        // Dữ liệu cũ có ISBN sai số kiểm tra: sửa giá mà giữ nguyên ISBN vẫn được, tin không phải duyệt lại
        jdbc.update("UPDATE listings SET status = 'ACTIVE' WHERE id = ?", listing);
        jdbc.update("UPDATE books SET isbn = '9786042011237' WHERE id = (SELECT book_id FROM listings WHERE id = ?)", listing);
        book.put("isbn", "9786042011237");
        expect(put(seller, "/seller/listings/" + listing, Map.of("book", book, "price", 90_000, "stock", 1)), 200);
        assertThat(listingStatus(listing)).isEqualTo("ACTIVE");
    }

    // ---- BR-4.2, BR-4.8, BR-4.9: sự cố kho ----

    @Test
    void lostAfterInspectionPaysTheLowEstimate() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long c = consignmentOf(lot);
        long w = warehouseOf(c);
        fundPlatform(1_000_000);

        long incident = expect(post(staff, "/staff/warehouse/" + w + "/incidents",
                Map.of("type", "LOST", "description", "Thất lạc khi chuyển kệ")), 201).id();
        assertThat(post(staff, "/staff/warehouse/" + w + "/incidents", Map.of("type", "LOST", "description", "Lần hai")).text("code"))
                .isEqualTo("INCIDENT_PENDING");
        assertThat(status(post(staff, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()))).as("Staff không duyệt được").isEqualTo(403);

        Res ok = expect(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()), 200);
        assertThat(ok.text("stage")).isEqualTo("INSPECTED");
        assertThat(ok.body().path("sellerAmount").asLong()).isEqualTo(400_000);
        assertThat(walletAvailable(seller.id())).isEqualTo(400_000);
        assertThat(col("lots", "status", lot)).isEqualTo("LOST");
        assertThat(col("warehouse_items", "status", w)).isEqualTo("LOST");
        assertThat(col("consignments", "status", c)).isEqualTo("LOST");
        assertThat(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()).text("code")).isEqualTo("INCIDENT_DECIDED");
    }

    @Test
    void damagedBeforeInspectionPaysAPercentOfTheCappedPriceAndWaivesStorage() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long c = receivedConsignment(seller, staff, 3_000_000);
        long w = warehouseOf(c);
        fundPlatform(2_000_000);

        long incident = expect(post(staff, "/staff/warehouse/" + w + "/incidents",
                Map.of("type", "DAMAGED", "description", "Ướt góc bìa do dột mái", "photoUrls", List.of("/files/wet.png"))), 201).id();
        assertThat(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()).text("code"))
                .isEqualTo("SELLER_PERCENT_REQUIRED");
        Res ok = expect(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of("sellerPercent", 50)), 200);
        assertThat(ok.text("stage")).isEqualTo("UNINSPECTED");
        assertThat(walletAvailable(seller.id())).as("min(3.000.000; trần 2.000.000) × 50%").isEqualTo(1_000_000);
        assertThat(col("consignments", "status", c)).isEqualTo("WITHDRAWN");

        // Người bán đến nhận sau 40 ngày: không tính phí lưu kho
        jdbc.update("UPDATE warehouse_items SET return_notified_at = now() - interval '40 days' WHERE id = ?", w);
        expect(post(staff, "/staff/warehouse/" + w + "/return", null), 200);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM account_debts WHERE user_id = ?", Long.class, seller.id())).isZero();
        assertThat(walletAvailable(seller.id())).isEqualTo(1_000_000);
        assertThat(col("consignments", "status", c)).isEqualTo("RETURNED");
    }

    @Test
    void lostAfterTheWinnerPaidRefundsTheBuyerWithABonusAndPaysTheSeller() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor buyer = user("Người thắng", 0);
        long lot = consignToReadyLot(seller, staff, 500_000, 800_000, 1_200_000, 500_000, 700_000);
        long w = warehouseOf(consignmentOf(lot));
        jdbc.update("UPDATE lots SET status = 'PAID', hammer_price = 1000000, winner_id = ? WHERE id = ?", buyer.id(), lot);
        jdbc.update("UPDATE warehouse_items SET status = 'RESERVED' WHERE id = ?", w);
        jdbc.update("UPDATE wallets SET held_balance = 1000000 WHERE user_id = ?", seller.id());
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, lot_id, order_type, status, subtotal, buyer_premium, shipping_fee, total,
                                    pickup_at_warehouse, payment_method, paid_at)
                VALUES (?, ?, ?, 'AUCTION', 'PENDING_CONFIRM', 1000000, 100000, 0, 1100000, TRUE, 'WALLET', now()) RETURNING id""",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer.id(), lot);
        fundPlatform(2_000_000);

        long incident = expect(post(staff, "/staff/warehouse/" + w + "/incidents", Map.of("type", "LOST", "description", "Mất khi đóng gói")), 201).id();
        Res ok = expect(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()), 200);

        assertThat(ok.text("stage")).isEqualTo("SOLD_PAID");
        assertThat(walletAvailable(buyer.id())).as("hoàn 1.100.000 + bồi thường 10% giá búa").isEqualTo(1_200_000);
        assertThat(walletHeld(seller.id())).isZero();
        assertThat(walletAvailable(seller.id())).as("giá búa − 15% hoa hồng").isEqualTo(850_000);
        assertThat(col("orders", "status", order)).isEqualTo("CANCELLED");
        assertThat(col("lots", "status", lot)).isEqualTo("LOST");
    }

    @Test
    void lostAfterFailedInspectionNeedsAnAdminChosenPercent() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long c = receivedConsignment(seller, staff, 2_000_000);
        expect(post(staff, "/staff/consignments/" + c + "/inspection",
                Map.of("result", "FAIL", "conditionReport", "Thiếu 20 trang, nghi bản in lậu")), 200);
        long w = warehouseOf(c);
        fundPlatform(1_000_000);
        long incident = expect(post(staff, "/staff/warehouse/" + w + "/incidents", Map.of("type", "LOST", "description", "Thất lạc")), 201).id();

        assertThat(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()).text("code"))
                .as("không tự trả theo giá người bán tự khai").isEqualTo("SELLER_PERCENT_REQUIRED");
        expect(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of("sellerPercent", 10)), 200);
        assertThat(walletAvailable(seller.id())).isEqualTo(200_000);
        assertThat(col("consignments", "status", c)).isEqualTo("LOST");
    }

    @Test
    void lostBookOfALotConvertedToAListingRejectsThePendingListing() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        openShop(seller, false);
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long c = consignmentOf(lot);
        jdbc.update("UPDATE lots SET status = 'UNSOLD' WHERE id = ?", lot);
        expect(post(seller, "/consignments/" + c + "/unsold-decision", Map.of("action", "CONVERT_TO_LISTING", "listingPrice", 350_000)), 200);
        long listing = jdbc.queryForObject("SELECT l.id FROM listings l JOIN consignments c ON c.book_id = l.book_id WHERE c.id = ?", Long.class, c);
        fundPlatform(1_000_000);

        long incident = expect(post(staff, "/staff/warehouse/" + warehouseOf(c) + "/incidents",
                Map.of("type", "LOST", "description", "Thất lạc")), 201).id();
        expect(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()), 200);

        assertThat(listingStatus(listing)).isEqualTo("REJECTED");
        assertThat(walletAvailable(seller.id())).isEqualTo(400_000);
    }

    @Test
    void approvalNeedsPlatformFundsAndRejectNeedsAReason() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        long platform = jdbc.queryForObject("SELECT available_balance::bigint FROM wallets WHERE user_id IS NULL", Long.class);
        long huge = platform + 5_000_000;
        long lot = consignToReadyLot(seller, staff, 500_000, huge, huge, 200_000, 300_000);
        long w = warehouseOf(consignmentOf(lot));
        long incident = expect(post(staff, "/staff/warehouse/" + w + "/incidents", Map.of("type", "LOST", "description", "Thất lạc")), 201).id();

        assertThat(post(admin, "/admin/warehouse-incidents/" + incident + "/approve", Map.of()).text("code"))
                .isEqualTo("PLATFORM_FUNDS_INSUFFICIENT");
        assertThat(col("warehouse_incidents", "status", incident)).isEqualTo("PENDING");
        assertThat(walletAvailable(seller.id())).isZero();

        assertThat(status(post(admin, "/admin/warehouse-incidents/" + incident + "/reject", Map.of()))).isEqualTo(400);
        expect(post(admin, "/admin/warehouse-incidents/" + incident + "/reject", Map.of("reason", "Đã tìm thấy sách ở kệ B2")), 200);
        assertThat(col("warehouse_incidents", "status", incident)).isEqualTo("REJECTED");
        assertThat(col("lots", "status", lot)).isEqualTo("READY");
    }
}
