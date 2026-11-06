package com.rebook.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

/**
 * Chặn khởi động khi chạy ngoài dev / test mà vẫn dùng khoá JWT mặc định (ai cũng biết, ký được token giả).
 */
@Component
public class ProductionGuard {

    private static final String DEFAULT_SECRET = "rebook-dev-secret-change-me-please-0123456789abcdef";

    private final Environment env;
    private final String secret;

    public ProductionGuard(Environment env, @Value("${app.jwt.secret}") String secret) {
        this.env = env;
        this.secret = secret;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void check() {
        if (env.acceptsProfiles(Profiles.of("dev", "test"))) {
            return;
        }
        if (DEFAULT_SECRET.equals(secret) || secret.length() < 32) {
            throw new IllegalStateException("Chưa đặt JWT_SECRET (>= 32 ký tự) cho môi trường không phải dev: từ chối khởi động");
        }
    }
}
