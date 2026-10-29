package com.rebook.order;

import com.jayway.jsonpath.JsonPath;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Người mua thanh toán lại đơn đang chờ: giao dịch VNPay cũ thành công muộn không được làm mất tiền. */
class RepayOrderTest extends IntegrationTest {

    private long buyerId;
    private long addressId;
    private long category;

    @BeforeEach
    void setUp() {
        buyerId = createUser(Role.USER, "Người Mua", 1_000_000);
        addressId = jdbc.queryForObject("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người Mua', '0900000000', 'Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi') RETURNING id""",
                Long.class, buyerId);
        category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "test-" + UUID.randomUUID());
    }

    private long createListing(long price) {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, owner, "Sách " + UUID.randomUUID(), category);
        return jdbc.queryForObject("""
                INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, ?, 3, 'ACTIVE') RETURNING id""",
                Long.class, book, shop, price);
    }

    private String checkoutVnpay(long... listings) throws Exception {
        for (long l : listings) {
            mvc.perform(post("/cart").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                    .content("{\"listingId\":" + l + ",\"quantity\":1}")).andExpect(status().isOk());
        }
        return mvc.perform(post("/orders/checkout").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"addressId\":" + addressId + ",\"paymentMethod\":\"VNPAY\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
    }

    private String pay(long orderId, String method) throws Exception {
        return mvc.perform(post("/orders/" + orderId + "/pay").with(as(buyerId, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"method\":\"" + method + "\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
    }

    private void simulate(String paymentCode) throws Exception {
        mvc.perform(post("/payments/" + paymentCode + "/simulate").with(as(buyerId, Role.USER))).andExpect(status().isOk());
    }

    private String orderStatus(long orderId) {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, orderId);
    }

    private long amountDue(long orderId) {
        return jdbc.queryForObject("SELECT total - deposit_applied FROM orders WHERE id = ?", Long.class, orderId);
    }

    @Test
    void lateVnpayAfterPayingOneOrderByWalletRefundsThatShare() throws Exception {
        String body = checkoutVnpay(createListing(100_000), createListing(50_000));
        List<Integer> ids = JsonPath.read(body, "$.orders[*].id");
        String oldCode = JsonPath.read(body, "$.payment.code");
        long first = ids.get(0);
        long second = ids.get(1);

        pay(first, "WALLET");
        long afterWallet = walletAvailable(buyerId);
        assertThat(afterWallet).isEqualTo(1_000_000 - amountDue(first));

        simulate(oldCode); // VNPay cũ vẫn trừ tiền người mua đủ cho cả hai đơn

        assertThat(orderStatus(first)).isEqualTo("PENDING_CONFIRM");
        assertThat(orderStatus(second)).isEqualTo("PENDING_CONFIRM");
        // phần của đơn đầu đã trả bằng ví → hoàn lại vào ví
        assertThat(walletAvailable(buyerId)).isEqualTo(afterWallet + amountDue(first));
    }

    @Test
    void oldVnpayLinkSucceedingAfterNewLinkWasCreatedIsRefunded() throws Exception {
        String body = checkoutVnpay(createListing(80_000));
        long order = ((Integer) JsonPath.read(body, "$.orders[0].id")).longValue();
        String oldCode = JsonPath.read(body, "$.payment.code");

        String newCode = JsonPath.read(pay(order, "VNPAY"), "$.payment.code");

        simulate(oldCode);
        // Link cũ không còn gắn với đơn: tiền vào ví, đơn vẫn chờ link mới
        assertThat(walletAvailable(buyerId)).isEqualTo(1_000_000 + amountDue(order));
        assertThat(orderStatus(order)).isEqualTo("PENDING_PAYMENT");

        simulate(newCode);
        assertThat(orderStatus(order)).isEqualTo("PENDING_CONFIRM");
        assertThat(walletAvailable(buyerId)).isEqualTo(1_000_000 + amountDue(order));
    }
}
