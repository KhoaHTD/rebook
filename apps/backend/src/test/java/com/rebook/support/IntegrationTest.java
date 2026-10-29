package com.rebook.support;

import com.rebook.security.UserPrincipal;
import com.rebook.user.Role;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.List;
import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;

/** Nền chung cho test tích hợp: Postgres thật (schema rebook_test), gọi API qua MockMvc, dữ liệu tạo bằng SQL. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public abstract class IntegrationTest {

    @Autowired
    protected MockMvc mvc;
    @Autowired
    protected JdbcTemplate jdbc;

    /** Tạo user + ví (số dư cho trước), trả về id. */
    protected long createUser(Role role, String fullName, long balance) {
        String email = role.name().toLowerCase() + "-" + UUID.randomUUID() + "@test.local";
        Long id = jdbc.queryForObject("""
                INSERT INTO users (email, password_hash, full_name, role, email_verified)
                VALUES (?, 'x', ?, ?, TRUE) RETURNING id""", Long.class, email, fullName, role.name());
        jdbc.update("INSERT INTO wallets (user_id, available_balance) VALUES (?, ?)", id, balance);
        return id;
    }

    protected RequestPostProcessor as(long userId, Role role) {
        UserPrincipal principal = new UserPrincipal(userId, "u" + userId + "@test.local", role);
        return authentication(new UsernamePasswordAuthenticationToken(principal, null,
                List.of(new SimpleGrantedAuthority("ROLE_" + role.name()))));
    }

    protected long walletAvailable(long userId) {
        return jdbc.queryForObject("SELECT available_balance FROM wallets WHERE user_id = ?", Long.class, userId);
    }

    protected long walletHeld(long userId) {
        return jdbc.queryForObject("SELECT held_balance FROM wallets WHERE user_id = ?", Long.class, userId);
    }
}
