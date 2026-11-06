package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Đơn trả trước bị coi là đã giao (hết 7 ngày) mà người mua không nhận được sách: khiếu nại "không nhận được hàng"
 * không cần ảnh, không cần gửi trả; được đồng ý là hoàn tiền ngay.
 */
class NotReceivedReturnTest extends IntegrationTest {

    private long buyer;
    private long shopOwner;
    private long orderId;
    private long adminId;

    @BeforeEach
    void setUp() {
        buyer = createUser(Role.USER, "Người Mua", 0);
        shopOwner = createUser(Role.USER, "Chủ shop", 0);
        adminId = createUser(Role.ADMIN, "Admin", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, shopOwner, "Shop " + UUID.randomUUID());
        orderId = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, subtotal, shipping_fee, total,
                                    paid_at, delivered_at)
                VALUES (?, ?, ?, 'NORMAL', 'DELIVERED', 'WALLET', 100000, 20000, 120000, now(), now() - interval '1 day')
                RETURNING id""", Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer, shop);
        jdbc.update("UPDATE wallets SET held_balance = 120000 WHERE user_id = ?", shopOwner); // tiền shop chờ hoàn tất
    }

    private org.springframework.test.web.servlet.ResultActions requestReturn(String reason, String images) throws Exception {
        return mvc.perform(post("/orders/" + orderId + "/return").with(as(buyer, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"" + reason + "\",\"description\":\"Chưa nhận được sách\"" + images + "}"));
    }

    private String orderStatus() {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId);
    }

    @Test
    void otherReasonsStillNeedPhotos() throws Exception {
        requestReturn("MISSING_PAGES", "").andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("IMAGES_REQUIRED"));
        requestReturn("MISSING_PAGES", ",\"images\":[]").andExpect(status().isBadRequest());
    }

    @Test
    void sellerApprovingRefundsAtOnceWithoutReturnShipping() throws Exception {
        requestReturn("NOT_RECEIVED", "").andExpect(status().isOk());

        mvc.perform(post("/seller/orders/" + orderId + "/return-decision").with(as(shopOwner, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approve\":true,\"note\":\"Hãng làm thất lạc\"}"))
                .andExpect(status().isOk());

        assertThat(orderStatus()).isEqualTo("RETURNED");
        assertThat(walletAvailable(buyer)).isEqualTo(120_000);
        assertThat(walletHeld(shopOwner)).isZero();
    }

    @Test
    void adminCanRefundWhenSellerRejects() throws Exception {
        requestReturn("NOT_RECEIVED", ",\"images\":[]").andExpect(status().isOk());
        mvc.perform(post("/seller/orders/" + orderId + "/return-decision").with(as(shopOwner, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approve\":false,\"note\":\"Đã giao rồi\"}"))
                .andExpect(status().isOk());

        // Trước đây Admin hoàn tiền chỉ chuyển sang "chờ người mua gửi trả", người mua không có sách nên mất tiền
        mvc.perform(post("/admin/disputes/" + orderId + "/resolve").with(as(adminId, Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approve\":true,\"note\":\"Shop không có mã vận đơn thật\"}"))
                .andExpect(status().isOk());

        assertThat(orderStatus()).isEqualTo("RETURNED");
        assertThat(walletAvailable(buyer)).isEqualTo(120_000);
        assertThat(walletHeld(shopOwner)).isZero();
    }
}
