package com.rebook.wallet;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.config.AppProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Cổng ZaloPay (API v2, HMAC-SHA256): tạo đơn → app mở {@code order_url}; ZaloPay đưa trình duyệt về return URL;
 * backend truy vấn lại trạng thái để chốt (máy dev chạy localhost nên ZaloPay không gọi callback được).
 * Tài liệu: https://developers.zalopay.vn/v2/general/overview.html
 */
@Component
@RequiredArgsConstructor
public class ZaloPayGateway {

    private static final DateTimeFormatter YYMMDD = DateTimeFormatter.ofPattern("yyMMdd").withZone(CodeGenerator.VN);
    /** ZaloPay chỉ nhận hạn thanh toán từ 5 phút. */
    private static final long MIN_EXPIRE_SECONDS = 300;

    private final AppProperties props;
    private final ZaloPayClient client;
    private final ObjectMapper json;

    /** Kết quả truy vấn: 1 thành công, 2 thất bại, 3 chưa thanh toán / đang xử lý. */
    public record QueryResult(int returnCode, String zpTransId, BigDecimal amount, String message) {

        public boolean paid() {
            return returnCode == 1;
        }

        public boolean failed() {
            return returnCode == 2;
        }
    }

    public boolean isConfigured() {
        var z = props.payment().zalopay();
        return z != null && notBlank(z.appId()) && notBlank(z.key1()) && notBlank(z.key2());
    }

    /** Mã đơn phía ZaloPay: bắt đầu bằng ngày (giờ VN) yyMMdd, duy nhất. */
    public static String appTransId(Instant createdAt, String paymentCode) {
        return YYMMDD.format(createdAt) + "_" + paymentCode;
    }

    /** Tạo đơn trên ZaloPay, trả về link thanh toán ({@code order_url}). */
    public String createOrder(String appTransId, Long userId, BigDecimal amount, String description, Duration ttl) {
        return createOrder(appTransId, userId, amount, description, ttl, null);
    }

    /** [returnUrl] khác null thì ZaloPay đưa trình duyệt về địa chỉ đó thay vì địa chỉ trong cấu hình. */
    public String createOrder(String appTransId, Long userId, BigDecimal amount, String description, Duration ttl, String returnUrl) {
        var z = props.payment().zalopay();
        String appTime = String.valueOf(Instant.now().toEpochMilli());
        String appUser = "rebook_" + userId;
        String embedData = toJson(Map.of("redirecturl", returnUrl == null || returnUrl.isBlank() ? z.returnUrl() : returnUrl));
        String item = "[]";
        String amountText = amount.toBigInteger().toString();
        String mac = hmac(z.key1(), String.join("|", z.appId(), appTransId, appUser, amountText, appTime, embedData, item));

        Map<String, String> form = new LinkedHashMap<>();
        form.put("app_id", z.appId());
        form.put("app_user", appUser);
        form.put("app_trans_id", appTransId);
        form.put("app_time", appTime);
        form.put("amount", amountText);
        form.put("item", item);
        form.put("embed_data", embedData);
        form.put("description", description);
        form.put("bank_code", "");
        form.put("expire_duration_seconds", String.valueOf(Math.max(MIN_EXPIRE_SECONDS, ttl.toSeconds())));
        if (notBlank(z.callbackUrl())) {
            form.put("callback_url", z.callbackUrl());
        }
        form.put("mac", mac);

        Map<String, Object> res = client.post(z.endpoint() + "/create", form);
        Object url = res.get("order_url");
        if (!"1".equals(String.valueOf(res.get("return_code"))) || url == null) {
            throw new ApiException(HttpStatus.BAD_GATEWAY, "PAYMENT_GATEWAY_ERROR",
                    "ZaloPay từ chối tạo đơn: " + res.getOrDefault("sub_return_message", res.get("return_message")));
        }
        return url.toString();
    }

    /** Hỏi ZaloPay trạng thái đơn (nguồn tin cậy duy nhất để chốt thanh toán). */
    public QueryResult query(String appTransId) {
        var z = props.payment().zalopay();
        Map<String, String> form = new LinkedHashMap<>();
        form.put("app_id", z.appId());
        form.put("app_trans_id", appTransId);
        form.put("mac", hmac(z.key1(), z.appId() + "|" + appTransId + "|" + z.key1()));
        Map<String, Object> res = client.post(z.endpoint() + "/query", form);
        int code = Integer.parseInt(String.valueOf(res.getOrDefault("return_code", "3")));
        Object zpTransId = res.get("zp_trans_id");
        Object amount = res.get("amount");
        return new QueryResult(code,
                zpTransId == null || "0".equals(zpTransId.toString()) ? null : zpTransId.toString(),
                amount == null ? null : new BigDecimal(amount.toString()),
                String.valueOf(res.get("return_message")));
    }

    /** Kiểm checksum của các tham số ZaloPay gắn vào redirect URL. */
    public boolean verifyRedirect(Map<String, String> p) {
        if (!isConfigured() || p.get("checksum") == null) {
            return false;
        }
        String data = String.join("|", nz(p.get("appid")), nz(p.get("apptransid")), nz(p.get("pmcid")),
                nz(p.get("bankcode")), nz(p.get("amount")), nz(p.get("discountamount")), nz(p.get("status")));
        return hmac(props.payment().zalopay().key2(), data).equalsIgnoreCase(p.get("checksum"));
    }

    /** Kiểm chữ ký callback server-to-server: mac = HMAC(key2, data). */
    public boolean verifyCallback(String data, String mac) {
        return isConfigured() && data != null && mac != null
                && hmac(props.payment().zalopay().key2(), data).equalsIgnoreCase(mac);
    }

    static String hmac(String key, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Không ký được dữ liệu ZaloPay", e);
        }
    }

    private String toJson(Object value) {
        try {
            return json.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }
}
