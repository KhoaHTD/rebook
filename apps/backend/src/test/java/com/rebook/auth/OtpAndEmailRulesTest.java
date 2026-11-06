package com.rebook.auth;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** P0 mục 3, phần làm được bằng email (docs/ra-soat-nghiep-vu/THIET_KE_GUI_MAIL.md mục 4). */
class OtpAndEmailRulesTest extends IntegrationTest {

    @Test
    void normalizedEmailFollowsTheSameRulesAsTheGeneratedColumn() {
        assertThat(AuthService.normalizeEmail(" A.B+shop@Gmail.com ")).isEqualTo("ab@gmail.com");
        assertThat(AuthService.normalizeEmail("a.b@googlemail.com")).isEqualTo("ab@gmail.com");
        assertThat(AuthService.normalizeEmail("a.b+x@outlook.com")).isEqualTo("a.b@outlook.com");

        long id = createUser(Role.USER, "Hộp thư", 0);
        String spelled = "Ng.Van" + id + "+1@gmail.com";
        jdbc.update("UPDATE users SET email = ? WHERE id = ?", spelled, id);
        assertThat(jdbc.queryForObject("SELECT email_normalized FROM users WHERE id = ?", String.class, id))
                .isEqualTo(AuthService.normalizeEmail(spelled)).isEqualTo("ngvan" + id + "@gmail.com");
    }

    @Test
    void anotherSpellingOfARegisteredGmailBoxCannotRegister() throws Exception {
        String local = "box" + UUID.randomUUID().toString().replace("-", "");
        register(local + "@gmail.com").andExpect(status().isCreated());

        String variant = local.substring(0, 3) + "." + local.substring(3) + "+ban@gmail.com";
        register(variant).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("EMAIL_TAKEN"));
    }

    @Test
    void askingForANewCodeTooSoonIsRefused() throws Exception {
        long me = createUser(Role.USER, "Người xin mã", 0);
        sendOtp(me).andExpect(status().isOk()).andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("***")));
        sendOtp(me).andExpect(status().isTooManyRequests()).andExpect(jsonPath("$.code").value("TOO_MANY_REQUESTS"));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM otp_codes WHERE user_id = ?", Long.class, me)).isEqualTo(1);
    }

    @Test
    void forgotPasswordIsThrottledByEmailEvenWhenTheEmailDoesNotExist() throws Exception {
        String ghost = "ghost-" + UUID.randomUUID() + "@test.local";
        forgot(ghost).andExpect(status().isOk());
        forgot(ghost).andExpect(status().isTooManyRequests());
    }

    private org.springframework.test.web.servlet.ResultActions register(String email) throws Exception {
        return mvc.perform(post("/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"Rebook@123\",\"fullName\":\"Người thử\"}"));
    }

    private org.springframework.test.web.servlet.ResultActions sendOtp(long me) throws Exception {
        return mvc.perform(post("/auth/send-otp").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"purpose\":\"VERIFY_EMAIL\"}"));
    }

    private org.springframework.test.web.servlet.ResultActions forgot(String email) throws Exception {
        return mvc.perform(post("/auth/forgot-password").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\"}"));
    }
}
