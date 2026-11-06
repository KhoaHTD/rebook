package com.rebook.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.auth.AuthDtos.AuthResponse;
import com.rebook.common.ApiException;
import com.rebook.config.AppProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Đăng nhập bằng Google theo luồng "authorization code" chạy ở server (không cần SDK Google trong app):
 * app mở {@code /auth/google/login} trong trình duyệt → Google → {@code /auth/google/callback} (server đổi code lấy ID token,
 * kiểm tra email đã xác minh) → chuyển về app kèm một vé dùng một lần → app gọi {@code POST /auth/google/exchange} đổi vé lấy token.
 * Không đặt token vào URL; vé sống 2 phút và chỉ dùng được một lần.
 */
@Slf4j
@Service
public class GoogleAuthService {

    static final String AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
    static final String TOKEN_URL = "https://oauth2.googleapis.com/token";
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final long TICKET_SECONDS = 120;
    private static final long STATE_SECONDS = 600;

    /** Danh tính Google đã xác minh. */
    public record GoogleIdentity(String email, String name, String picture) {
    }

    /** Đổi code lấy ID token (tách riêng để test không gọi Google thật). */
    public interface TokenExchanger {
        String idToken(String code, String clientId, String clientSecret, String redirectUri);
    }

    private record Ticket(GoogleIdentity identity, Instant expiresAt) {
    }

    private final AuthService authService;
    private final AppProperties props;
    private final ObjectMapper json;
    private final TokenExchanger exchanger;
    private final String clientId;
    private final String clientSecret;
    private final String redirectUri;
    private final String appRedirect;
    private final Map<String, Ticket> tickets = new ConcurrentHashMap<>();

    @org.springframework.beans.factory.annotation.Autowired
    public GoogleAuthService(AuthService authService, AppProperties props, ObjectMapper json,
                             @Value("${app.google.client-id:}") String clientId,
                             @Value("${app.google.client-secret:}") String clientSecret,
                             @Value("${app.google.redirect-uri:http://localhost:8080/auth/google/callback}") String redirectUri,
                             @Value("${app.google.app-redirect:rebook:///auth/google}") String appRedirect) {
        this.authService = authService;
        this.props = props;
        this.json = json;
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.redirectUri = redirectUri;
        this.appRedirect = appRedirect;
        RestClient http = RestClient.create();
        this.exchanger = (code, id, secret, redirect) -> {
            MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
            form.add("code", code);
            form.add("client_id", id);
            form.add("client_secret", secret);
            form.add("redirect_uri", redirect);
            form.add("grant_type", "authorization_code");
            JsonNode body = http.post().uri(TOKEN_URL).contentType(MediaType.APPLICATION_FORM_URLENCODED).body(form)
                    .retrieve().body(JsonNode.class);
            return body == null || body.path("id_token").isMissingNode() ? null : body.get("id_token").asText();
        };
    }

    /** Dành cho test: thay bộ đổi code. */
    GoogleAuthService(AuthService authService, AppProperties props, ObjectMapper json, TokenExchanger exchanger,
                      String clientId, String clientSecret, String redirectUri, String appRedirect) {
        this.authService = authService;
        this.props = props;
        this.json = json;
        this.exchanger = exchanger;
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.redirectUri = redirectUri;
        this.appRedirect = appRedirect;
    }

    public boolean enabled() {
        return !clientId.isBlank() && !clientSecret.isBlank();
    }

    /** Địa chỉ trang đăng nhập của Google; [platform] là "app" (quay về deep link) hoặc "web" (quay về trang web). */
    public String loginUrl(String platform) {
        requireEnabled();
        String state = signState("web".equals(platform) ? "web" : "app");
        return AUTH_URL + "?response_type=code&scope=" + enc("openid email profile") + "&client_id=" + enc(clientId)
                + "&redirect_uri=" + enc(redirectUri) + "&state=" + enc(state) + "&prompt=select_account";
    }

    /** Xử lý Google gọi về: trả địa chỉ để chuyển hướng người dùng (về app / web, kèm vé hoặc mã lỗi). */
    public String callback(String code, String state, String error) {
        String platform = verifyState(state);
        String target = "web".equals(platform) ? props.payment().appUrl() + "/auth/google" : appRedirect;
        if (error != null || code == null) {
            return target + "?error=" + enc(error == null ? "GOOGLE_DENIED" : error);
        }
        try {
            GoogleIdentity who = identityFrom(exchanger.idToken(code, clientId, clientSecret, redirectUri));
            String ticket = newTicket();
            tickets.put(ticket, new Ticket(who, Instant.now().plusSeconds(TICKET_SECONDS)));
            return target + "?ticket=" + enc(ticket);
        } catch (ApiException e) {
            return target + "?error=" + enc(e.getCode());
        } catch (RuntimeException e) {
            log.warn("Đăng nhập Google lỗi: {}", e.toString());
            return target + "?error=GOOGLE_FAILED";
        }
    }

    /** App đổi vé lấy token (vé dùng một lần). */
    public AuthResponse exchange(String ticket) {
        tickets.values().removeIf(t -> t.expiresAt().isBefore(Instant.now()));
        Ticket t = ticket == null ? null : tickets.remove(ticket);
        if (t == null || t.expiresAt().isBefore(Instant.now())) {
            throw ApiException.unauthorized("INVALID_GOOGLE_TICKET", "Phiên đăng nhập Google đã hết hạn, hãy thử lại");
        }
        return authService.loginWithGoogle(t.identity().email(), t.identity().name(), t.identity().picture());
    }

    // ---- nội bộ ----

    private void requireEnabled() {
        if (!enabled()) {
            throw new ApiException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE, "GOOGLE_NOT_CONFIGURED",
                    "Đăng nhập Google chưa được cấu hình trên máy chủ");
        }
    }

    /** ID token nhận trực tiếp từ Google qua TLS nên chỉ cần kiểm tra các trường, không cần kiểm chữ ký. */
    GoogleIdentity identityFrom(String idToken) {
        if (idToken == null) {
            throw ApiException.unauthorized("GOOGLE_FAILED", "Google không trả về ID token");
        }
        try {
            String[] parts = idToken.split("\\.");
            JsonNode claims = json.readTree(Base64.getUrlDecoder().decode(parts[1]));
            String aud = claims.path("aud").asText();
            String iss = claims.path("iss").asText();
            boolean verified = "true".equalsIgnoreCase(claims.path("email_verified").asText());
            String email = claims.path("email").asText("");
            if (!clientId.equals(aud) || !(iss.equals("accounts.google.com") || iss.equals("https://accounts.google.com"))) {
                throw ApiException.unauthorized("GOOGLE_FAILED", "ID token không dành cho ứng dụng này");
            }
            if (!verified || email.isBlank()) {
                throw ApiException.unauthorized("GOOGLE_EMAIL_UNVERIFIED", "Email Google chưa được xác minh");
            }
            long exp = claims.path("exp").asLong(0);
            if (exp != 0 && exp < Instant.now().getEpochSecond()) {
                throw ApiException.unauthorized("GOOGLE_FAILED", "ID token đã hết hạn");
            }
            return new GoogleIdentity(email, claims.path("name").asText(""), claims.path("picture").asText(null));
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            throw ApiException.unauthorized("GOOGLE_FAILED", "ID token không hợp lệ");
        }
    }

    private String newTicket() {
        byte[] b = new byte[32];
        RANDOM.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    /** state = platform.hạn.chữ ký (HMAC-SHA256 bằng khoá JWT) để chống giả mạo callback. */
    String signState(String platform) {
        String body = platform + "." + (Instant.now().getEpochSecond() + STATE_SECONDS) + "." + newTicket().substring(0, 10);
        return body + "." + hmac(body);
    }

    String verifyState(String state) {
        String[] p = state == null ? new String[0] : state.split("\\.");
        if (p.length != 4 || !MessageDigest.isEqual(hmac(p[0] + "." + p[1] + "." + p[2]).getBytes(StandardCharsets.UTF_8),
                p[3].getBytes(StandardCharsets.UTF_8)) || Long.parseLong(p[1]) < Instant.now().getEpochSecond()) {
            throw ApiException.badRequest("BAD_GOOGLE_STATE", "Yêu cầu đăng nhập Google không hợp lệ hoặc đã hết hạn");
        }
        return p[0];
    }

    private String hmac(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(props.jwt().secret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static String enc(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
