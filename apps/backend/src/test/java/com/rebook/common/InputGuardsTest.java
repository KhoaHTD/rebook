package com.rebook.common;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Các chốt chặn nhỏ lộ ra khi test theo vai: dò mật khẩu, sai phương thức, ISBN, số tài khoản, lý do từ chối. */
class InputGuardsTest extends IntegrationTest {

    @Test
    void loginIsBlockedAfterTenWrongPasswordsAndResetsAfterSuccess() throws Exception {
        String email = "guard-" + UUID.randomUUID() + "@rebook.vn";
        // Đếm theo email nên email không tồn tại cũng bị chặn như email thật (không lộ email có tồn tại hay không).
        for (int i = 0; i < 10; i++) {
            mvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                            .content("{\"email\":\"" + email + "\",\"password\":\"Sai" + i + "\"}"))
                    .andExpect(status().isUnauthorized());
        }
        mvc.perform(post("/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"Sai11\"}"))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value("TOO_MANY_REQUESTS"));
    }

    @Test
    void otpIsLockedAfterFiveWrongGuessesEvenIfTheNextOneIsRight() throws Exception {
        long me = createUser(Role.USER, "Người nhập OTP", 0);
        jdbc.update("UPDATE users SET email_verified = FALSE WHERE id = ?", me);
        String sent = mvc.perform(post("/auth/send-otp").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"purpose\":\"VERIFY_EMAIL\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String code = jdbc.queryForObject("SELECT code FROM otp_codes WHERE user_id = ? ORDER BY id DESC LIMIT 1", String.class, me);
        String wrong = code.equals("000000") ? "111111" : "000000";
        for (int i = 0; i < 5; i++) {
            mvc.perform(post("/auth/verify-otp").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                            .content("{\"purpose\":\"VERIFY_EMAIL\",\"code\":\"" + wrong + "\"}"))
                    .andExpect(status().isBadRequest());
        }
        // Số lần sai phải được lưu lại, nên mã đúng cũng bị từ chối.
        mvc.perform(post("/auth/verify-otp").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"purpose\":\"VERIFY_EMAIL\",\"code\":\"" + code + "\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void endedSessionStillCountsEveryoneWhoRegisteredEvenAfterTheDepositIsRefunded() throws Exception {
        long me = createUser(Role.USER, "Người xem phiên", 0);
        long a = createUser(Role.USER, "Người tham gia A", 0);
        long b = createUser(Role.USER, "Người tham gia B", 0);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status, ended_at)
                VALUES ('Phiên đã kết thúc', now() - interval '1 hour', now() - interval '2 hours', 500000, 'ENDED', now())
                RETURNING id""", Long.class);
        jdbc.update("INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status) VALUES (?, ?, 1, 500000, 5000000, 'REFUNDED')", session, a);
        jdbc.update("INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status) VALUES (?, ?, 2, 500000, 5000000, 'APPLIED')", session, b);

        mvc.perform(get("/sessions/" + session).with(as(me, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.session.registeredCount").value(2));
    }

    @Test
    void wrongMethodAnswers405NotAServerError() throws Exception {
        long me = createUser(Role.USER, "Người dùng", 0);
        mvc.perform(get("/lots/1/bids").with(as(me, Role.USER)))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.code").value("METHOD_NOT_ALLOWED"));
        mvc.perform(patch("/cart").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isMethodNotAllowed());
    }

    @Test
    void withdrawalNeedsADigitsOnlyAccountNumber() throws Exception {
        long me = createUser(Role.USER, "Người rút", 500_000);
        for (String bad : new String[]{"12ab", "12345", "12345678901234567890"}) {
            mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                            .content("{\"amount\":100000,\"bankName\":\"VCB\",\"accountNumber\":\"" + bad
                                    + "\",\"accountHolder\":\"NGUOI RUT\"}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.fieldErrors.accountNumber").exists());
        }
        mvc.perform(post("/wallet/withdrawals").with(as(me, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\":100000,\"bankName\":\"VCB\",\"accountNumber\":\"123456789\",\"accountHolder\":\"NGUOI RUT\"}"))
                .andExpect(status().isCreated());
    }

    private String listingBody(String isbn) {
        return """
                {"book":{"title":"Sách thử ISBN","author":"A","categoryId":%d,"conditionGrade":"GOOD","weightGram":300,"isbn":%s,
                "imageUrls":["a","b","c"]},"price":50000,"stock":1}""";
    }

    @Test
    void bookIsbnMustBeTenOrThirteenCharactersWhenGiven() throws Exception {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        jdbc.update("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hà Nội', 'VCB', '123456', 'X')""", owner, "Shop " + UUID.randomUUID());
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "isbn-" + UUID.randomUUID());
        for (String bad : new String[]{"\"abc\"", "\"12345\""}) {
            mvc.perform(post("/seller/listings").with(as(owner, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                            .content(listingBody(bad).formatted(category, bad)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.fieldErrors['book.isbn']").exists());
        }
        for (String good : new String[]{"\"9786041234567\"", "\"080442957X\"", "\"\"", "null"}) {
            mvc.perform(post("/seller/listings").with(as(owner, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                            .content(listingBody(good).formatted(category, good)))
                    .andExpect(status().isCreated());
        }
    }
}
