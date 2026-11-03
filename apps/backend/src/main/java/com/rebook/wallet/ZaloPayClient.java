package com.rebook.wallet;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import java.util.stream.Collectors;

/** Gửi form tới API ZaloPay và đọc JSON trả về. Tách riêng để test thay bằng bản giả. */
@Component
public class ZaloPayClient {

    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
    private final ObjectMapper json;

    public ZaloPayClient(ObjectMapper json) {
        this.json = json;
    }

    public Map<String, Object> post(String url, Map<String, String> form) {
        String body = form.entrySet().stream()
                .map(e -> enc(e.getKey()) + "=" + enc(e.getValue()))
                .collect(Collectors.joining("&"));
        HttpRequest req = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();
        try {
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            return json.readValue(res.body(), new TypeReference<>() {
            });
        } catch (IOException e) {
            throw gatewayDown(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw gatewayDown(e);
        }
    }

    private static ApiException gatewayDown(Exception cause) {
        ApiException e = new ApiException(HttpStatus.BAD_GATEWAY, "PAYMENT_GATEWAY_ERROR",
                "Không kết nối được ZaloPay, thử lại sau");
        e.initCause(cause);
        return e;
    }

    private static String enc(String s) {
        return URLEncoder.encode(s == null ? "" : s, StandardCharsets.UTF_8);
    }
}
