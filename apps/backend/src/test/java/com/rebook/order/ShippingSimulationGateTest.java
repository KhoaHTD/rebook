package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Production (chưa có hãng vận chuyển thật): shop không tự bấm "giao thành công" / "giao thất bại" được. */
@TestPropertySource(properties = "app.shipping.simulate-enabled=false")
class ShippingSimulationGateTest extends IntegrationTest {

    @Test
    void sellerCannotMarkItsOwnOrderDeliveredOrFailedWhenSimulationIsOff() throws Exception {
        long buyer = createUser(Role.USER, "Người mua", 0);
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, subtotal, total, shipped_at)
                VALUES (?, ?, ?, 'NORMAL', 'SHIPPING', 'COD', 50000, 50000, now()) RETURNING id""",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), buyer, shop);

        mvc.perform(post("/seller/orders/" + order + "/delivered").with(as(owner, Role.USER)))
                .andExpect(status().isForbidden());
        mvc.perform(post("/seller/orders/" + order + "/delivery-failed").with(as(owner, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"Khách không nhận\"}"))
                .andExpect(status().isForbidden());
        // Người mua vẫn xác nhận được.
        mvc.perform(post("/orders/" + order + "/confirm-received").with(as(buyer, Role.USER)))
                .andExpect(status().isOk());
    }
}
