package com.rebook.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@ConfigurationProperties(prefix = "app")
public record AppProperties(Jwt jwt, Otp otp, Cors cors, Auction auction, Payment payment) {

    public record Jwt(String secret, long accessTokenMinutes, long refreshTokenDays) {
    }

    public record Otp(long ttlMinutes, boolean exposeInResponse) {
    }

    public record Cors(List<String> allowedOrigins) {
    }

    public record Auction(boolean engineEnabled) {
    }

    public record Payment(boolean simulateEnabled, Vnpay vnpay) {
    }

    public record Vnpay(String tmnCode, String hashSecret, String payUrl, String returnUrl) {
    }
}
