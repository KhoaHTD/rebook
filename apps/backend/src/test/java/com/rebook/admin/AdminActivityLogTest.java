package com.rebook.admin;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Duyệt tin đăng và khoá tài khoản phải để lại dấu vết người thao tác. */
class AdminActivityLogTest extends IntegrationTest {

    private long adminId;
    private long listingId;

    @BeforeEach
    void setUp() {
        adminId = createUser(Role.ADMIN, "Admin Kiểm Duyệt", 0);
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "test-" + UUID.randomUUID());
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hà Nội', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, 'Sách chờ duyệt', 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, owner, category);
        listingId = jdbc.queryForObject("""
                INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 50000, 2, 'PENDING_REVIEW') RETURNING id""",
                Long.class, book, shop);
    }

    private long logCount(String action, Object targetId) {
        return jdbc.queryForObject("SELECT count(*) FROM admin_activity_logs WHERE admin_id = ? AND action = ? AND target_id = ?",
                Long.class, adminId, action, String.valueOf(targetId));
    }

    @Test
    void approvingAListingIsLoggedWithTheAdmin() throws Exception {
        mvc.perform(post("/admin/listings/" + listingId + "/approve").with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        assertThat(logCount("APPROVE_LISTING", listingId)).isEqualTo(1);
        mvc.perform(get("/admin/activity-logs").param("targetType", "LISTING").param("size", "100").with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.targetId=='" + listingId + "')].adminName").value("Admin Kiểm Duyệt"));
    }

    @Test
    void rejectingAListingIsLoggedWithTheReason() throws Exception {
        mvc.perform(post("/admin/listings/" + listingId + "/reject").with(as(adminId, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"Ảnh mờ\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));

        assertThat(logCount("REJECT_LISTING", listingId)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT summary FROM admin_activity_logs WHERE action = 'REJECT_LISTING' AND target_id = ?",
                String.class, String.valueOf(listingId))).contains("Ảnh mờ");
    }

    @Test
    void lockingAndUnlockingAUserIsLogged() throws Exception {
        long target = createUser(Role.USER, "Người vi phạm", 0);

        mvc.perform(post("/admin/users/" + target + "/lock").with(as(adminId, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"Spam\"}"))
                .andExpect(status().isOk());
        mvc.perform(post("/admin/users/" + target + "/unlock").with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk());

        assertThat(logCount("LOCK_USER", target)).isEqualTo(1);
        assertThat(logCount("UNLOCK_USER", target)).isEqualTo(1);
    }

    @Test
    void activityLogsCanBeFilteredByAction() throws Exception {
        mvc.perform(post("/admin/listings/" + listingId + "/approve").with(as(adminId, Role.ADMIN))).andExpect(status().isOk());

        mvc.perform(get("/admin/activity-logs").param("action", "APPROVE_LISTING").param("adminId", String.valueOf(adminId))
                        .with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].action").value("APPROVE_LISTING"));
    }
}
