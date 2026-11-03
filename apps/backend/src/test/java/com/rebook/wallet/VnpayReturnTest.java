package com.rebook.wallet;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.web.util.UriComponentsBuilder;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;
import java.util.Map;
import java.util.StringJoiner;
import java.util.TreeMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** VNPay đã cấu hình (mã giả cho test): link thanh toán có chữ ký, trang quay về xác nhận giao dịch và cộng ví. */
@TestPropertySource(properties = {
        "app.payment.vnpay.tmn-code=TESTTMN1",
        "app.payment.vnpay.hash-secret=TESTSECRETTESTSECRETTESTSECRET12"
})
class VnpayReturnTest extends IntegrationTest {

    private static final String SECRET = "TESTSECRETTESTSECRETTESTSECRET12";

    /** Tạo phiên nạp 100.000đ, trả về các tham số trong link VNPay. */
    private Map<String, String> topUp(long userId) throws Exception {
        String body = mvc.perform(post("/wallet/top-up").with(as(userId, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":100000}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.paymentUrl").value(containsString("sandbox.vnpayment.vn")))
                // Có VNPay thật thì app không hiện nút giả lập.
                .andExpect(jsonPath("$.simulateAvailable").value(false))
                .andReturn().getResponse().getContentAsString();
        String url = body.replaceAll(".*\"paymentUrl\":\"([^\"]+)\".*", "$1");
        Map<String, String> params = new TreeMap<>();
        UriComponentsBuilder.fromUriString(url).build().getQueryParams()
                .forEach((k, v) -> params.put(k, java.net.URLDecoder.decode(v.getFirst(), StandardCharsets.US_ASCII)));
        return params;
    }

    /** Tham số VNPay gửi về khi giao dịch thành công, ký bằng [secret]. */
    private static Map<String, String> callback(Map<String, String> link, String responseCode, String secret) throws Exception {
        Map<String, String> p = new TreeMap<>();
        p.put("vnp_TmnCode", link.get("vnp_TmnCode"));
        p.put("vnp_Amount", link.get("vnp_Amount"));
        p.put("vnp_TxnRef", link.get("vnp_TxnRef"));
        p.put("vnp_OrderInfo", link.get("vnp_OrderInfo"));
        p.put("vnp_ResponseCode", responseCode);
        p.put("vnp_TransactionStatus", responseCode);
        p.put("vnp_TransactionNo", "1" + System.nanoTime() % 100000000);
        p.put("vnp_BankCode", "NCB");
        p.put("vnp_PayDate", "20261104100000");
        StringJoiner data = new StringJoiner("&");
        p.forEach((k, v) -> data.add(URLEncoder.encode(k, StandardCharsets.US_ASCII) + "="
                + URLEncoder.encode(v, StandardCharsets.US_ASCII)));
        Mac mac = Mac.getInstance("HmacSHA512");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
        p.put("vnp_SecureHash", HexFormat.of().formatHex(mac.doFinal(data.toString().getBytes(StandardCharsets.UTF_8))));
        return p;
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder returnRequest(Map<String, String> p) {
        var req = get("/payments/vnpay/return");
        p.forEach((k, v) -> req.param(k, v));
        return req;
    }

    @Test
    void paymentLinkIsSignedAndUsesIpv4ForLocalhost() throws Exception {
        long user = createUser(Role.USER, "Người nạp", 0);
        Map<String, String> link = topUp(user);
        assertThat(link.get("vnp_TmnCode")).isEqualTo("TESTTMN1");
        assertThat(link.get("vnp_Amount")).isEqualTo("10000000");
        assertThat(link.get("vnp_IpAddr")).isEqualTo("127.0.0.1");
        assertThat(link.get("vnp_SecureHash")).hasSize(128);
    }

    @Test
    void successfulReturnCreditsWalletAndShowsAPage() throws Exception {
        long user = createUser(Role.USER, "Người nạp", 0);
        Map<String, String> link = topUp(user);

        mvc.perform(returnRequest(callback(link, "00", SECRET)))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(containsString("Thanh toán thành công")))
                .andExpect(content().string(containsString(link.get("vnp_TxnRef"))))
                // Nút + tự chuyển về màn kết quả thanh toán trong app.
                .andExpect(content().string(containsString(
                        "href=\"http://localhost:5199/home/payments/" + link.get("vnp_TxnRef") + "\"")));
        assertThat(walletAvailable(user)).isEqualTo(100_000);

        // Tải lại trang: không cộng lần hai, vẫn báo thành công.
        mvc.perform(returnRequest(callback(link, "00", SECRET)))
                .andExpect(content().string(containsString("Thanh toán thành công")));
        assertThat(walletAvailable(user)).isEqualTo(100_000);
    }

    @Test
    void wrongSignatureOrCancelledPaymentDoesNotCredit() throws Exception {
        long user = createUser(Role.USER, "Người nạp", 0);
        Map<String, String> link = topUp(user);

        mvc.perform(returnRequest(callback(link, "00", "sai-khoa-bi-mat")))
                .andExpect(content().string(containsString("Thanh toán không thành công")));
        mvc.perform(returnRequest(callback(link, "24", SECRET)))  // 24 = khách huỷ giao dịch
                .andExpect(content().string(containsString("Thanh toán không thành công")));
        assertThat(walletAvailable(user)).isZero();
        assertThat(jdbc.queryForObject("SELECT status FROM payments WHERE code = ?", String.class, link.get("vnp_TxnRef")))
                .isEqualTo("FAILED");
    }
}
