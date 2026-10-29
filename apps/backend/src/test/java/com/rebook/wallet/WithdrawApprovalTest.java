package com.rebook.wallet;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WithdrawApprovalTest extends IntegrationTest {

    private long adminId;
    private long userId;
    private long withdrawId;

    @BeforeEach
    void setUp() throws Exception {
        adminId = createUser(Role.ADMIN, "Admin Duyệt", 0);
        userId = createUser(Role.USER, "Người Rút", 500_000);
        String body = mvc.perform(post("/wallet/withdrawals").with(as(userId, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"amount":200000,"bankName":"VCB","accountNumber":"0123456789","accountHolder":"NGUOI RUT"}"""))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        withdrawId = Long.parseLong(body.replaceAll(".*\"id\":(\\d+).*", "$1"));
    }

    private ResultActions approve(String json) throws Exception {
        return mvc.perform(post("/admin/withdrawals/" + withdrawId).with(as(adminId, Role.ADMIN))
                .contentType(MediaType.APPLICATION_JSON).content(json));
    }

    private String approveJson(String sender, String time, String amount, String proof) {
        return """
                {"approve":true,"note":"ok","senderName":%s,"transferTime":%s,"transferAmount":%s,"proofImageUrl":%s}"""
                .formatted(sender, time, amount, proof);
    }

    private String withdrawStatus() {
        return jdbc.queryForObject("SELECT status FROM withdraw_requests WHERE id = ?", String.class, withdrawId);
    }

    @Test
    void requestHoldsMoney() {
        assertThat(walletAvailable(userId)).isEqualTo(300_000);
        assertThat(walletHeld(userId)).isEqualTo(200_000);
    }

    @Test
    void approveWithoutTransferInfoIsRejectedAndNothingChanges() throws Exception {
        approve("{\"approve\":true,\"note\":\"ok\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("TRANSFER_INFO_REQUIRED"));

        assertThat(withdrawStatus()).isEqualTo("PENDING");
        assertThat(walletHeld(userId)).isEqualTo(200_000);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM withdraw_transfers WHERE withdraw_id = ?", Long.class, withdrawId)).isZero();
    }

    @Test
    void approveWithMismatchedAmountIsRejected() throws Exception {
        approve(approveJson("\"Sàn ReBook\"", "\"" + Instant.now().minusSeconds(60) + "\"", "150000", "\"/files/a.png\""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("TRANSFER_AMOUNT_MISMATCH"));
        assertThat(withdrawStatus()).isEqualTo("PENDING");
    }

    @Test
    void approveWithFutureTransferTimeIsRejected() throws Exception {
        approve(approveJson("\"Sàn ReBook\"", "\"" + Instant.now().plusSeconds(3600) + "\"", "200000", "\"/files/a.png\""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_TRANSFER_TIME"));
    }

    @Test
    void approveWithoutProofImageIsRejected() throws Exception {
        approve(approveJson("\"Sàn ReBook\"", "\"" + Instant.now().minusSeconds(60) + "\"", "200000", "\"\""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("TRANSFER_INFO_REQUIRED"));
    }

    @Test
    void approveStoresLedgerEntryReceiptAndActivityLog() throws Exception {
        Instant transferTime = Instant.now().minusSeconds(120);
        approve(approveJson("\"Sàn ReBook\"", "\"" + transferTime + "\"", "200000", "\"/files/proof.png\""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"))
                .andExpect(jsonPath("$.processedBy").value(adminId))
                .andExpect(jsonPath("$.processedByName").value("Admin Duyệt"))
                .andExpect(jsonPath("$.userName").value("Người Rút"))
                .andExpect(jsonPath("$.transfer.senderName").value("Sàn ReBook"))
                .andExpect(jsonPath("$.transfer.amount").value(200000))
                .andExpect(jsonPath("$.transfer.proofImageUrl").value("/files/proof.png"));

        // Bản ghi 1: ví người rút bị trừ thật, có dòng sổ cái
        assertThat(withdrawStatus()).isEqualTo("APPROVED");
        assertThat(walletHeld(userId)).isZero();
        assertThat(walletAvailable(userId)).isEqualTo(300_000);
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM wallet_transactions t JOIN wallets w ON w.id = t.wallet_id
                WHERE w.user_id = ? AND t.ref_type = 'WITHDRAW' AND t.ref_id = ? AND t.held_change = -200000""",
                Long.class, userId, withdrawId)).isEqualTo(1);

        // Bản ghi 2: biên lai chuyển khoản
        var receipt = jdbc.queryForMap("SELECT * FROM withdraw_transfers WHERE withdraw_id = ?", withdrawId);
        assertThat(receipt.get("admin_id")).isEqualTo(adminId);
        assertThat(receipt.get("sender_name")).isEqualTo("Sàn ReBook");
        assertThat(receipt.get("proof_image_url")).isEqualTo("/files/proof.png");
        assertThat(((Number) receipt.get("amount")).longValue()).isEqualTo(200_000);

        // Nhật ký Admin
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM admin_activity_logs
                WHERE admin_id = ? AND action = 'APPROVE_WITHDRAWAL' AND target_id = ?""",
                Long.class, adminId, String.valueOf(withdrawId))).isEqualTo(1);
    }

    @Test
    void secondApproveIsConflict() throws Exception {
        String json = approveJson("\"Sàn ReBook\"", "\"" + Instant.now().minusSeconds(60) + "\"", "200000", "\"/files/a.png\"");
        approve(json).andExpect(status().isOk());
        approve(json).andExpect(status().isConflict());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM withdraw_transfers WHERE withdraw_id = ?", Long.class, withdrawId)).isEqualTo(1);
    }

    @Test
    void rejectReleasesMoneyWithoutReceiptAndIsLogged() throws Exception {
        approve("{\"approve\":false,\"note\":\"Sai số tài khoản\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"))
                .andExpect(jsonPath("$.processedByName").value("Admin Duyệt"));

        assertThat(walletHeld(userId)).isZero();
        assertThat(walletAvailable(userId)).isEqualTo(500_000);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM withdraw_transfers WHERE withdraw_id = ?", Long.class, withdrawId)).isZero();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM admin_activity_logs WHERE action = 'REJECT_WITHDRAWAL' AND target_id = ?""",
                Long.class, String.valueOf(withdrawId))).isEqualTo(1);
    }

    @Test
    void historyListShowsProcessedRequestsWithApprover() throws Exception {
        approve("{\"approve\":false,\"note\":\"x\"}").andExpect(status().isOk());

        mvc.perform(get("/admin/withdrawals").param("status", "REJECTED").param("size", "100").with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.id==" + withdrawId + ")].processedByName").value("Admin Duyệt"));
        mvc.perform(get("/admin/withdrawals").param("size", "100").with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.id==" + withdrawId + ")]").isEmpty());
    }

    @Test
    void activityLogEndpointListsAdminActionsAndIsAdminOnly() throws Exception {
        approve("{\"approve\":false,\"note\":\"x\"}").andExpect(status().isOk());

        mvc.perform(get("/admin/activity-logs").param("targetType", "WITHDRAWAL").param("size", "100").with(as(adminId, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.targetId=='" + withdrawId + "')].adminName").value("Admin Duyệt"))
                .andExpect(jsonPath("$.items[?(@.targetId=='" + withdrawId + "')].action").value("REJECT_WITHDRAWAL"));
        mvc.perform(get("/admin/activity-logs").with(as(userId, Role.USER))).andExpect(status().isForbidden());
    }
}
