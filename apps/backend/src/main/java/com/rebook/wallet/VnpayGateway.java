package com.rebook.wallet;

import com.rebook.common.CodeGenerator;
import com.rebook.config.AppProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.Map;
import java.util.StringJoiner;
import java.util.TreeMap;

/**
 * Tạo URL thanh toán và kiểm chữ ký VNPay (API v2.1.0, HMAC-SHA512).
 * Cần VNPAY_TMN_CODE và VNPAY_HASH_SECRET (đăng ký tài khoản sandbox tại sandbox.vnpayment.vn).
 */
@Component
@RequiredArgsConstructor
public class VnpayGateway {

    private static final DateTimeFormatter VNP_DATE = DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(CodeGenerator.VN);

    private final AppProperties props;

    public boolean isConfigured() {
        var v = props.payment().vnpay();
        return v.tmnCode() != null && !v.tmnCode().isBlank() && v.hashSecret() != null && !v.hashSecret().isBlank();
    }

    public String buildPaymentUrl(String txnRef, BigDecimal amount, String orderInfo, String clientIp, Instant expireAt) {
        var v = props.payment().vnpay();
        Map<String, String> params = new TreeMap<>();
        params.put("vnp_Version", "2.1.0");
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", v.tmnCode());
        params.put("vnp_Amount", amount.multiply(BigDecimal.valueOf(100)).toBigInteger().toString());
        params.put("vnp_CurrCode", "VND");
        params.put("vnp_TxnRef", txnRef);
        params.put("vnp_OrderInfo", orderInfo);
        params.put("vnp_OrderType", "other");
        params.put("vnp_Locale", "vn");
        params.put("vnp_ReturnUrl", v.returnUrl());
        params.put("vnp_IpAddr", clientIp == null ? "127.0.0.1" : clientIp);
        params.put("vnp_CreateDate", VNP_DATE.format(Instant.now()));
        params.put("vnp_ExpireDate", VNP_DATE.format(expireAt));

        String query = encode(params);
        return v.payUrl() + "?" + query + "&vnp_SecureHash=" + hmacSha512(v.hashSecret(), query);
    }

    /** Kiểm chữ ký callback (IPN hoặc return URL). */
    public boolean verify(Map<String, String> callbackParams) {
        if (!isConfigured()) {
            return false;
        }
        String received = callbackParams.get("vnp_SecureHash");
        if (received == null) {
            return false;
        }
        Map<String, String> fields = new TreeMap<>();
        callbackParams.forEach((k, val) -> {
            if (k.startsWith("vnp_") && !k.equals("vnp_SecureHash") && !k.equals("vnp_SecureHashType")
                    && val != null && !val.isEmpty()) {
                fields.put(k, val);
            }
        });
        return hmacSha512(props.payment().vnpay().hashSecret(), encode(fields)).equalsIgnoreCase(received);
    }

    private static String encode(Map<String, String> sorted) {
        StringJoiner joiner = new StringJoiner("&");
        sorted.forEach((k, val) -> joiner.add(URLEncoder.encode(k, StandardCharsets.US_ASCII) + "="
                + URLEncoder.encode(val, StandardCharsets.US_ASCII)));
        return joiner.toString();
    }

    private static String hmacSha512(String secret, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA512");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
            return HexFormat.of().formatHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Không ký được dữ liệu VNPay", e);
        }
    }
}
