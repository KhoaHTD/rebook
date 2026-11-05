package com.rebook.common;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Nhật ký bảo mật (docs/LOGGING_DESIGN.md mục 5.1): đăng ký, đăng nhập, OTP, mật khẩu, khoá tài khoản, 403, upload. */
class SecurityAuditTest extends IntegrationTest {

    private static final String PASSWORD = "Matkhau@123";

    private long count(String code, String where, Object... args) {
        Object[] all = new Object[args.length];
        System.arraycopy(args, 0, all, 0, args.length);
        return jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE event_code = ? AND " + where, Long.class,
                prepend(code, all));
    }

    private static Object[] prepend(Object first, Object[] rest) {
        Object[] r = new Object[rest.length + 1];
        r[0] = first;
        System.arraycopy(rest, 0, r, 1, rest.length);
        return r;
    }

    private String register(String email) throws Exception {
        mvc.perform(post("/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + PASSWORD + "\",\"fullName\":\"Người thử\"}")).andExpect(status().isCreated());
        return email;
    }

    private long userId(String email) {
        return jdbc.queryForObject("SELECT id FROM users WHERE email = ?", Long.class, email);
    }

    @Test
    void registrationAndLoginLeaveEventsWithoutStoringTheEmail() throws Exception {
        String email = "audit-" + UUID.randomUUID() + "@rebook.vn";
        register(email);
        long id = userId(email);
        assertThat(count("AUTH.REGISTER.SUCCESS", "target_id = ? AND actor_id = ?", String.valueOf(id), id)).isEqualTo(1);

        mvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"Sai12345\"}")).andExpect(status().isUnauthorized());
        mvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + PASSWORD + "\"}")).andExpect(status().isOk());

        assertThat(count("AUTH.LOGIN.SUCCESS", "actor_id = ?", id)).isEqualTo(1);
        // Đăng nhập sai không biết là ai: ghi bằng băm email, không lưu email.
        assertThat(count("AUTH.LOGIN.FAILED", "result = 'DENIED' AND reason_code = 'BAD_CREDENTIALS' AND details->>'emailHash' IS NOT NULL "
                + "AND details::text NOT LIKE '%@%'")).isGreaterThanOrEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE details::text LIKE ?", Long.class, "%" + email + "%")).isZero();
    }

    @Test
    void tooManyWrongPasswordsIsLoggedAsThrottled() throws Exception {
        String email = "throttle-" + UUID.randomUUID() + "@rebook.vn";
        for (int i = 0; i < 11; i++) {
            mvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"" + email + "\",\"password\":\"Sai" + i + "x\"}"));
        }
        assertThat(count("AUTH.LOGIN.THROTTLED", "reason_code = 'THROTTLED'")).isGreaterThanOrEqualTo(1);
    }

    @Test
    void otpAttemptsAreLoggedWithoutTheCode() throws Exception {
        String email = register("otp-" + UUID.randomUUID() + "@rebook.vn");
        long id = userId(email);
        String code = jdbc.queryForObject("SELECT code FROM otp_codes WHERE user_id = ? ORDER BY id DESC LIMIT 1", String.class, id);
        String wrong = code.equals("000000") ? "111111" : "000000";

        mvc.perform(post("/auth/verify-otp").with(as(id, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"purpose\":\"VERIFY_EMAIL\",\"code\":\"" + wrong + "\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/auth/verify-otp").with(as(id, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"purpose\":\"VERIFY_EMAIL\",\"code\":\"" + code + "\"}")).andExpect(status().isNoContent());

        assertThat(count("AUTH.OTP.SENT", "actor_id = ?", id)).isEqualTo(1);
        assertThat(count("AUTH.OTP.FAILED", "actor_id = ? AND reason_code = 'WRONG_CODE'", id)).isEqualTo(1);
        assertThat(count("AUTH.OTP.VERIFIED", "actor_id = ?", id)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM audit_events WHERE actor_id = ? AND details::text LIKE ?", Long.class,
                id, "%" + code + "%")).isZero(); // mã OTP không nằm trong nhật ký
    }

    @Test
    void passwordChangeAndAdminActionsAreLogged() throws Exception {
        String email = register("pw-" + UUID.randomUUID() + "@rebook.vn");
        long id = userId(email);
        long admin = createUser(Role.ADMIN, "Admin", 0);

        mvc.perform(post("/me/password").with(as(id, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"currentPassword\":\"Sai12345\",\"newPassword\":\"Moi@123456\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/me/password").with(as(id, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"currentPassword\":\"" + PASSWORD + "\",\"newPassword\":\"Moi@123456\"}")).andExpect(status().isNoContent());
        mvc.perform(post("/admin/users/" + id + "/lock").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Vi phạm\"}")).andExpect(status().isOk());
        mvc.perform(post("/admin/users/" + id + "/unlock").with(as(admin, Role.ADMIN))).andExpect(status().isOk());

        assertThat(count("AUTH.PASSWORD.CHANGED", "target_id = ? AND result = 'DENIED'", String.valueOf(id))).isEqualTo(1);
        assertThat(count("AUTH.PASSWORD.CHANGED", "target_id = ? AND result = 'SUCCESS'", String.valueOf(id))).isEqualTo(1);
        assertThat(count("USER.LOCKED", "target_id = ? AND actor_id = ?", String.valueOf(id), admin)).isEqualTo(1);
        assertThat(count("USER.UNLOCKED", "target_id = ?", String.valueOf(id))).isEqualTo(1);
    }

    @Test
    void forbiddenAccessIsLoggedWithTheActorAndThePath() throws Exception {
        long me = createUser(Role.USER, "Người thường", 0);

        mvc.perform(get("/admin/users").with(as(me, Role.USER))).andExpect(status().isForbidden());

        assertThat(count("ACCESS.DENIED", "actor_id = ? AND details->>'path' = '/admin/users'", me)).isEqualTo(1);
    }

    @Test
    void uploadsAndRejectedUploadsAreLogged() throws Exception {
        long me = createUser(Role.USER, "Người tải ảnh", 0);
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};

        mvc.perform(multipart("/files").file(new MockMultipartFile("file", "a.png", "image/png", png)).with(as(me, Role.USER)))
                .andExpect(status().isOk());
        mvc.perform(multipart("/files").file(new MockMultipartFile("file", "a.txt", "text/plain", "x".getBytes())).with(as(me, Role.USER)))
                .andExpect(status().isBadRequest());

        assertThat(count("FILE.UPLOADED", "actor_id = ?", me)).isEqualTo(1);
        assertThat(count("FILE.REJECTED", "actor_id = ? AND result = 'DENIED'", me)).isEqualTo(1);
    }
}
