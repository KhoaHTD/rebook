package com.rebook.journey;

import com.rebook.auction.AuctionRunner;
import com.rebook.auction.AuctionSettlement;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/** Các câu chuyện đi hết một vòng đời, từ nạp tiền tới nhận tiền, kiểm bảo toàn tiền ở cuối (docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần B mục A). */
class FullJourneyTest extends JourneySupport {

    @Autowired
    AuctionRunner runner;
    @Autowired
    AuctionSettlement settlement;

    private long subtotal(long order) {
        return jdbc.queryForObject("SELECT subtotal FROM orders WHERE id = ?", Long.class, order);
    }

    /** Shop tự giao nên nhận cả phí ship; sàn chỉ thu phí trên tiền sách (OrderSettlement). */
    private long sellerNet(long order) {
        return jdbc.queryForObject("SELECT subtotal + shipping_fee - round(subtotal * fee_percent / 100) FROM orders WHERE id = ?", Long.class, order);
    }

    private long fee(long order) {
        return jdbc.queryForObject("SELECT round(subtotal * fee_percent / 100) FROM orders WHERE id = ?", Long.class, order);
    }

    /** Một đơn mua thường bằng ví tới trạng thái DELIVERED. */
    private long deliveredOrder(Actor seller, Actor buyer, long listing, long addr) throws Exception {
        long order = buy(buyer, listing, 1, "WALLET", addr);
        expect(post(seller, "/seller/orders/" + order + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + order + "/ship", Map.of("trackingCode", "VN" + order)), 200);
        expect(post(seller, "/seller/orders/" + order + "/delivered", null), 200);
        assertThat(orderStatus(order)).isEqualTo("DELIVERED");
        return order;
    }

    // ---------------------------------------------------------------- S1

    @Test
    void s1_topUpListApproveBuyDeliverComplete() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        Actor admin = admin();
        openShop(seller, false);
        long start = totalMoney(seller, buyer);

        topUp(buyer, 500_000);
        assertThat(walletAvailable(buyer.id())).isEqualTo(500_000);

        long listing = createListing(seller, 120_000, 2);
        assertThat(listingStatus(listing)).as("shop mới: tin chờ duyệt").isEqualTo("PENDING_REVIEW");
        assertThat(get(buyer, "/listings/" + listing).status()).as("người mua chưa thấy tin chờ duyệt").isEqualTo(404);
        expect(post(admin, "/admin/listings/" + listing + "/approve", null), 200);
        assertThat(listingStatus(listing)).isEqualTo("ACTIVE");
        expect(get(buyer, "/listings/" + listing), 200);

        long addr = address(buyer);
        long order = buy(buyer, listing, 1, "WALLET", addr);
        assertThat(orderStatus(order)).isEqualTo("PENDING_CONFIRM");
        assertThat(stock(listing)).as("giữ hàng ngay khi đặt").isEqualTo(1);
        assertThat(walletAvailable(buyer.id())).isEqualTo(500_000 - total(order));
        assertThat(walletAvailable(seller.id())).as("tiền chưa tới người bán khi đơn chưa hoàn tất").isZero();

        expect(post(seller, "/seller/orders/" + order + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + order + "/ship", Map.of("trackingCode", "VN123")), 200);
        expect(post(seller, "/seller/orders/" + order + "/delivered", null), 200);
        expect(post(buyer, "/orders/" + order + "/confirm-received", null), 200);

        assertThat(orderStatus(order)).isEqualTo("COMPLETED");
        assertThat(walletAvailable(seller.id())).as("người bán nhận giá sách trừ phí sàn").isEqualTo(sellerNet(order));
        expect(post(buyer, "/orders/" + order + "/review", Map.of("rating", 5, "comment", "Sách đúng mô tả")), 201);
        assertThat(post(buyer, "/orders/" + order + "/review", Map.of("rating", 4)).status()).as("mỗi đơn một đánh giá").isEqualTo(409);
        assertThat(totalMoney(seller, buyer) - start).as("bảo toàn tiền: chỉ tăng đúng số đã nạp").isEqualTo(500_000);
    }

    // ---------------------------------------------------------------- S2

    @Test
    void s2_returnApprovedBuyerShipsBackAndIsRefunded() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        openShop(seller, true);
        long start = totalMoney(seller, buyer);
        topUp(buyer, 400_000);
        long listing = createListing(seller, 100_000, 1);
        long addr = address(buyer);
        long order = deliveredOrder(seller, buyer, listing, addr);
        long paid = total(order);

        expect(post(buyer, "/orders/" + order + "/return",
                Map.of("reason", "WRONG_CONDITION", "description", "Thiếu trang", "images", List.of("/files/x.png"))), 200);
        assertThat(orderStatus(order)).isEqualTo("RETURN_REQUESTED");
        expect(post(seller, "/seller/orders/" + order + "/return-decision", Map.of("approve", true, "note", "Đồng ý")), 200);
        assertThat(walletAvailable(buyer.id())).as("chưa hoàn tiền khi sách chưa về").isEqualTo(400_000 - paid);
        expect(post(buyer, "/orders/" + order + "/return/shipment", Map.of("trackingCode", "RT1")), 200);
        expect(post(seller, "/seller/orders/" + order + "/return-received", null), 200);

        assertThat(orderStatus(order)).isEqualTo("RETURNED");
        assertThat(walletAvailable(buyer.id())).as("hoàn đủ tiền").isEqualTo(400_000);
        assertThat(walletAvailable(seller.id())).isZero();
        assertThat(totalMoney(seller, buyer) - start).isEqualTo(400_000);
    }

    // ---------------------------------------------------------------- S3

    @Test
    void s3_returnRejectedAdminKeepsTheOrder() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        Actor admin = admin();
        openShop(seller, true);
        topUp(buyer, 400_000);
        long listing = createListing(seller, 100_000, 1);
        long order = deliveredOrder(seller, buyer, listing, address(buyer));

        expect(post(buyer, "/orders/" + order + "/return",
                Map.of("reason", "MISSING_PAGES", "description", "Thiếu 10 trang", "images", List.of("/files/x.png"))), 200);
        expect(post(seller, "/seller/orders/" + order + "/return-decision", Map.of("approve", false, "note", "Sách đủ trang")), 200);
        expect(post(admin, "/admin/disputes/" + order + "/resolve", Map.of("approve", false, "note", "Shop đúng")), 200);

        assertThat(orderStatus(order)).isEqualTo("COMPLETED");
        assertThat(walletAvailable(seller.id())).isEqualTo(sellerNet(order));
    }

    @Test
    void s3_returnRejectedAdminRefundsTheBuyer() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        Actor admin = admin();
        openShop(seller, true);
        topUp(buyer, 400_000);
        long listing = createListing(seller, 100_000, 1);
        long order = deliveredOrder(seller, buyer, listing, address(buyer));

        expect(post(buyer, "/orders/" + order + "/return",
                Map.of("reason", "WRONG_EDITION", "description", "Sai ấn bản", "images", List.of("/files/x.png"))), 200);
        expect(post(seller, "/seller/orders/" + order + "/return-decision", Map.of("approve", false, "note", "Không đồng ý")), 200);
        expect(post(admin, "/admin/disputes/" + order + "/resolve", Map.of("approve", true, "note", "Người mua đúng")), 200);
        assertThat(orderStatus(order)).as("Admin phân xử hoàn tiền: vẫn phải chờ hàng về").isIn("RETURN_REQUESTED", "RETURNED");
        if (orderStatus(order).equals("RETURN_REQUESTED")) {
            expect(post(buyer, "/orders/" + order + "/return/shipment", Map.of("trackingCode", "RT2")), 200);
            expect(post(seller, "/seller/orders/" + order + "/return-received", null), 200);
        }
        assertThat(orderStatus(order)).isEqualTo("RETURNED");
        assertThat(walletAvailable(buyer.id())).isEqualTo(400_000);
        assertThat(walletAvailable(seller.id())).isZero();
    }

    // ---------------------------------------------------------------- S4

    @Test
    void s4_cancelBeforeAndAfterConfirmation() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        openShop(seller, true);
        topUp(buyer, 500_000);
        long listing = createListing(seller, 100_000, 2);
        long addr = address(buyer);

        long first = buy(buyer, listing, 1, "WALLET", addr);
        assertThat(stock(listing)).isEqualTo(1);
        expect(post(buyer, "/orders/" + first + "/cancel", Map.of("reason", "Đổi ý")), 200);
        assertThat(orderStatus(first)).isEqualTo("CANCELLED");
        assertThat(stock(listing)).as("trả lại tồn kho").isEqualTo(2);
        assertThat(walletAvailable(buyer.id())).as("hoàn đủ tiền").isEqualTo(500_000);

        long second = buy(buyer, listing, 1, "WALLET", addr);
        expect(post(seller, "/seller/orders/" + second + "/confirm", null), 200);
        expect(post(buyer, "/orders/" + second + "/cancel", Map.of("reason", "Mua nhầm")), 200);
        assertThat(orderStatus(second)).as("sau khi xác nhận chỉ gửi yêu cầu huỷ").isEqualTo("PREPARING");
        expect(post(seller, "/seller/orders/" + second + "/cancel-request", Map.of("approve", true)), 200);
        assertThat(orderStatus(second)).isEqualTo("CANCELLED");
        assertThat(walletAvailable(buyer.id())).isEqualTo(500_000);
        assertThat(stock(listing)).isEqualTo(2);
    }

    @Test
    void s4b_sellerCancelsAfterConfirmingAndAFailedDeliveryAreBothRefunded() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        openShop(seller, true);
        long start = totalMoney(seller, buyer);
        topUp(buyer, 600_000);
        long listing = createListing(seller, 100_000, 2);
        long addr = address(buyer);

        long a = buy(buyer, listing, 1, "WALLET", addr);
        expect(post(seller, "/seller/orders/" + a + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + a + "/cancel", Map.of("reason", "Hết sách thật")), 200);
        assertThat(orderStatus(a)).isEqualTo("CANCELLED");
        assertThat(stock(listing)).isEqualTo(2);
        assertThat(walletAvailable(buyer.id())).isEqualTo(600_000);

        long b = buy(buyer, listing, 1, "WALLET", addr);
        expect(post(seller, "/seller/orders/" + b + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + b + "/ship", Map.of("trackingCode", "F1")), 200);
        expect(post(seller, "/seller/orders/" + b + "/delivery-failed", Map.of("reason", "Người nhận không nghe máy")), 200);
        assertThat(orderStatus(b)).isEqualTo("FAILED_DELIVERY");
        assertThat(walletAvailable(buyer.id())).as("giao thất bại: hoàn đủ tiền").isEqualTo(600_000);
        assertThat(walletAvailable(seller.id())).isZero();
        assertThat(totalMoney(seller, buyer) - start).isEqualTo(600_000);
    }

    // ---------------------------------------------------------------- S5

    @Test
    void s5_codPaysTheSellerOnlyAfterTheCarrierMoneyIsRemitted() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        Actor staff = staff();
        Actor admin = admin();
        openShop(seller, true);
        long start = totalMoney(seller, buyer);
        long listing = createListing(seller, 100_000, 1);
        long order = buy(buyer, listing, 1, "COD", address(buyer));
        assertThat(orderStatus(order)).isEqualTo("PENDING_CONFIRM");

        expect(post(seller, "/seller/orders/" + order + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + order + "/ship", Map.of("trackingCode", "COD1")), 200);
        expect(post(staff, "/staff/orders/" + order + "/carrier-delivered", null), 200);
        expect(post(buyer, "/orders/" + order + "/confirm-received", null), 200);
        assertThat(orderStatus(order)).isEqualTo("COMPLETED");
        assertThat(walletAvailable(seller.id())).as("sàn chưa nhận tiền thu hộ thì chưa trả người bán").isZero();

        expect(post(admin, "/admin/cod/" + order + "/remit", Map.of("amount", total(order), "reference", "DS-1")), 200);
        assertThat(walletAvailable(seller.id())).isEqualTo(sellerNet(order));
        assertThat(totalMoney(seller, buyer) - start).as("COD: tiền vào hệ thống đúng bằng số hãng vận chuyển nộp").isEqualTo(total(order));
    }

    // ---------------------------------------------------------------- Đấu giá

    private record World(Actor seller, Actor staff, Actor admin, Actor b1, Actor b2, Actor b3, long lot, long session) {
    }

    private void closeCurrentLotAndTick(long session, long lot) {
        jdbc.update("UPDATE lots SET ends_at = now() - interval '1 second' WHERE id = ?", lot);
        runner.tick(session);
    }

    private void bid(Actor who, long lot, long amount) throws Exception {
        expect(post(who, "/lots/" + lot + "/bids", Map.of("amount", amount)), 200);
    }

    /** Ký gửi → kiểm định → phiên → đăng ký → mở phiên → ba người trả giá → hết phiên. Người thắng: b2 ở 450.000. */
    private World auctionUntilInvoice() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b1 = user("Người 1", 0);
        Actor b2 = user("Người 2", 0);
        Actor b3 = user("Người 3", 0);
        for (Actor b : List.of(b1, b2, b3)) {
            topUp(b, 1_000_000);
        }
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 2, lot);
        for (Actor b : List.of(b1, b2, b3)) {
            Res r = post(b, "/sessions/" + session + "/register", Map.of("agreeRules", true));
            assertThat(r.status()).as("đăng ký " + r.body()).isIn(200, 201);
            assertThat(walletHeld(b.id())).as("khoá cọc").isEqualTo(100_000);
        }
        expect(post(admin, "/admin/sessions/" + session + "/start", null), 200);
        runner.tick(session);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot)).isEqualTo("OPEN");

        bid(b1, lot, 200_000);
        bid(b2, lot, 250_000);
        expect(put(b3, "/lots/" + lot + "/proxy-bid", Map.of("maxAmount", 400_000)), 200);
        bid(b1, lot, 350_000);
        bid(b2, lot, 450_000);

        closeCurrentLotAndTick(session, lot);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot)).isEqualTo("SOLD");
        jdbc.update("UPDATE auction_sessions SET next_lot_at = now() - interval '1 second' WHERE id = ?", session);
        runner.tick(session);
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).isEqualTo("ENDED");
        return new World(seller, staff, admin, b1, b2, b3, lot, session);
    }

    private long invoice(World w, Actor buyer) {
        return jdbc.queryForObject("SELECT id FROM orders WHERE lot_id = ? AND buyer_id = ? AND order_type = 'AUCTION'", Long.class, w.lot(), buyer.id());
    }

    // ---------------------------------------------------------------- S6

    @Test
    void s6_consignAuctionPayPickUpAndSellerGetsPaid() throws Exception {
        Actor probe = user("đo", 0);
        long start = totalMoney(probe);
        World w = auctionUntilInvoice();
        long all = totalMoney(w.seller(), w.b1(), w.b2(), w.b3()) - start;
        assertThat(all).as("tổng tiền các bên = tổng đã nạp").isEqualTo(3_000_000);

        assertThat(walletHeld(w.b1().id())).as("người thua nhận lại cọc").isZero();
        assertThat(walletHeld(w.b3().id())).isZero();
        assertThat(walletAvailable(w.b1().id())).isEqualTo(1_000_000);
        assertThat(walletAvailable(w.b3().id())).isEqualTo(1_000_000);
        assertThat(walletHeld(w.b2().id())).as("người thắng còn bị giữ cọc tới khi trả hoá đơn").isEqualTo(100_000);

        long inv = invoice(w, w.b2());
        assertThat(subtotal(inv)).isEqualTo(450_000);
        expect(post(w.b2(), "/orders/" + inv + "/delivery-option", Map.of("pickupAtWarehouse", true)), 200);
        Res due = get(w.b2(), "/orders/" + inv);
        long amountDue = due.body().path("amountDue").asLong();
        assertThat(amountDue).as("hoá đơn = giá búa + phí người mua − cọc").isEqualTo(
                450_000 + due.body().path("buyerPremium").asLong() - 100_000);
        expect(post(w.b2(), "/orders/" + inv + "/pay", Map.of("method", "WALLET")), 200);
        assertThat(orderStatus(inv)).isEqualTo("PENDING_CONFIRM");

        expect(post(w.staff(), "/staff/orders/" + inv + "/confirm", null), 200);
        expect(post(w.staff(), "/staff/orders/" + inv + "/delivered", null), 200);
        assertThat(orderStatus(inv)).isEqualTo("DELIVERED");
        expect(post(w.b2(), "/orders/" + inv + "/confirm-received", null), 200);
        assertThat(orderStatus(inv)).isEqualTo("COMPLETED");

        long commission = jdbc.queryForObject("SELECT round(450000 * commission_percent / 100) FROM lots WHERE id = ?", Long.class, w.lot());
        assertThat(walletAvailable(w.seller().id())).as("người bán nhận giá búa trừ hoa hồng").isEqualTo(450_000 - commission);
        assertThat(walletHeld(w.b2().id())).isZero();
        assertThat(totalMoney(w.seller(), w.b1(), w.b2(), w.b3()) - start).as("bảo toàn tiền").isEqualTo(3_000_000);
    }

    // ---------------------------------------------------------------- S7

    @Test
    void s7_winnerNeverPaysSoTheRunnerUpIsOfferedAndPays() throws Exception {
        Actor probe = user("đo", 0);
        long start = totalMoney(probe);
        World w = auctionUntilInvoice();
        long inv = invoice(w, w.b2());

        jdbc.update("UPDATE orders SET payment_due_at = now() - interval '1 hour' WHERE id = ?", inv);
        settlement.handleOverdue(inv);

        assertThat(orderStatus(inv)).isEqualTo("CANCELLED");
        assertThat(jdbc.queryForObject("SELECT auction_banned_until IS NOT NULL FROM users WHERE id = ?", Boolean.class, w.b2().id()))
                .as("bị cấm đấu giá").isTrue();
        assertThat(walletHeld(w.b2().id())).as("cọc đã bị thu").isZero();
        assertThat(walletAvailable(w.b2().id())).isLessThan(1_000_000);

        // Người trả cao thứ hai là b3 (proxy 400.000 thua ở 400.000? hoặc b1 350.000): ai được mời phải đạt giá sàn 300.000
        Long second = jdbc.queryForObject("SELECT buyer_id FROM orders WHERE lot_id = ? AND second_chance", Long.class, w.lot());
        assertThat(second).isIn(w.b1().id(), w.b3().id());
        Actor offered = second == w.b1().id() ? w.b1() : w.b3();
        long offer = invoice(w, offered);
        expect(post(offered, "/orders/" + offer + "/delivery-option", Map.of("pickupAtWarehouse", true)), 200);
        expect(post(offered, "/orders/" + offer + "/pay", Map.of("method", "WALLET")), 200);
        expect(post(w.staff(), "/staff/orders/" + offer + "/confirm", null), 200);
        expect(post(w.staff(), "/staff/orders/" + offer + "/delivered", null), 200);
        expect(post(offered, "/orders/" + offer + "/confirm-received", null), 200);

        assertThat(orderStatus(offer)).isEqualTo("COMPLETED");
        assertThat(walletAvailable(w.seller().id())).as("người bán vẫn được trả").isPositive();
        assertThat(totalMoney(w.seller(), w.b1(), w.b2(), w.b3()) - start).as("bảo toàn tiền, tiền phạt về ví sàn").isEqualTo(3_000_000);
    }

    // ---------------------------------------------------------------- S8

    @Test
    void s8_sessionWithTooFewPeopleIsPostponedThenCancelledAndEveryoneIsRefunded() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b1 = user("Người 1", 0);
        topUp(b1, 500_000);
        long lot = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 3, lot);
        assertThat(post(b1, "/sessions/" + session + "/register", Map.of("agreeRules", true)).status()).isIn(200, 201);
        expect(post(b1, "/sessions/" + session + "/deposit", Map.of("amount", 10_000)), 200);
        assertThat(walletHeld(b1.id())).isEqualTo(110_000);

        jdbc.update("UPDATE auction_sessions SET registration_deadline = now() - interval '1 minute' WHERE id = ?", session);
        runner.checkQuorum(session);
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).as("dời lịch một lần").isEqualTo("PUBLISHED");
        assertThat(jdbc.queryForObject("SELECT postpone_count FROM auction_sessions WHERE id = ?", Integer.class, session)).isEqualTo(1);

        jdbc.update("UPDATE auction_sessions SET registration_deadline = now() - interval '1 minute' WHERE id = ?", session);
        runner.checkQuorum(session);
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).isEqualTo("CANCELLED");
        assertThat(walletHeld(b1.id())).as("hoàn toàn bộ cọc").isZero();
        assertThat(walletAvailable(b1.id())).isEqualTo(500_000);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot)).as("lô quay về chờ xếp phiên").isEqualTo("READY");
    }

    // ---------------------------------------------------------------- Thêm các ngã rẽ của SRS 6.5 – 6.6

    private String lotStatus(long lot) {
        return jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot);
    }

    private String closeResult(long lot) {
        return jdbc.queryForObject("SELECT close_result FROM lots WHERE id = ?", String.class, lot);
    }

    private void startSession(Actor admin, long session) throws Exception {
        expect(post(admin, "/admin/sessions/" + session + "/start", null), 200);
        runner.tick(session);
    }

    /** Mở lô kế (sau giờ nghỉ). */
    private void openNext(long session) {
        jdbc.update("UPDATE auction_sessions SET next_lot_at = now() - interval '1 second' WHERE id = ?", session);
        runner.tick(session);
    }

    private void register(Actor who, long session) throws Exception {
        assertThat(post(who, "/sessions/" + session + "/register", Map.of("agreeRules", true)).status()).isIn(200, 201);
    }

    // ---------------------------------------------------------------- S9

    @Test
    void s9_unsoldLotConvertedToAFixedPriceListingAndSold() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b1 = user("Người xem", 0);
        Actor buyer = user("Người mua", 0);
        openShop(seller, true);
        topUp(b1, 500_000);
        topUp(buyer, 600_000);
        long consignment = newConsignmentThroughInspection(seller, staff);
        long lot = jdbc.queryForObject("SELECT id FROM lots WHERE consignment_id = ?", Long.class, consignment);
        long session = publishedSession(admin, 100_000, 1, lot);
        register(b1, session);
        startSession(admin, session);

        closeCurrentLotAndTick(session, lot); // không ai trả giá
        assertThat(lotStatus(lot)).isEqualTo("UNSOLD");
        assertThat(closeResult(lot)).isEqualTo("NO_BIDS");
        openNext(session);
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).isEqualTo("ENDED");
        assertThat(walletHeld(b1.id())).as("không thắng lô nào: nhận lại cọc").isZero();

        expect(post(seller, "/consignments/" + consignment + "/unsold-decision",
                Map.of("action", "CONVERT_TO_LISTING", "listingPrice", 300_000)), 200);
        assertThat(lotStatus(lot)).isEqualTo("CONVERTED");
        long listing = jdbc.queryForObject("SELECT l.id FROM listings l JOIN consignments c ON c.book_id = l.book_id WHERE c.id = ?", Long.class, consignment);
        assertThat(listingStatus(listing)).isEqualTo("PENDING_REVIEW");
        assertThat(post(admin, "/admin/listings/" + listing + "/approve", null).status()).as("sách còn nằm trong kho").isIn(400, 409);

        long warehouse = jdbc.queryForObject("SELECT id FROM warehouse_items WHERE consignment_id = ?", Long.class, consignment);
        expect(post(staff, "/staff/warehouse/" + warehouse + "/return", null), 200);
        expect(post(admin, "/admin/listings/" + listing + "/approve", null), 200);
        long order = buy(buyer, listing, 1, "WALLET", address(buyer));
        assertThat(orderStatus(order)).isEqualTo("PENDING_CONFIRM");
    }

    private long newConsignmentThroughInspection(Actor seller, Actor staff) throws Exception {
        long c = newConsignment(seller, 500_000);
        expect(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 200);
        java.time.Instant at = java.time.Instant.now().plus(2, java.time.temporal.ChronoUnit.DAYS).atZone(VN).withHour(10).withMinute(0).toInstant();
        expect(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", at.toString())), 200);
        expect(post(staff, "/staff/consignments/" + c + "/check-in", Map.of("shelfCode", "A9")), 200);
        expect(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(400_000, 600_000, 200_000, 300_000)), 200);
        expect(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true)), 200);
        return c;
    }

    // ---------------------------------------------------------------- S10

    @Test
    void s10_reserveNotMetThenRelistedWithALowerReserveAndSold() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b1 = user("Người 1", 0);
        Actor b2 = user("Người 2", 0);
        topUp(b1, 600_000);
        topUp(b2, 600_000);
        long consignment = newConsignmentThroughInspection(seller, staff);
        long lot = jdbc.queryForObject("SELECT id FROM lots WHERE consignment_id = ?", Long.class, consignment);

        long first = publishedSession(admin, 100_000, 1, lot);
        register(b1, first);
        register(b2, first);
        startSession(admin, first);
        bid(b1, lot, 200_000);
        bid(b2, lot, 250_000);
        closeCurrentLotAndTick(first, lot);
        assertThat(lotStatus(lot)).isEqualTo("UNSOLD");
        assertThat(closeResult(lot)).as("giá cuối 250.000 < giá sàn 300.000").isEqualTo("RESERVE_NOT_MET");
        assertThat(jdbc.queryForObject("SELECT hammer_price FROM lots WHERE id = ?", Long.class, lot)).as("không có giá búa").isNull();
        openNext(first);
        assertThat(walletHeld(b1.id())).as("không ai thắng: hoàn cọc cả hai").isZero();
        assertThat(walletHeld(b2.id())).isZero();

        status(post(seller, "/consignments/" + consignment + "/unsold-decision", Map.of("action", "RELIST", "newReserve", 150_000)), 400);
        status(post(seller, "/consignments/" + consignment + "/unsold-decision", Map.of("action", "RELIST", "newReserve", 350_000)), 400);
        expect(post(seller, "/consignments/" + consignment + "/unsold-decision", Map.of("action", "RELIST", "newReserve", 250_000)), 200);
        assertThat(lotStatus(lot)).isEqualTo("READY");

        long second = publishedSession(admin, 100_000, 1, lot);
        register(b1, second);
        register(b2, second);
        startSession(admin, second);
        bid(b1, lot, 200_000);
        bid(b2, lot, 250_000);
        closeCurrentLotAndTick(second, lot);
        assertThat(lotStatus(lot)).isEqualTo("SOLD");
        assertThat(jdbc.queryForObject("SELECT hammer_price::bigint FROM lots WHERE id = ?", Long.class, lot)).isEqualTo(250_000);
        openNext(second);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE lot_id = ? AND buyer_id = ?", Long.class, lot, b2.id())).isEqualTo(1);
        assertThat(walletHeld(b1.id())).isZero();
    }

    private void status(Res r, int... allowed) {
        assertThat(r.status()).as(r.body().toString()).isIn(java.util.Arrays.stream(allowed).boxed().toArray());
    }

    // ---------------------------------------------------------------- S11

    @Test
    void s11_staffCancelsTheOpenLotAndTheSessionGoesOn() throws Exception {
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b1 = user("Người 1", 0);
        Actor b2 = user("Người 2", 0);
        topUp(b1, 600_000);
        topUp(b2, 600_000);
        long lot1 = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long lot2 = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 2, lot1, lot2);
        register(b1, session);
        register(b2, session);
        startSession(admin, session);

        bid(b1, lot1, 200_000);
        status(post(user("Không phải Staff", 0), "/staff/lots/" + lot1 + "/cancel", Map.of("reason", "x")), 403);
        expect(post(staff, "/staff/lots/" + lot1 + "/cancel", Map.of("reason", "Sách bị rách khi mang lên")), 200);
        assertThat(lotStatus(lot1)).isEqualTo("CANCELLED");
        status(post(b2, "/lots/" + lot1 + "/bids", Map.of("amount", 250_000)), 409);

        openNext(session);
        assertThat(lotStatus(lot2)).as("phiên chạy tiếp lô sau").isEqualTo("OPEN");
        bid(b2, lot2, 300_000);
        closeCurrentLotAndTick(session, lot2);
        openNext(session);
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).isEqualTo("ENDED");
        assertThat(walletHeld(b1.id())).as("b1 chỉ dẫn lô bị huỷ: nhận lại cọc").isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE lot_id = ?", Long.class, lot1)).as("lô huỷ không có hoá đơn").isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE lot_id = ? AND buyer_id = ?", Long.class, lot2, b2.id())).isEqualTo(1);
    }

    // ---------------------------------------------------------------- S12

    @Test
    void s12_oneBuyerWinsTwoLotsAndTheDepositAndShippingAreAppliedOnce() throws Exception {
        Actor probe = user("đo", 0);
        long start = totalMoney(probe);
        Actor seller = user("Người ký gửi", 0);
        Actor staff = staff();
        Actor admin = admin();
        Actor b1 = user("Người thắng hai lô", 0);
        Actor b2 = user("Người cạnh tranh", 0);
        topUp(b1, 1_500_000);
        topUp(b2, 600_000);
        long lot1 = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long lot2 = consignToReadyLot(seller, staff, 500_000, 400_000, 600_000, 200_000, 300_000);
        long session = publishedSession(admin, 100_000, 2, lot1, lot2);
        register(b1, session);
        register(b2, session);
        long addr = address(b1);
        startSession(admin, session);

        bid(b2, lot1, 250_000);
        bid(b1, lot1, 300_000);
        closeCurrentLotAndTick(session, lot1);
        openNext(session);
        bid(b2, lot2, 250_000);
        bid(b1, lot2, 350_000);
        closeCurrentLotAndTick(session, lot2);
        openNext(session);
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).isEqualTo("ENDED");
        assertThat(walletHeld(b2.id())).as("người thua cả hai nhận lại cọc").isZero();

        List<Long> invoices = jdbc.queryForList("SELECT id FROM orders WHERE buyer_id = ? AND order_type = 'AUCTION' ORDER BY id", Long.class, b1.id());
        assertThat(invoices).hasSize(2);
        long deposits = 0;
        long shipping = 0;
        for (long inv : invoices) {
            expect(post(b1, "/orders/" + inv + "/delivery-option", Map.of("addressId", addr, "pickupAtWarehouse", false)), 200);
            Res d = get(b1, "/orders/" + inv);
            deposits += d.body().path("depositApplied").asLong();
            shipping += d.body().path("shippingFee").asLong();
        }
        assertThat(deposits).as("cọc chỉ trừ một lần cho cả hai hoá đơn").isEqualTo(100_000);
        long single = jdbc.queryForObject("SELECT max(shipping_fee) FROM orders WHERE buyer_id = ? AND order_type = 'AUCTION'", Long.class, b1.id());
        assertThat(shipping).as("gộp kiện: tổng phí giao nhỏ hơn hai lần phí lẻ").isLessThan(2 * single);

        for (long inv : invoices) {
            expect(post(b1, "/orders/" + inv + "/pay", Map.of("method", "WALLET")), 200);
            expect(post(staff, "/staff/orders/" + inv + "/confirm", null), 200);
            expect(post(staff, "/staff/orders/" + inv + "/ship", Map.of("trackingCode", "AU" + inv)), 200);
            expect(post(staff, "/staff/orders/" + inv + "/delivered", null), 200);
            expect(post(b1, "/orders/" + inv + "/confirm-received", null), 200);
            assertThat(orderStatus(inv)).isEqualTo("COMPLETED");
        }
        assertThat(walletHeld(b1.id())).isZero();
        assertThat(walletAvailable(seller.id())).as("người bán nhận hai giá búa trừ hoa hồng").isGreaterThan(0).isLessThan(650_000);
        assertThat(totalMoney(seller, b1, b2) - start).as("bảo toàn tiền").isEqualTo(2_100_000);
    }

    // ---------------------------------------------------------------- S13

    @Test
    void s13_sellerWithdrawsSaleProceedsAndAdminApprovesOrRejects() throws Exception {
        Actor seller = user("Người bán", 0);
        Actor buyer = user("Người mua", 0);
        Actor admin = admin();
        openShop(seller, true);
        topUp(buyer, 400_000);
        long listing = createListing(seller, 200_000, 1);
        long order = buy(buyer, listing, 1, "WALLET", address(buyer));
        expect(post(seller, "/seller/orders/" + order + "/confirm", null), 200);
        expect(post(seller, "/seller/orders/" + order + "/ship", Map.of("trackingCode", "W1")), 200);
        expect(post(seller, "/seller/orders/" + order + "/delivered", null), 200);
        expect(post(buyer, "/orders/" + order + "/confirm-received", null), 200);
        long net = sellerNet(order);
        assertThat(walletAvailable(seller.id())).isEqualTo(net);

        Res w = get(seller, "/wallet/withdrawable");
        assertThat(w.body().path("withdrawable").asLong()).as("tiền bán hàng không bị khoá như tiền mới nạp").isEqualTo(net);

        Map<String, Object> bank = Map.of("bankName", "VCB", "accountNumber", "0123456789", "accountHolder", "NGUOI BAN");
        long w1 = expect(post(seller, "/wallet/withdrawals", merge(bank, Map.of("amount", 100_000))), 201).id();
        long w2 = expect(post(seller, "/wallet/withdrawals", merge(bank, Map.of("amount", 50_000))), 201).id();
        assertThat(walletAvailable(seller.id())).as("tiền xin rút bị khoá").isEqualTo(net - 150_000);
        status(post(seller, "/wallet/withdrawals", merge(bank, Map.of("amount", net))), 400, 409);

        expect(post(admin, "/admin/withdrawals/" + w1, Map.of("approve", true, "senderName", "ReBook", "transferTime", java.time.Instant.now().toString(),
                "transferAmount", 100_000, "proofImageUrl", "/files/bill.png")), 200);
        expect(post(admin, "/admin/withdrawals/" + w2, Map.of("approve", false, "note", "Sai tên tài khoản")), 200);
        assertThat(walletAvailable(seller.id())).as("duyệt: trừ hẳn; từ chối: trả lại").isEqualTo(net - 100_000);
        assertThat(walletHeld(seller.id())).isZero();
        status(post(admin, "/admin/withdrawals/" + w1, Map.of("approve", false, "note", "x")), 409);
    }

    private static Map<String, Object> merge(Map<String, Object> a, Map<String, Object> b) {
        Map<String, Object> m = new java.util.HashMap<>(a);
        m.putAll(b);
        return m;
    }

    // ---------------------------------------------------------------- S14

    @Test
    void s14_payingTheSameInvoiceTwiceAtTheSameMomentChargesOnce() throws Exception {
        World w = auctionUntilInvoice();
        long inv = invoice(w, w.b2());
        expect(post(w.b2(), "/orders/" + inv + "/delivery-option", Map.of("pickupAtWarehouse", true)), 200);
        long before = walletAvailable(w.b2().id());

        java.util.concurrent.ExecutorService pool = java.util.concurrent.Executors.newFixedThreadPool(2);
        java.util.concurrent.CountDownLatch go = new java.util.concurrent.CountDownLatch(1);
        List<java.util.concurrent.Future<Integer>> fs = new java.util.ArrayList<>();
        for (int i = 0; i < 2; i++) {
            fs.add(pool.submit(() -> {
                go.await();
                return post(w.b2(), "/orders/" + inv + "/pay", Map.of("method", "WALLET")).status();
            }));
        }
        go.countDown();
        List<Integer> codes = new java.util.ArrayList<>();
        for (var f : fs) {
            codes.add(f.get());
        }
        pool.shutdown();

        assertThat(codes).containsExactlyInAnyOrder(200, 409);
        long due = before - walletAvailable(w.b2().id());
        assertThat(due).as("chỉ trừ tiền một lần").isEqualTo(jdbc.queryForObject("SELECT total - COALESCE(deposit_applied, 0) FROM orders WHERE id = ?", Long.class, inv));
    }
}
