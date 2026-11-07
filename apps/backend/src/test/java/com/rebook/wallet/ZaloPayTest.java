package com.rebook.wallet;

import com.jayway.jsonpath.JsonPath;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.endsWith;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** ZaloPay đã cấu hình (khoá giả); phần gọi HTTP tới ZaloPay được thay bằng bản giả. */
@TestPropertySource(properties = {
        "app.payment.zalopay.app-id=9999",
        "app.payment.zalopay.key1=test-key1",
        "app.payment.zalopay.key2=test-key2",
        "app.payment.zalopay.endpoint=https://zalopay.test/v2"
})
class ZaloPayTest extends IntegrationTest {

    private static final String ORDER_URL = "https://qcgateway.zalopay.vn/openinapp?order=abc";

    @MockitoBean
    ZaloPayClient client;

    private void zaloCreates() {
        when(client.post(endsWith("/create"), anyMap()))
                .thenReturn(Map.of("return_code", 1, "order_url", ORDER_URL));
    }

    private void zaloQueryReturns(int code, long amount) {
        when(client.post(endsWith("/query"), anyMap()))
                // zp_trans_id khác nhau mỗi lần: DB test giữ dữ liệu giữa các lần chạy và cột này UNIQUE.
                .thenReturn(Map.of("return_code", code, "amount", amount, "zp_trans_id", System.nanoTime()));
    }

    /** Nạp tiền, trả về mã thanh toán. */
    private String topUp(long userId, long amount) throws Exception {
        String body = mvc.perform(post("/wallet/top-up").with(as(userId, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":" + amount + "}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.paymentUrl").value(ORDER_URL))
                .andExpect(jsonPath("$.simulateAvailable").value(false))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.code");
    }

    private String appTransId(String code) {
        return jdbc.queryForObject("SELECT gateway_ref FROM payments WHERE code = ?", String.class, code);
    }

    /** Tham số ZaloPay gắn vào redirect URL, checksum = HMAC(key2, appid|apptransid|pmcid|bankcode|amount|discountamount|status). */
    private Map<String, String> redirect(String appTransId, long amount, String key2) {
        String data = String.join("|", "9999", appTransId, "38", "", String.valueOf(amount), "0", "1");
        return Map.of("appid", "9999", "apptransid", appTransId, "pmcid", "38", "bankcode", "",
                "amount", String.valueOf(amount), "discountamount", "0", "status", "1",
                "checksum", ZaloPayGateway.hmac(key2, data));
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder returnRequest(Map<String, String> p) {
        var req = get("/payments/zalopay/return");
        p.forEach(req::param);
        return req;
    }

    /** Có ZaloPay thật thì endpoint giả lập cũng phải bị chặn: nếu không ai cũng tự nạp tiền ảo được. */
    @Test
    void simulateIsRefusedWhenZaloPayIsConfigured() throws Exception {
        long user = createUser(Role.USER, "Nạp thử", 0);
        zaloCreates();
        String code = topUp(user, 100_000);

        mvc.perform(post("/payments/" + code + "/simulate").with(as(user, Role.USER)))
                .andExpect(status().isForbidden());

        org.assertj.core.api.Assertions.assertThat(walletAvailable(user)).isZero();
        org.assertj.core.api.Assertions.assertThat(
                jdbc.queryForObject("SELECT status FROM payments WHERE code = ?", String.class, code)).isEqualTo("PENDING");
    }

    @Test
    @SuppressWarnings("unchecked")
    void createOrderIsSignedWithKey1() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 50_000);

        ArgumentCaptor<Map<String, String>> form = ArgumentCaptor.forClass(Map.class);
        verify(client).post(eq("https://zalopay.test/v2/create"), form.capture());
        Map<String, String> f = form.getValue();
        assertThat(f.get("app_trans_id")).isEqualTo(appTransId(code)).matches("\\d{6}_" + code);
        assertThat(f.get("amount")).isEqualTo("50000");
        assertThat(f.get("embed_data")).contains("/payments/zalopay/return");
        String expected = ZaloPayGateway.hmac("test-key1", String.join("|", "9999", f.get("app_trans_id"),
                f.get("app_user"), "50000", f.get("app_time"), f.get("embed_data"), f.get("item")));
        assertThat(f.get("mac")).isEqualTo(expected);
    }

    /** Gọi qua link Cloudflare (máy chủ demo gắn X-Public-Url) thì ZaloPay phải đưa người dùng về đúng link đó, không phải localhost. */
    @Test
    @SuppressWarnings("unchecked")
    void returnUrlFollowsThePublicLinkWhenTheDemoServerSendsIt() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        mvc.perform(post("/wallet/top-up").with(as(user, Role.USER)).header("X-Public-Url", "https://abc-def.trycloudflare.com")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":50000}"))
                .andExpect(status().isCreated());

        ArgumentCaptor<Map<String, String>> form = ArgumentCaptor.forClass(Map.class);
        verify(client).post(eq("https://zalopay.test/v2/create"), form.capture());
        assertThat(form.getValue().get("embed_data"))
                .contains("https:\\/\\/abc-def.trycloudflare.com\\/api\\/payments\\/zalopay\\/return".replace("\\/", "/"))
                .doesNotContain("localhost");
    }

    /** Header lạ (tên miền ngoài danh sách, http, có đường dẫn) bị bỏ qua: không ai bắt ZaloPay đưa người dùng sang trang tuỳ ý. */
    @Test
    @SuppressWarnings("unchecked")
    void foreignPublicUrlHeaderIsIgnored() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        for (String bad : new String[]{"https://evil.example.com", "http://abc.trycloudflare.com",
                "https://abc.trycloudflare.com/x", "https://evil.com/.trycloudflare.com", "https://trycloudflare.com.evil.com"}) {
            mvc.perform(post("/wallet/top-up").with(as(user, Role.USER)).header("X-Public-Url", bad)
                            .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":50000}"))
                    .andExpect(status().isCreated());
        }
        ArgumentCaptor<Map<String, String>> form = ArgumentCaptor.forClass(Map.class);
        verify(client, org.mockito.Mockito.times(5)).post(eq("https://zalopay.test/v2/create"), form.capture());
        for (Map<String, String> f : form.getAllValues()) {
            assertThat(f.get("embed_data")).doesNotContain("evil").doesNotContain("abc.trycloudflare.com");
        }
    }

    /** Điện thoại Android quay về từ ZaloPay: trang kết quả mở lại app bằng deep link, có đường lui về bản web. */
    @Test
    void returnPageOpensTheAndroidAppAndFallsBackToTheWeb() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 50_000);
        zaloQueryReturns(1, 50_000);
        var req = returnRequest(redirect(appTransId(code), 50_000, "test-key2"))
                .header("X-Public-Url", "https://abc-def.trycloudflare.com")
                .header("User-Agent", "Mozilla/5.0 (Linux; Android 16) Chrome/130 Mobile");

        mvc.perform(req)
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("rebook:///home/payments/" + code)))
                .andExpect(content().string(containsString("https://abc-def.trycloudflare.com/home/payments/" + code)))
                .andExpect(content().string(org.hamcrest.Matchers.not(containsString("localhost"))));

        // Trình duyệt máy tính: vẫn chuyển thẳng về bản web, không dùng deep link
        mvc.perform(returnRequest(redirect(appTransId(code), 50_000, "test-key2"))
                        .header("X-Public-Url", "https://abc-def.trycloudflare.com")
                        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0) Chrome/130"))
                .andExpect(content().string(org.hamcrest.Matchers.not(containsString("rebook:///"))))
                .andExpect(content().string(containsString("https://abc-def.trycloudflare.com/home/payments/" + code)));
    }

    @Test
    void returnConfirmsWithQueryCreditsOnceAndShowsAPage() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 50_000);
        zaloQueryReturns(1, 50_000);

        mvc.perform(returnRequest(redirect(appTransId(code), 50_000, "test-key2")))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(containsString("Thanh toán thành công")))
                .andExpect(content().string(containsString("href=\"http://localhost:5199/home/payments/" + code + "\"")));
        assertThat(walletAvailable(user)).isEqualTo(50_000);

        // Tải lại trang: không cộng lần hai.
        mvc.perform(returnRequest(redirect(appTransId(code), 50_000, "test-key2")))
                .andExpect(content().string(containsString("Thanh toán thành công")));
        assertThat(walletAvailable(user)).isEqualTo(50_000);
    }

    @Test
    void wrongChecksumIsRejectedWithoutAskingZaloPay() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 50_000);

        mvc.perform(returnRequest(redirect(appTransId(code), 50_000, "khoa-sai")))
                .andExpect(content().string(containsString("Thanh toán không thành công")));
        verify(client, never()).post(endsWith("/query"), anyMap());
        assertThat(walletAvailable(user)).isZero();
    }

    @Test
    void appPollingAsksZaloPayUntilPaid() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 30_000);

        zaloQueryReturns(3, 0); // chưa thanh toán: trả lại link để app mở lại trang ZaloPay
        mvc.perform(get("/payments/" + code).with(as(user, Role.USER)))
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.paymentUrl").value(ORDER_URL));
        zaloQueryReturns(1, 30_000);
        mvc.perform(get("/payments/" + code).with(as(user, Role.USER)))
                .andExpect(jsonPath("$.status").value("SUCCESS"))
                .andExpect(jsonPath("$.paymentUrl").doesNotExist());
        assertThat(walletAvailable(user)).isEqualTo(30_000);
    }

    @Test
    void queryReportingAnotherAmountDoesNotCredit() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 30_000);
        zaloQueryReturns(1, 1_000);
        mvc.perform(get("/payments/" + code).with(as(user, Role.USER)))
                .andExpect(jsonPath("$.status").value("PENDING"));
        assertThat(walletAvailable(user)).isZero();
    }

    @Test
    void callbackWithValidMacCreditsOnce() throws Exception {
        zaloCreates();
        long user = createUser(Role.USER, "Người nạp", 0);
        String code = topUp(user, 20_000);
        String data = "{\"app_id\":9999,\"app_trans_id\":\"" + appTransId(code) + "\",\"amount\":20000,\"zp_trans_id\":" + System.nanoTime() + "}";
        String body = "{\"data\":" + com.fasterxml.jackson.databind.json.JsonMapper.builder().build().writeValueAsString(data)
                + ",\"mac\":\"" + ZaloPayGateway.hmac("test-key2", data) + "\",\"type\":1}";

        mvc.perform(post("/payments/zalopay/callback").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(jsonPath("$.return_code").value(1));
        mvc.perform(post("/payments/zalopay/callback").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(jsonPath("$.return_code").value(2));
        assertThat(walletAvailable(user)).isEqualTo(20_000);

        String forged = body.replace(ZaloPayGateway.hmac("test-key2", data), "00");
        mvc.perform(post("/payments/zalopay/callback").contentType(MediaType.APPLICATION_JSON).content(forged))
                .andExpect(jsonPath("$.return_code").value(-1));
    }

    @Test
    void zaloPayRefusingTheOrderReturnsAGatewayError() throws Exception {
        when(client.post(endsWith("/create"), anyMap()))
                .thenReturn(Map.of("return_code", 2, "sub_return_message", "Chữ ký không hợp lệ"));
        long user = createUser(Role.USER, "Người nạp", 0);
        mvc.perform(post("/wallet/top-up").with(as(user, Role.USER))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":50000}"))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.code").value("PAYMENT_GATEWAY_ERROR"));
    }
}
