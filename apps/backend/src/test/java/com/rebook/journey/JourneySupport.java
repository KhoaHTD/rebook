package com.rebook.journey;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Hạ tầng chung cho test luồng đầu cuối: gọi API như app gọi, dựng nhanh người dùng, shop, tin, ký gửi, phiên. */
abstract class JourneySupport extends IntegrationTest {

    protected static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");

    @Autowired
    protected ObjectMapper om;

    /** Một người dùng đang đóng vai nào đó. */
    protected record Actor(long id, Role role) {
    }

    protected record Res(int status, JsonNode body) {
        long id() {
            return body.path("id").asLong();
        }

        String text(String field) {
            return body.path(field).asText();
        }
    }

    protected Res call(HttpMethod method, String url, Actor who, Object body) throws Exception {
        var req = MockMvcRequestBuilders.request(method, url);
        if (who != null) {
            req.with(as(who.id(), who.role()));
        }
        if (body != null) {
            req.contentType(MediaType.APPLICATION_JSON).content(body instanceof String s ? s : om.writeValueAsString(body));
        }
        MockHttpServletResponse r = mvc.perform(req).andReturn().getResponse();
        String text = r.getContentAsString();
        return new Res(r.getStatus(), text == null || text.isBlank() ? om.createObjectNode() : om.readTree(text));
    }

    protected Res get(Actor who, String url) throws Exception {
        return call(HttpMethod.GET, url, who, null);
    }

    protected Res post(Actor who, String url, Object body) throws Exception {
        return call(HttpMethod.POST, url, who, body);
    }

    protected Res put(Actor who, String url, Object body) throws Exception {
        return call(HttpMethod.PUT, url, who, body);
    }

    protected Res delete(Actor who, String url) throws Exception {
        return call(HttpMethod.DELETE, url, who, null);
    }

    // ---- Người dùng ----

    protected Actor user(String name, long balance) {
        long id = createUser(Role.USER, name, balance);
        jdbc.update("UPDATE users SET phone = ?, phone_verified = TRUE WHERE id = ?", "09" + (10_000_000 + id % 80_000_000), id);
        return new Actor(id, Role.USER);
    }

    protected Actor staff() {
        return new Actor(createUser(Role.STAFF, "Nhân viên kho", 0), Role.STAFF);
    }

    protected Actor admin() {
        return new Actor(createUser(Role.ADMIN, "Quản trị", 0), Role.ADMIN);
    }

    protected long address(Actor who) throws Exception {
        Res r = post(who, "/me/addresses", Map.of("receiverName", "Người nhận", "phone", "0912345678", "province", "Hồ Chí Minh",
                "district", "Quận 1", "ward", "Bến Nghé", "detail", "1 Lê Lợi", "isDefault", true));
        if (r.status() != 200 && r.status() != 201) {
            throw new IllegalStateException("Không tạo được địa chỉ: " + r.status() + " " + r.body());
        }
        return r.id();
    }

    // ---- Tiền ----

    /** Nạp ví đúng như app: tạo giao dịch ZaloPay rồi giả lập cổng trả về thành công. */
    protected void topUp(Actor who, long amount) throws Exception {
        Res p = post(who, "/wallet/top-up", Map.of("amount", amount));
        if (p.status() != 201) {
            throw new IllegalStateException("Không nạp được: " + p.status() + " " + p.body());
        }
        Res paid = post(who, "/payments/" + p.text("code") + "/simulate", null);
        if (paid.status() != 200) {
            throw new IllegalStateException("Giả lập thanh toán lỗi: " + paid.status() + " " + paid.body());
        }
    }

    /**
     * Phần tiền ví sàn gắn với những người tham gia (phí, phạt, tiền COD thu hộ...): giao dịch ví sàn có tham chiếu tới
     * đơn hoặc lượt đăng ký của họ. Không đo toàn bộ ví sàn vì job định kỳ của ứng dụng đang chạy trong test có thể
     * xử lý đơn do test khác để lại và cộng phí vào ví sàn đúng lúc đang đo.
     */
    protected long platformShare(Actor... actors) {
        if (actors.length == 0) {
            return 0;
        }
        String ids = java.util.Arrays.stream(actors).map(a -> String.valueOf(a.id())).collect(java.util.stream.Collectors.joining(","));
        return jdbc.queryForObject("""
                SELECT COALESCE(sum(t.available_change + t.held_change), 0)
                FROM wallet_transactions t JOIN wallets w ON w.id = t.wallet_id
                WHERE w.user_id IS NULL AND (
                      (t.ref_type = 'ORDER' AND t.ref_id IN (SELECT id FROM orders WHERE buyer_id IN (%s)))
                   OR (t.ref_type = 'REGISTRATION' AND t.ref_id IN (SELECT id FROM auction_registrations WHERE user_id IN (%s))))
                """.formatted(ids, ids), Long.class);
    }

    /** Tổng ví của những người tham gia + phần ví sàn gắn với họ (dùng để kiểm bảo toàn tiền). */
    protected long totalMoney(Actor... actors) {
        long sum = platformShare(actors);
        for (Actor a : actors) {
            sum += walletAvailable(a.id()) + walletHeld(a.id());
        }
        return sum;
    }

    // ---- Shop, tin, mua bán ----

    protected long category;

    protected long category() {
        if (category == 0) {
            category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Journey', ?) RETURNING id", Long.class,
                    "jn-" + UUID.randomUUID());
        }
        return category;
    }

    protected Map<String, Object> book(String title) {
        return Map.of("title", title, "author", "Tác giả", "categoryId", category(), "conditionGrade", "GOOD",
                "weightGram", 300, "imageUrls", List.of("/files/a.png", "/files/b.png", "/files/c.png"));
    }

    protected long openShop(Actor owner, boolean trusted) throws Exception {
        Res r = put(owner, "/me/shop", Map.of("name", "Shop " + UUID.randomUUID().toString().substring(0, 8), "pickupAddress", "1 Nguyễn Huệ",
                "pickupProvince", "Hồ Chí Minh", "bankName", "VCB", "bankAccountNumber", "0123456789", "bankAccountHolder", "NGUOI BAN"));
        if (r.status() != 200 && r.status() != 201) {
            throw new IllegalStateException("Không bật được shop: " + r.status() + " " + r.body());
        }
        jdbc.update("UPDATE shops SET trusted = ? WHERE user_id = ?", trusted, owner.id());
        return r.id();
    }

    /** Đăng tin, trả về id tin (trạng thái tuỳ shop có uy tín hay không). */
    protected long createListing(Actor seller, long price, int stock) throws Exception {
        Res r = post(seller, "/seller/listings", Map.of("book", book("Sách " + UUID.randomUUID()), "price", price, "stock", stock));
        if (r.status() != 201 && r.status() != 200) {
            throw new IllegalStateException("Không đăng được tin: " + r.status() + " " + r.body());
        }
        return r.id();
    }

    protected String listingStatus(long listing) {
        return jdbc.queryForObject("SELECT status FROM listings WHERE id = ?", String.class, listing);
    }

    protected int stock(long listing) {
        return jdbc.queryForObject("SELECT stock FROM listings WHERE id = ?", Integer.class, listing);
    }

    /** Bỏ vào giỏ và đặt hàng một tin; trả về id đơn. */
    protected long buy(Actor buyer, long listing, int qty, String method, long address) throws Exception {
        Res add = post(buyer, "/cart", Map.of("listingId", listing, "quantity", qty));
        if (add.status() != 200) {
            throw new IllegalStateException("Không bỏ giỏ được: " + add.status() + " " + add.body());
        }
        Res co = post(buyer, "/orders/checkout", Map.of("addressId", address, "paymentMethod", method, "listingIds", List.of(listing)));
        if (co.status() != 201) {
            throw new IllegalStateException("Không đặt được: " + co.status() + " " + co.body());
        }
        return co.body().path("orders").get(0).path("id").asLong();
    }

    protected String orderStatus(long order) {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, order);
    }

    protected long total(long order) {
        return jdbc.queryForObject("SELECT total FROM orders WHERE id = ?", Long.class, order);
    }

    // ---- Ký gửi và phiên đấu giá ----

    protected long newConsignment(Actor seller, long expected) throws Exception {
        Res r = post(seller, "/consignments", Map.of("book", book("Sách quý " + UUID.randomUUID()), "expectedPrice", expected,
                "provenance", "Bản in đầu"));
        if (r.status() != 201 && r.status() != 200) {
            throw new IllegalStateException("Không tạo được ký gửi: " + r.status() + " " + r.body());
        }
        return r.id();
    }

    protected Map<String, Object> passInspection(long estLow, long estHigh, long start, long reserve) {
        return Map.of("result", "PASS", "conditionGrade", "GOOD", "conditionReport", "Sách còn tốt, đủ trang",
                "photoUrls", List.of("/files/s1.png"), "estimateLow", estLow, "estimateHigh", estHigh,
                "proposedStart", start, "proposedReserve", reserve);
    }

    /** Đưa một ký gửi đi hết vòng: sơ duyệt, hẹn lịch, nhận sách, kiểm định đạt, người bán chấp nhận. Trả về id lô. */
    protected long consignToReadyLot(Actor seller, Actor staff, long expected, long estLow, long estHigh, long start, long reserve) throws Exception {
        long c = newConsignment(seller, expected);
        expect(post(staff, "/staff/consignments/" + c + "/review", Map.of("approve", true)), 200);
        Instant at = Instant.now().plus(2, ChronoUnit.DAYS).atZone(VN).withHour(10).withMinute(0).withSecond(0).toInstant();
        expect(post(seller, "/consignments/" + c + "/appointment", Map.of("appointmentAt", at.toString())), 200);
        expect(post(staff, "/staff/consignments/" + c + "/check-in", Map.of("shelfCode", "A1", "photoUrls", List.of("/files/in.png"))), 200);
        expect(post(staff, "/staff/consignments/" + c + "/inspection", passInspection(estLow, estHigh, start, reserve)), 200);
        expect(post(seller, "/consignments/" + c + "/decision", Map.of("decision", "ACCEPT", "agreeTerms", true)), 200);
        return jdbc.queryForObject("SELECT id FROM lots WHERE consignment_id = ?", Long.class, c);
    }

    protected Res expect(Res r, int status) {
        if (r.status() != status) {
            throw new AssertionError("Mong " + status + " nhưng nhận " + r.status() + ": " + r.body());
        }
        return r;
    }

    protected Map<String, Object> sessionBody(String title, long deposit, int minParticipants) {
        Instant start = Instant.now().plus(10, ChronoUnit.DAYS);
        return Map.of("title", title, "startAt", start.toString(), "registrationDeadline", start.minus(2, ChronoUnit.DAYS).toString(),
                "minParticipants", minParticipants, "depositAmount", deposit, "lotDurationSec", 60, "softCloseSec", 15, "lotGapSec", 5);
    }

    /** Tạo phiên nháp, xếp lô, công bố. Trả về id phiên. */
    protected long publishedSession(Actor admin, long deposit, int minParticipants, long... lots) throws Exception {
        long s = expect(post(admin, "/admin/sessions", sessionBody("Phiên " + UUID.randomUUID().toString().substring(0, 6), deposit, minParticipants)), 201).id();
        expect(put(admin, "/admin/sessions/" + s + "/lots", Map.of("lotIds", java.util.Arrays.stream(lots).boxed().toList())), 200);
        expect(post(admin, "/admin/sessions/" + s + "/publish", null), 200);
        return s;
    }

    protected BigDecimal bd(long v) {
        return BigDecimal.valueOf(v);
    }
}
