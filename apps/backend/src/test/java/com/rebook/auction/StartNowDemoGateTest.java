package com.rebook.auction;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** BR-5.4: ngoài môi trường demo, Admin không mở phiên ngay được (phiên tự mở đúng giờ). */
@TestPropertySource(properties = "app.auction.demo-enabled=false")
class StartNowDemoGateTest extends IntegrationTest {

    @Test
    void startNowIsRefusedOutsideDemo() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin", 0);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên đã xác nhận', now() + interval '1 day', now(), 50000, 'CONFIRMED') RETURNING id""", Long.class);
        mvc.perform(post("/admin/sessions/" + session + "/start").with(as(admin, Role.ADMIN)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("DEMO_ONLY"));
    }
}
