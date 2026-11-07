package com.rebook.wallet;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.net.URI;
import java.util.Arrays;
import java.util.List;

/**
 * Địa chỉ công khai mà người dùng đang vào app (link Cloudflare khi demo online), để ZaloPay đưa họ quay về đúng chỗ
 * thay vì địa chỉ localhost trong cấu hình.
 *
 * <p>Máy chủ demo (apps/frontend/tool/demo_server.dart) gắn header {@code X-Public-Url} vào yêu cầu đi qua Cloudflare.
 * Header chỉ được tin khi là https và tên miền nằm trong danh sách cho phép ({@code app.payment.public-host-suffixes}),
 * nên người ngoài không thể bắt ZaloPay đưa người dùng sang một trang tuỳ ý.
 */
@Component
public class PublicUrl {

    public static final String HEADER = "X-Public-Url";

    private final List<String> allowedSuffixes;
    private final String apiPrefix;

    public PublicUrl(@Value("${app.payment.public-host-suffixes:.trycloudflare.com}") String suffixes,
                     @Value("${app.payment.public-api-prefix:/api}") String apiPrefix) {
        this.allowedSuffixes = Arrays.stream(suffixes.split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).map(String::toLowerCase).toList();
        this.apiPrefix = apiPrefix.endsWith("/") ? apiPrefix.substring(0, apiPrefix.length() - 1) : apiPrefix;
    }

    /** Gốc địa chỉ công khai của yêu cầu đang xử lý (ví dụ https://abc.trycloudflare.com), hoặc null nếu không có / không hợp lệ. */
    public String current() {
        if (!(RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attrs)) {
            return null;
        }
        HttpServletRequest req = attrs.getRequest();
        return validate(req.getHeader(HEADER));
    }

    /** Địa chỉ ZaloPay đưa trình duyệt về sau khi trả tiền, qua đường /api của máy chủ demo. */
    public String zaloPayReturn(String origin) {
        return origin + apiPrefix + "/payments/zalopay/return";
    }

    String validate(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            URI u = URI.create(raw.trim());
            String host = u.getHost() == null ? "" : u.getHost().toLowerCase();
            boolean pathOk = u.getPath() == null || u.getPath().isEmpty() || u.getPath().equals("/");
            boolean allowed = allowedSuffixes.stream().anyMatch(host::endsWith);
            if (!"https".equalsIgnoreCase(u.getScheme()) || !allowed || !pathOk || u.getUserInfo() != null
                    || u.getQuery() != null || u.getFragment() != null || u.getPort() != -1) {
                return null;
            }
            return "https://" + host;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
