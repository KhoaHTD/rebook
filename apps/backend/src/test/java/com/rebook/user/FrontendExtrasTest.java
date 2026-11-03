package com.rebook.user;

import com.rebook.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Các phần frontend làm thêm ngoài SRS (docs/BACKEND_HANDOFF.md của frontend): sách yêu thích, theo dõi phiên,
 * tài khoản ngân hàng đã dùng, ghim bản đồ cho địa chỉ, danh sách khiếu nại đã phân xử.
 */
class FrontendExtrasTest extends IntegrationTest {

    private long createListing(String status) {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hà Nội', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "test-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, owner, "Sách " + UUID.randomUUID(), category);
        return jdbc.queryForObject("""
                INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 100000, 1, ?) RETURNING id""",
                Long.class, book, shop, status);
    }

    @Test
    void favoriteListingsAreSavedNewestFirstAndHiddenOnesAreSkipped() throws Exception {
        long me = createUser(Role.USER, "Người thích sách", 0);
        long first = createListing("ACTIVE");
        long second = createListing("ACTIVE");
        long hidden = createListing("HIDDEN");

        for (long id : new long[]{first, second, hidden}) {
            mvc.perform(post("/listings/" + id + "/favorite").with(as(me, Role.USER)))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.favorite").value(true));
            jdbc.update("UPDATE listing_favorites SET created_at = now() + (? * interval '1 second') WHERE listing_id = ?",
                    id == first ? 1 : id == second ? 2 : 3, id);
        }
        // Thả tim lần hai không tạo dòng trùng.
        mvc.perform(post("/listings/" + first + "/favorite").with(as(me, Role.USER))).andExpect(status().isOk());

        mvc.perform(get("/me/favorites").with(as(me, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(second))
                .andExpect(jsonPath("$[1].id").value(first));

        mvc.perform(delete("/listings/" + second + "/favorite").with(as(me, Role.USER)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.favorite").value(false));
        mvc.perform(get("/me/favorites").with(as(me, Role.USER)))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(first));

        mvc.perform(post("/listings/999999999/favorite").with(as(me, Role.USER))).andExpect(status().isNotFound());
    }

    @Test
    void watchingWholeSessions() throws Exception {
        long me = createUser(Role.USER, "Người theo dõi", 0);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên yêu thích', now() + interval '2 day', now() + interval '1 day', 50000, 'PUBLISHED') RETURNING id""",
                Long.class);
        long draft = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên nháp', now() + interval '2 day', now() + interval '1 day', 50000, 'DRAFT') RETURNING id""",
                Long.class);

        mvc.perform(post("/sessions/" + session + "/watch").with(as(me, Role.USER)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.watching").value(true));
        mvc.perform(post("/sessions/" + draft + "/watch").with(as(me, Role.USER))).andExpect(status().isNotFound());

        mvc.perform(get("/me/watched-sessions").with(as(me, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(session));

        mvc.perform(delete("/sessions/" + session + "/watch").with(as(me, Role.USER))).andExpect(status().isOk());
        mvc.perform(get("/me/watched-sessions").with(as(me, Role.USER))).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void withdrawalsRememberBankAccountsAndFavoritesComeFirst() throws Exception {
        long me = createUser(Role.USER, "Người rút", 1_000_000);
        long other = createUser(Role.USER, "Người khác", 0);
        String vcb = """
                {"amount":100000,"bankName":"VCB","accountNumber":"0123","accountHolder":"NGUYEN A"}""";
        String acb = """
                {"amount":100000,"bankName":"ACB","accountNumber":"9999","accountHolder":"NGUYEN A"}""";
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content(vcb))
                .andExpect(status().isCreated());
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content(acb))
                .andExpect(status().isCreated());
        // Dùng lại tài khoản cũ: không tạo dòng mới.
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content(vcb))
                .andExpect(status().isCreated());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM bank_accounts WHERE user_id = ?", Long.class, me)).isEqualTo(2);
        mvc.perform(get("/wallet/bank-accounts").with(as(me, Role.USER)))
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].bankName").value("VCB"));

        long acbId = jdbc.queryForObject("SELECT id FROM bank_accounts WHERE user_id = ? AND bank_name = 'ACB'", Long.class, me);
        mvc.perform(post("/wallet/bank-accounts/" + acbId + "/favorite").with(as(me, Role.USER)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.favorite").value(true));
        mvc.perform(get("/wallet/bank-accounts").with(as(me, Role.USER)))
                .andExpect(jsonPath("$[0].bankName").value("ACB"));

        // Không đụng được tài khoản của người khác.
        mvc.perform(post("/wallet/bank-accounts/" + acbId + "/favorite").with(as(other, Role.USER)))
                .andExpect(status().isNotFound());
    }

    @Test
    void addressKeepsMapPinAndType() throws Exception {
        long me = createUser(Role.USER, "Người nhận", 0);
        mvc.perform(post("/me/addresses").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content("""
                        {"receiverName":"Người nhận","phone":"0900000000","province":"Hà Nội","district":"Ba Đình",
                         "ward":"Kim Mã","detail":"1 Kim Mã","isDefault":true,"latitude":21.03,"longitude":105.82,
                         "addressType":"OFFICE"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.latitude").value(21.03))
                .andExpect(jsonPath("$.addressType").value("OFFICE"));
        // Không gửi loại → nhà riêng; toạ độ sai → 400.
        mvc.perform(post("/me/addresses").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content("""
                        {"receiverName":"B","phone":"0900000000","province":"Hà Nội","district":"Ba Đình",
                         "ward":"Kim Mã","detail":"2 Kim Mã","isDefault":false}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.addressType").value("HOME"));
        mvc.perform(post("/me/addresses").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content("""
                        {"receiverName":"B","phone":"0900000000","province":"Hà Nội","district":"Ba Đình",
                         "ward":"Kim Mã","detail":"3 Kim Mã","isDefault":false,"latitude":200}"""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void resolvedDisputesListShowsWhoResolvedAndWhen() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin Phân Xử", 0);
        long buyer = createUser(Role.USER, "Người mua", 0);
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, subtotal, total, delivered_at)
                VALUES (?, ?, ?, 'NORMAL', 'DELIVERED', 'COD', 50000, 50000, now() - interval '1 day') RETURNING id""",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer, shop);
        mvc.perform(post("/orders/" + order + "/return").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"MISSING_PAGES","description":"Thiếu trang","images":["/files/a.png"]}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.returnRequest.respondBy").isNotEmpty());
        mvc.perform(post("/seller/orders/" + order + "/return-decision").with(as(owner, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approve\":false,\"note\":\"Sách đúng mô tả\"}"))
                .andExpect(status().isOk());
        mvc.perform(post("/admin/disputes/" + order + "/resolve").with(as(admin, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approve\":false,\"note\":\"Giữ đơn\"}"))
                .andExpect(status().isOk());

        mvc.perform(get("/admin/disputes").param("resolved", "true").param("size", "100").with(as(admin, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.orderId == " + order + ")].resolvedByName").value("Admin Phân Xử"))
                .andExpect(jsonPath("$.items[?(@.orderId == " + order + ")].resolvedAt").isNotEmpty());
        mvc.perform(get("/admin/disputes").param("size", "100").with(as(admin, Role.ADMIN)))
                .andExpect(jsonPath("$.items[?(@.orderId == " + order + ")]").isEmpty());
    }

    @Test
    void reviewedListingsShowWhoReviewedAndWhen() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin Duyệt Tin", 0);
        long pending = createListing("PENDING_REVIEW");
        long other = createListing("PENDING_REVIEW");

        mvc.perform(post("/admin/listings/" + pending + "/approve").with(as(admin, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reviewedBy").value(admin))
                .andExpect(jsonPath("$.reviewedByName").value("Admin Duyệt Tin"))
                .andExpect(jsonPath("$.reviewedAt").isNotEmpty());
        mvc.perform(post("/admin/listings/" + other + "/reject").with(as(admin, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"Ảnh mờ\"}"))
                .andExpect(status().isOk());

        // Mới nhất trước: tin vừa từ chối đứng trước tin vừa duyệt.
        mvc.perform(get("/admin/listings/reviewed").param("size", "100").with(as(admin, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].id").value(other))
                .andExpect(jsonPath("$.items[0].status").value("REJECTED"))
                .andExpect(jsonPath("$.items[1].id").value(pending))
                .andExpect(jsonPath("$.items[1].reviewedByName").value("Admin Duyệt Tin"));
        // Chưa duyệt thì không có trong danh sách.
        mvc.perform(get("/admin/listings/reviewed").param("size", "100").with(as(admin, Role.ADMIN)))
                .andExpect(jsonPath("$.items[?(@.reviewedBy == null)]").isEmpty());
        // Người dùng thường không xem được.
        long user = createUser(Role.USER, "Khách", 0);
        mvc.perform(get("/admin/listings/reviewed").with(as(user, Role.USER))).andExpect(status().isForbidden());
    }

    @Test
    void withdrawalKeepsTheSellersNoteApartFromTheAdminNote() throws Exception {
        long me = createUser(Role.USER, "Người rút", 500_000);
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"amount":100000,"bankName":"VCB","accountNumber":"0123","accountHolder":"NGUYEN A",
                                 "note":"  Rut tien ban sach thang 11  "}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.userNote").value("Rut tien ban sach thang 11"))
                .andExpect(jsonPath("$.note").doesNotExist());
        // Không ghi chú vẫn tạo được.
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"amount":100000,"bankName":"VCB","accountNumber":"0123","accountHolder":"NGUYEN A"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.userNote").doesNotExist());
    }
}
