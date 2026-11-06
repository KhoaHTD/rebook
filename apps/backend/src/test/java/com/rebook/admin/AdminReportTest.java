package com.rebook.admin;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Báo cáo của Admin: có đủ mọi ngày trong khoảng, chặn khoảng sai và chặn người không phải Admin. */
class AdminReportTest extends IntegrationTest {

    @Test
    void reportListsEveryDayOfTheRange() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin Báo Cáo", 0);
        LocalDate to = LocalDate.now();
        LocalDate from = to.minusDays(6);
        mvc.perform(get("/admin/reports").param("from", from.toString()).param("to", to.toString()).with(as(admin, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.days.length()").value(7))
                .andExpect(jsonPath("$.days[0].date").value(from.toString()))
                .andExpect(jsonPath("$.newUsers").isNumber())
                .andExpect(jsonPath("$.statuses").isArray());
    }

    @Test
    void reportRejectsAnInvertedRange() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin Báo Cáo", 0);
        mvc.perform(get("/admin/reports").param("from", "2026-11-10").param("to", "2026-11-01").with(as(admin, Role.ADMIN)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BAD_RANGE"));
    }

    @Test
    void reportIsForAdminsOnly() throws Exception {
        long user = createUser(Role.USER, "Người mua", 0);
        mvc.perform(get("/admin/reports").with(as(user, Role.USER))).andExpect(status().isForbidden());
    }
}
