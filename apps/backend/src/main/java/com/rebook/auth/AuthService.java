package com.rebook.auth;

import com.rebook.auth.AuthDtos.AuthResponse;
import com.rebook.auth.AuthDtos.LoginRequest;
import com.rebook.auth.AuthDtos.OtpSentResponse;
import com.rebook.auth.AuthDtos.RegisterRequest;
import com.rebook.auth.AuthDtos.ResetPasswordRequest;
import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.common.RateLimiter;
import com.rebook.config.AppProperties;
import com.rebook.notification.MailService;
import com.rebook.security.JwtService;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import com.rebook.user.UserService;
import com.rebook.user.UserStatus;
import com.rebook.wallet.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
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
    private static final int MAX_OTP_PER_HOUR = 5;
    private static final int MAX_OTP_PER_DAY = 10;
    private static final SecureRandom RANDOM = new SecureRandom();

    private static final int MAX_LOGIN_FAILURES = 10;
    private static final int MAX_LOGIN_FAILURES_PER_IP = 30;
    private static final int MAX_LOGIN_FAILURES_PER_EMAIL = 100;
    private static final Duration LOGIN_WINDOW = Duration.ofMinutes(15);

    private final UserRepository userRepository;
    private final UserService userService;
    private final RefreshTokenRepository refreshTokenRepository;
    private final OtpCodeRepository otpRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final WalletService walletService;
    private final AppProperties props;
    private final RateLimiter limiter;
    private final OtpAttempts otpAttempts;
    private final AuditLog audit;
    private final MailService mail;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        String email = req.email().trim().toLowerCase();
        // Biến thể a.b+1@gmail.com của một hộp thư đã đăng ký cũng bị chặn: không lách cấm / nợ bằng cùng hộp thư
        if (userRepository.existsByEmailIgnoreCase(email) || userRepository.existsByNormalizedEmail(normalizeEmail(email))) {
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
        audit.recordBy(user.getId(), user.getRole(), EventCode.AUTH_REGISTER_SUCCESS, "USER", user.getId(), null,
                "Đăng ký tài khoản", "emailDomain", email.substring(email.indexOf('@') + 1));

        // Mail lỗi không chặn đăng ký: tài khoản đã tạo, người dùng bấm "gửi lại mã"
        String otp = issueOtp(user, OtpCode.Purpose.VERIFY_EMAIL, false);
        return tokens(user, otp);
    }

    /**
     * Chặn dò mật khẩu bằng ba bộ đếm sai: theo email + IP (10 lần), theo IP (30 lần, chặn dò nhiều email),
     * theo email trên mọi IP (100 lần, chặn dò phân tán). Kẻ xấu ở một IP không còn khoá được tài khoản người khác (BE-42).
     */
    @Transactional
    public AuthResponse login(LoginRequest req, String clientIp) {
        String email = req.email().trim().toLowerCase();
        String ip = clientIp == null ? "?" : clientIp;
        String pairKey = "login:" + email + "|" + ip;
        String ipKey = "login-ip:" + ip;
        String emailKey = "login:" + email;
        if (limiter.count(pairKey) >= MAX_LOGIN_FAILURES || limiter.count(ipKey) >= MAX_LOGIN_FAILURES_PER_IP
                || limiter.count(emailKey) >= MAX_LOGIN_FAILURES_PER_EMAIL) {
            audit.recordDeniedBy(null, null, EventCode.AUTH_LOGIN_THROTTLED, "THROTTLED", "USER", null, "Đăng nhập bị chặn tạm vì sai quá nhiều lần",
                    "emailHash", emailHash(req.email()), "windowMinutes", LOGIN_WINDOW.toMinutes());
            throw ApiException.tooMany("Sai mật khẩu quá nhiều lần, vui lòng thử lại sau 15 phút");
        }
        User user = userRepository.findByEmailIgnoreCase(req.email().trim())
                .filter(u -> passwordEncoder.matches(req.password(), u.getPasswordHash()))
                .orElse(null);
        if (user == null) {
            limiter.hit(pairKey, LOGIN_WINDOW);
            limiter.hit(ipKey, LOGIN_WINDOW);
            limiter.hit(emailKey, LOGIN_WINDOW);
            audit.recordDeniedBy(null, null, EventCode.AUTH_LOGIN_FAILED, "BAD_CREDENTIALS", "USER", null, "Đăng nhập sai",
                    "emailHash", emailHash(req.email()), "failuresInWindow", limiter.count(pairKey));
            throw new BadCredentialsException("bad credentials");
        }
        limiter.reset(pairKey);
        if (user.getStatus() != UserStatus.ACTIVE) {
            audit.recordDeniedBy(user.getId(), user.getRole(), EventCode.AUTH_LOGIN_FAILED, "ACCOUNT_LOCKED", "USER", user.getId(),
                    "Đăng nhập vào tài khoản bị khoá");
        }
        ensureActive(user);
        audit.recordBy(user.getId(), user.getRole(), EventCode.AUTH_LOGIN_SUCCESS, "USER", user.getId(), null, "Đăng nhập");
        return tokens(user, null);
    }

    /**
     * Đăng nhập bằng Google (email đã được Google xác minh): có tài khoản cùng email thì dùng luôn (không hỏi OTP),
     * chưa có thì tạo tài khoản USER mới lấy tên + ảnh Google, mật khẩu ngẫu nhiên (đặt lại qua "quên mật khẩu" nếu cần).
     */
    @Transactional
    public AuthResponse loginWithGoogle(String rawEmail, String name, String picture) {
        String email = rawEmail.trim().toLowerCase();
        User user = userRepository.findByEmailIgnoreCase(email).orElse(null);
        boolean created = false;
        if (user == null) {
            if (userRepository.existsByNormalizedEmail(normalizeEmail(email))) {
                throw ApiException.conflict("EMAIL_TAKEN", "Email này trùng với một tài khoản đã đăng ký");
            }
            user = new User();
            user.setEmail(email);
            user.setFullName(name == null || name.isBlank() ? email.substring(0, email.indexOf('@')) : name.trim());
            user.setAvatarUrl(picture);
            user.setEmailVerified(true);
            byte[] noise = new byte[32];
            RANDOM.nextBytes(noise);
            user.setPasswordHash(passwordEncoder.encode(Base64.getUrlEncoder().withoutPadding().encodeToString(noise)));
            user = userRepository.save(user);
            walletService.createFor(user.getId());
            created = true;
        } else {
            ensureActive(user);
            if (!user.isEmailVerified()) {
                user.setEmailVerified(true);
            }
            if (user.getAvatarUrl() == null && picture != null) {
                user.setAvatarUrl(picture);
            }
        }
        audit.recordBy(user.getId(), user.getRole(), created ? EventCode.AUTH_REGISTER_SUCCESS : EventCode.AUTH_LOGIN_SUCCESS, "USER",
                user.getId(), null, created ? "Đăng ký bằng Google" : "Đăng nhập bằng Google");
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
        refreshTokenRepository.findByTokenHash(sha256(refreshToken)).ifPresent(t -> {
            t.setRevoked(true);
            audit.recordBy(t.getUserId(), userService.getUser(t.getUserId()).getRole(), EventCode.AUTH_LOGOUT, "USER", t.getUserId(), null, "Đăng xuất");
        });
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
        throttleOtp("u:" + userId, user);
        String code = issueOtp(user, purpose, true);
        return new OtpSentResponse("Đã gửi mã OTP tới email " + MailService.mask(user.getEmail()), exposeOtp(code));
    }

    /** Chỉ trả mã trong response khi bật cờ dev VÀ mail thật đang tắt: mail đã gửi đi thì không lộ mã lần nữa. */
    private String exposeOtp(String code) {
        return props.otp().exposeInResponse() && !mail.enabled() ? code : null;
    }

    @Transactional
    public void verifyOtp(Long userId, OtpCode.Purpose purpose, String code) {
        User user = userService.getUser(userId);
        consumeOtp(user, purpose, code);
        audit.recordBy(user.getId(), user.getRole(), EventCode.AUTH_OTP_VERIFIED, "USER", user.getId(), null, "Xác thực OTP", "purpose", purpose);
        switch (purpose) {
            case VERIFY_EMAIL -> user.setEmailVerified(true);
            case VERIFY_PHONE -> user.setPhoneVerified(true);
            default -> throw ApiException.badRequest("INVALID_PURPOSE", "Mục đích OTP không hợp lệ");
        }
    }

    /** Luôn trả về thành công để không lộ email nào đã đăng ký. */
    @Transactional
    public OtpSentResponse forgotPassword(String email) {
        // Giới hạn theo email kể cả khi email không tồn tại: hai trường hợp phải trả lời giống nhau
        throttleOtp("e:" + email.trim().toLowerCase(), null);
        User known = userRepository.findByEmailIgnoreCase(email.trim()).orElse(null);
        // Mail lỗi cũng trả lời như thường, để không lộ email nào có tài khoản
        String code = known == null ? null : issueOtp(known, OtpCode.Purpose.RESET_PASSWORD, false);
        audit.recordBy(known == null ? null : known.getId(), known == null ? null : known.getRole(), EventCode.AUTH_PASSWORD_RESET_REQUESTED,
                "USER", known == null ? null : known.getId(), null, "Yêu cầu đặt lại mật khẩu",
                "known", known != null, "emailHash", emailHash(email));
        return new OtpSentResponse("Nếu email tồn tại, mã OTP đã được gửi",
                exposeOtp(code));
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest req) {
        User user = userRepository.findByEmailIgnoreCase(req.email().trim())
                .orElseThrow(() -> ApiException.badRequest("INVALID_OTP", "Mã OTP không đúng"));
        consumeOtp(user, OtpCode.Purpose.RESET_PASSWORD, req.code());
        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        user.setEmailVerified(true); // nhận được OTP qua email nghĩa là email đúng
        refreshTokenRepository.revokeAllForUser(user.getId());
        audit.recordBy(user.getId(), user.getRole(), EventCode.AUTH_PASSWORD_RESET, "USER", user.getId(), null, "Đặt lại mật khẩu");
    }

    /**
     * Tạo mã và gửi mail ngay trong giao dịch (mail lỗi thì mã cũng bị huỷ cùng giao dịch).
     * strict: mail lỗi thì báo EMAIL_SEND_FAILED; không thì ghi log và vẫn trả về (đăng ký, quên mật khẩu).
     * Không ghi mã vào log; dev lấy mã qua devOtp (app.otp.expose-in-response).
     */
    private String issueOtp(User user, OtpCode.Purpose purpose, boolean strict) {
        OtpCode otp = new OtpCode();
        otp.setUserId(user.getId());
        otp.setPurpose(purpose);
        otp.setCode(CodeGenerator.digits(6));
        otp.setExpiresAt(Instant.now().plus(Duration.ofMinutes(props.otp().ttlMinutes())));
        otpRepository.save(otp);
        audit.recordBy(user.getId(), user.getRole(), EventCode.AUTH_OTP_SENT, "USER", user.getId(), null, "Gửi OTP", "purpose", purpose);
        try {
            mail.send(user.getEmail(), "ReBook: mã xác thực",otpMailBody(purpose, otp.getCode()));
        } catch (MailException e) {
            audit.recordDeniedBy(user.getId(), user.getRole(), EventCode.MAIL_FAILED, "SMTP_ERROR", "USER", user.getId(),
                    "Không gửi được mail OTP", "purpose", purpose);
            if (strict) {
                throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "EMAIL_SEND_FAILED",
                        "Chưa gửi được mail chứa mã OTP, vui lòng thử lại sau ít phút");
            }
            log.warn("Không gửi được mail OTP {} cho user #{}: {}", purpose, user.getId(), e.getMessage());
        }
        return otp.getCode();
    }

    private String otpMailBody(OtpCode.Purpose purpose, String code) {
        String what = switch (purpose) {
            case VERIFY_EMAIL -> "xác thực email";
            // shortcut: chưa có nhà cung cấp SMS nên mã xác thực SĐT gửi qua email; đổi sang SMS khi có (P0 mục 3)
            case VERIFY_PHONE -> "xác thực số điện thoại (tạm gửi qua email vì chưa có SMS)";
            case RESET_PASSWORD -> "đặt lại mật khẩu";
        };
        return "Mã OTP để " + what + " là: " + code + "\n\n"
                + "Mã có hiệu lực " + props.otp().ttlMinutes() + " phút. Không chia sẻ mã này với bất kỳ ai, kể cả nhân viên ReBook.\n"
                + "Nếu bạn không yêu cầu mã này, hãy bỏ qua thư.\n\n"
                + "ReBook - Chợ sách cũ";
    }

    /** Xin mã cách nhau ≥ 60 giây, tối đa 5 mã / giờ và 10 mã / ngày cho mỗi tài khoản hoặc mỗi email (BE-26). */
    private void throttleOtp(String key, User user) {
        if (limiter.count("otp-gap:" + key) > 0 || limiter.count("otp-hour:" + key) >= MAX_OTP_PER_HOUR
                || limiter.count("otp-day:" + key) >= MAX_OTP_PER_DAY) {
            audit.recordDeniedBy(user == null ? null : user.getId(), user == null ? null : user.getRole(), EventCode.AUTH_OTP_THROTTLED,
                    "THROTTLED", "USER", user == null ? null : user.getId(), "Xin mã OTP quá nhiều lần");
            throw ApiException.tooMany("Bạn vừa xin mã, vui lòng chờ ít phút rồi thử lại");
        }
        limiter.hit("otp-gap:" + key, Duration.ofSeconds(60));
        limiter.hit("otp-hour:" + key, Duration.ofHours(1));
        limiter.hit("otp-day:" + key, Duration.ofDays(1));
    }

    /**
     * Dạng chuẩn để so trùng hộp thư: chữ thường, bỏ phần sau dấu +, Gmail bỏ dấu chấm.
     * Phải khớp biểu thức của cột sinh users.email_normalized (V17).
     */
    static String normalizeEmail(String email) {
        String e = email.trim().toLowerCase();
        int at = e.indexOf('@'); // như split_part(email, '@', 1) trong SQL
        if (at < 0) {
            return e;
        }
        String local = e.substring(0, at);
        String domain = e.substring(at + 1);
        int plus = local.indexOf('+');
        if (plus >= 0) {
            local = local.substring(0, plus);
        }
        if (domain.equals("gmail.com") || domain.equals("googlemail.com")) {
            return local.replace(".", "") + "@gmail.com";
        }
        return local + "@" + domain;
    }

    private void consumeOtp(User user, OtpCode.Purpose purpose, String code) {
        OtpCode otp = otpRepository.findFirstByUserIdAndPurposeAndUsedAtIsNullOrderByIdDesc(user.getId(), purpose).orElse(null);
        if (otp == null) {
            audit.recordDeniedBy(user.getId(), user.getRole(), EventCode.AUTH_OTP_FAILED, "NO_ACTIVE_OTP", "USER", user.getId(), "Không có mã OTP đang hiệu lực", "purpose", purpose);
            throw ApiException.badRequest("INVALID_OTP", "Mã OTP không đúng hoặc đã hết hạn");
        }
        if (otp.getAttempts() >= MAX_OTP_ATTEMPTS || otp.getExpiresAt().isBefore(Instant.now())) {
            boolean locked = otp.getAttempts() >= MAX_OTP_ATTEMPTS;
            audit.recordDeniedBy(user.getId(), user.getRole(), locked ? EventCode.AUTH_OTP_LOCKED : EventCode.AUTH_OTP_FAILED,
                    locked ? "TOO_MANY_ATTEMPTS" : "EXPIRED", "USER", user.getId(), locked ? "Mã OTP bị khoá vì nhập sai quá nhiều lần" : "Mã OTP hết hạn",
                    "purpose", purpose);
            throw ApiException.badRequest("INVALID_OTP", "Mã OTP đã hết hạn, vui lòng yêu cầu mã mới");
        }
        if (!MessageDigest.isEqual(otp.getCode().getBytes(StandardCharsets.UTF_8), code.trim().getBytes(StandardCharsets.UTF_8))) {
            // Lưu trong giao dịch riêng: lỗi ném ra bên dưới sẽ hoàn lại giao dịch hiện tại.
            otpAttempts.increment(otp.getId());
            audit.recordDeniedBy(user.getId(), user.getRole(), EventCode.AUTH_OTP_FAILED, "WRONG_CODE", "USER", user.getId(), "Nhập sai mã OTP",
                    "purpose", purpose, "attempt", otp.getAttempts() + 1);
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
                userService.me(user.getId()), exposeOtp(otp));
    }

    private static void ensureActive(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw ApiException.forbidden("Tài khoản đã bị khoá"
                    + (user.getLockReason() != null ? ": " + user.getLockReason() : ""));
        }
    }

    /** Băm ngắn của email để đối chiếu nhiều lần thử mà không lưu email vào nhật ký. */
    private static String emailHash(String email) {
        return sha256(email.trim().toLowerCase()).substring(0, 16);
    }

    private static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
