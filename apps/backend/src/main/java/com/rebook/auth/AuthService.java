package com.rebook.auth;

import com.rebook.auth.AuthDtos.AuthResponse;
import com.rebook.auth.AuthDtos.LoginRequest;
import com.rebook.auth.AuthDtos.OtpSentResponse;
import com.rebook.auth.AuthDtos.RegisterRequest;
import com.rebook.auth.AuthDtos.ResetPasswordRequest;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.config.AppProperties;
import com.rebook.security.JwtService;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import com.rebook.user.UserService;
import com.rebook.user.UserStatus;
import com.rebook.wallet.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final int MAX_OTP_ATTEMPTS = 5;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final UserService userService;
    private final RefreshTokenRepository refreshTokenRepository;
    private final OtpCodeRepository otpRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final WalletService walletService;
    private final AppProperties props;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        String email = req.email().trim().toLowerCase();
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw ApiException.conflict("EMAIL_TAKEN", "Email đã được đăng ký");
        }
        if (req.phone() != null && userRepository.existsByPhone(req.phone())) {
            throw ApiException.conflict("PHONE_TAKEN", "Số điện thoại đã được đăng ký");
        }
        User user = new User();
        user.setEmail(email);
        user.setPhone(req.phone());
        user.setFullName(req.fullName().trim());
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        user = userRepository.save(user);
        walletService.createFor(user.getId());

        String otp = issueOtp(user, OtpCode.Purpose.VERIFY_EMAIL);
        return tokens(user, otp);
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByEmailIgnoreCase(req.email().trim())
                .filter(u -> passwordEncoder.matches(req.password(), u.getPasswordHash()))
                .orElseThrow(() -> new BadCredentialsException("bad credentials"));
        ensureActive(user);
        return tokens(user, null);
    }

    /** Đổi refresh token cũ lấy cặp token mới (token cũ bị thu hồi — rotation). */
    @Transactional
    public AuthResponse refresh(String refreshToken) {
        RefreshToken stored = refreshTokenRepository.findByTokenHash(sha256(refreshToken))
                .orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token không hợp lệ"));
        if (stored.isRevoked() || stored.getExpiresAt().isBefore(Instant.now())) {
            throw ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token đã hết hạn hoặc bị thu hồi");
        }
        stored.setRevoked(true);
        User user = userService.getUser(stored.getUserId());
        ensureActive(user);
        return tokens(user, null);
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokenRepository.findByTokenHash(sha256(refreshToken)).ifPresent(t -> t.setRevoked(true));
    }

    // ---- OTP ----

    @Transactional
    public OtpSentResponse sendOtp(Long userId, OtpCode.Purpose purpose) {
        User user = userService.getUser(userId);
        if (purpose == OtpCode.Purpose.VERIFY_PHONE && user.getPhone() == null) {
            throw ApiException.badRequest("PHONE_REQUIRED", "Hãy cập nhật số điện thoại trước");
        }
        if (purpose == OtpCode.Purpose.RESET_PASSWORD) {
            throw ApiException.badRequest("INVALID_PURPOSE", "Dùng /auth/forgot-password để đặt lại mật khẩu");
        }
        String code = issueOtp(user, purpose);
        return new OtpSentResponse("Đã gửi mã OTP", props.otp().exposeInResponse() ? code : null);
    }

    @Transactional
    public void verifyOtp(Long userId, OtpCode.Purpose purpose, String code) {
        User user = userService.getUser(userId);
        consumeOtp(user, purpose, code);
        switch (purpose) {
            case VERIFY_EMAIL -> user.setEmailVerified(true);
            case VERIFY_PHONE -> user.setPhoneVerified(true);
            default -> throw ApiException.badRequest("INVALID_PURPOSE", "Mục đích OTP không hợp lệ");
        }
    }

    /** Luôn trả về thành công để không lộ email nào đã đăng ký. */
    @Transactional
    public OtpSentResponse forgotPassword(String email) {
        String code = userRepository.findByEmailIgnoreCase(email.trim())
                .map(u -> issueOtp(u, OtpCode.Purpose.RESET_PASSWORD))
                .orElse(null);
        return new OtpSentResponse("Nếu email tồn tại, mã OTP đã được gửi",
                props.otp().exposeInResponse() ? code : null);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest req) {
        User user = userRepository.findByEmailIgnoreCase(req.email().trim())
                .orElseThrow(() -> ApiException.badRequest("INVALID_OTP", "Mã OTP không đúng"));
        consumeOtp(user, OtpCode.Purpose.RESET_PASSWORD, req.code());
        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        user.setEmailVerified(true); // nhận được OTP qua email nghĩa là email đúng
        refreshTokenRepository.revokeAllForUser(user.getId());
    }

    private String issueOtp(User user, OtpCode.Purpose purpose) {
        OtpCode otp = new OtpCode();
        otp.setUserId(user.getId());
        otp.setPurpose(purpose);
        otp.setCode(CodeGenerator.digits(6));
        otp.setExpiresAt(Instant.now().plus(Duration.ofMinutes(props.otp().ttlMinutes())));
        otpRepository.save(otp);
        // Chưa tích hợp dịch vụ gửi email/SMS: ghi log để dev lấy mã.
        log.info("[OTP] {} cho {}: {}", purpose, user.getEmail(), otp.getCode());
        return otp.getCode();
    }

    private void consumeOtp(User user, OtpCode.Purpose purpose, String code) {
        OtpCode otp = otpRepository.findFirstByUserIdAndPurposeAndUsedAtIsNullOrderByIdDesc(user.getId(), purpose)
                .orElseThrow(() -> ApiException.badRequest("INVALID_OTP", "Mã OTP không đúng hoặc đã hết hạn"));
        if (otp.getExpiresAt().isBefore(Instant.now()) || otp.getAttempts() >= MAX_OTP_ATTEMPTS) {
            throw ApiException.badRequest("INVALID_OTP", "Mã OTP đã hết hạn, vui lòng yêu cầu mã mới");
        }
        if (!MessageDigest.isEqual(otp.getCode().getBytes(StandardCharsets.UTF_8), code.trim().getBytes(StandardCharsets.UTF_8))) {
            otp.setAttempts(otp.getAttempts() + 1);
            otpRepository.saveAndFlush(otp);
            throw ApiException.badRequest("INVALID_OTP", "Mã OTP không đúng");
        }
        otp.setUsedAt(Instant.now());
    }

    // ---- Token ----

    private AuthResponse tokens(User user, String otp) {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String refresh = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        RefreshToken stored = new RefreshToken();
        stored.setUserId(user.getId());
        stored.setTokenHash(sha256(refresh));
        stored.setExpiresAt(Instant.now().plus(Duration.ofDays(props.jwt().refreshTokenDays())));
        refreshTokenRepository.save(stored);

        String access = jwtService.createAccessToken(user.getId(), user.getEmail(), user.getRole());
        return new AuthResponse(access, refresh, "Bearer", jwtService.accessTokenSeconds(),
                userService.me(user.getId()), props.otp().exposeInResponse() ? otp : null);
    }

    private static void ensureActive(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw ApiException.forbidden("Tài khoản đã bị khoá"
                    + (user.getLockReason() != null ? ": " + user.getLockReason() : ""));
        }
    }

    private static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
