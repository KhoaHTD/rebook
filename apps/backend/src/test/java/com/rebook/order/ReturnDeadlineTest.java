package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Yêu cầu trả hàng không được treo mãi khi người bán im lặng. */
class ReturnDeadlineTest extends IntegrationTest {

    @Autowired
    OrderJobs jobs;

    private long buyerId;
    private long orderId;

    @BeforeEach
    void setUp() throws Exception {
        buyerId = createUser(Role.USER, "Người Mua", 0);
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        orderId = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, subtotal, total, delivered_at)
                VALUES (?, ?, ?, 'NORMAL', 'DELIVERED', 'COD', 50000, 50000, now() - interval '1 day') RETURNING id""",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyerId, shop);

        mvc.perform(post("/orders/" + orderId + "/return").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"MISSING_PAGES","description":"Thiếu trang 10-20","images":["/files/a.png"]}"""))
                .andExpect(status().isOk());
    }

    private String returnStatus() {
        return jdbc.queryForObject("SELECT status FROM return_requests WHERE order_id = ?", String.class, orderId);
    }

    @Test
    void unansweredReturnGoesToAdminAfterDeadline() {
        jobs.run();
        assertThat(returnStatus()).isEqualTo("PENDING"); // chưa quá hạn

        jdbc.update("UPDATE return_requests SET created_at = now() - interval '3 day' WHERE order_id = ?", orderId);
        jobs.run();

        assertThat(returnStatus()).isEqualTo("DISPUTED");
        assertThat(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId))
                .isEqualTo("RETURN_REQUESTED");
    }

    @Test
    void buyerConfirmingReceiptClosesTheReturnRequest() throws Exception {
        mvc.perform(post("/orders/" + orderId + "/confirm-received").with(as(buyerId, Role.USER)))
                .andExpect(status().isOk());

        assertThat(returnStatus()).isEqualTo("REJECTED");
        assertThat(jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId)).isEqualTo("COMPLETED");
    }
}
