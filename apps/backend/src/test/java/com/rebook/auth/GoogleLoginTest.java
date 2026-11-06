package com.rebook.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.common.ApiException;
import com.rebook.config.AppProperties;
import com.rebook.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Đăng nhập Google: không gọi Google thật (bộ đổi code được thay bằng bản giả trả ID token dựng sẵn). */
class GoogleLoginTest extends IntegrationTest {

    private static final String CLIENT_ID = "demo-client-id.apps.googleusercontent.com";

    @Autowired AuthService authService;
    @Autowired AppProperties props;
    @Autowired ObjectMapper json;

    private String idToken(String email, boolean verified, String aud) throws Exception {
        String payload = json.writeValueAsString(Map.of("iss", "https://accounts.google.com", "aud", aud, "email", email,
                "email_verified", verified, "name", "Người Dùng Google", "picture", "https://example.com/a.png",
                "exp", System.currentTimeMillis() / 1000 + 3600));
        Base64.Encoder b64 = Base64.getUrlEncoder().withoutPadding();
        return b64.encodeToString("{\"alg\":\"RS256\"}".getBytes(StandardCharsets.UTF_8)) + "."
                + b64.encodeToString(payload.getBytes(StandardCharsets.UTF_8)) + ".sig";
    }

    private GoogleAuthService service(String token) {
        return new GoogleAuthService(authService, props, json, (code, id, secret, redirect) -> token,
                CLIENT_ID, "secret", "http://localhost:8080/auth/google/callback", "rebook:///auth/google");
    }

    private String stateOf(GoogleAuthService g) {
        String url = g.loginUrl("app");
        String enc = url.substring(url.indexOf("state=") + 6, url.indexOf("&prompt"));
        return java.net.URLDecoder.decode(enc, StandardCharsets.UTF_8);
    }

    @Test
    void notConfiguredByDefaultAndTheStatusEndpointSaysSo() throws Exception {
        mvc.perform(get("/auth/google/status")).andExpect(status().isOk()).andExpect(jsonPath("$.enabled").value(false));
        mvc.perform(get("/auth/google/login")).andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("GOOGLE_NOT_CONFIGURED"));
    }

    @Test
    void newGoogleUserGetsAnAccountAndWalletAndAReusableLogin() throws Exception {
        String email = "gg-" + UUID.randomUUID() + "@gmail.com";
        GoogleAuthService g = service(idToken(email, true, CLIENT_ID));

        String redirect = g.callback("code", stateOf(g), null);
        assertThat(redirect).startsWith("rebook:///auth/google?ticket=");
        String ticket = java.net.URLDecoder.decode(redirect.substring(redirect.indexOf("ticket=") + 7), StandardCharsets.UTF_8);

        var first = g.exchange(ticket);
        assertThat(first.user().email()).isEqualTo(email);
        assertThat(first.user().role().name()).isEqualTo("USER");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM wallets WHERE user_id = ?", Long.class, first.user().id())).isEqualTo(1L);
        assertThat(jdbc.queryForObject("SELECT email_verified FROM users WHERE id = ?", Boolean.class, first.user().id())).isTrue();

        // vé chỉ dùng được một lần
        assertThatThrownBy(() -> g.exchange(ticket)).isInstanceOf(ApiException.class).hasMessageContaining("hết hạn");

        // lần sau cùng email: vào đúng tài khoản cũ, không tạo thêm
        String again = g.callback("code", stateOf(g), null);
        String t2 = java.net.URLDecoder.decode(again.substring(again.indexOf("ticket=") + 7), StandardCharsets.UTF_8);
        assertThat(g.exchange(t2).user().id()).isEqualTo(first.user().id());
    }

    @Test
    void googleEmailMatchingAPasswordAccountLinksToIt() throws Exception {
        long existing = createUser(com.rebook.user.Role.USER, "Đã Có Tài Khoản", 0);
        String email = jdbc.queryForObject("SELECT email FROM users WHERE id = ?", String.class, existing);
        GoogleAuthService g = service(idToken(email, true, CLIENT_ID));
        String r = g.callback("code", stateOf(g), null);
        String ticket = java.net.URLDecoder.decode(r.substring(r.indexOf("ticket=") + 7), StandardCharsets.UTF_8);
        assertThat(g.exchange(ticket).user().id()).isEqualTo(existing);
    }

    @Test
    void lockedAccountsCannotSignInWithGoogle() throws Exception {
        long locked = createUser(com.rebook.user.Role.USER, "Bị Khoá", 0);
        jdbc.update("UPDATE users SET status = 'LOCKED' WHERE id = ?", locked);
        String email = jdbc.queryForObject("SELECT email FROM users WHERE id = ?", String.class, locked);
        GoogleAuthService g = service(idToken(email, true, CLIENT_ID));
        String r = g.callback("code", stateOf(g), null);
        String ticket = java.net.URLDecoder.decode(r.substring(r.indexOf("ticket=") + 7), StandardCharsets.UTF_8);
        assertThatThrownBy(() -> g.exchange(ticket)).isInstanceOf(ApiException.class);
    }

    @Test
    void rejectsUnverifiedEmailWrongAudienceAndForgedState() throws Exception {
        GoogleAuthService unverified = service(idToken("x@gmail.com", false, CLIENT_ID));
        assertThat(unverified.callback("code", stateOf(unverified), null)).contains("error=GOOGLE_EMAIL_UNVERIFIED");

        GoogleAuthService wrongAud = service(idToken("x@gmail.com", true, "someone-else"));
        assertThat(wrongAud.callback("code", stateOf(wrongAud), null)).contains("error=GOOGLE_FAILED");

        GoogleAuthService ok = service(idToken("x@gmail.com", true, CLIENT_ID));
        assertThatThrownBy(() -> ok.callback("code", "app.9999999999.abc.forged", null)).isInstanceOf(ApiException.class);
        // người dùng bấm "Từ chối" ở Google
        assertThat(ok.callback(null, stateOf(ok), "access_denied")).endsWith("?error=access_denied");
    }

    @Test
    void webPlatformReturnsToTheWebApp() throws Exception {
        GoogleAuthService g = service(idToken("web-" + UUID.randomUUID() + "@gmail.com", true, CLIENT_ID));
        String url = g.loginUrl("web");
        String state = java.net.URLDecoder.decode(url.substring(url.indexOf("state=") + 6, url.indexOf("&prompt")), StandardCharsets.UTF_8);
        assertThat(g.callback("code", state, null)).startsWith(props.payment().appUrl() + "/auth/google?ticket=");
    }
}
