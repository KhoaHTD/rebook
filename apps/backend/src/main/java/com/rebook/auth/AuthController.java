package com.rebook.auth;

import com.rebook.auth.AuthDtos.AuthResponse;
import com.rebook.auth.AuthDtos.ForgotPasswordRequest;
import com.rebook.auth.AuthDtos.LoginRequest;
import com.rebook.auth.AuthDtos.OtpSentResponse;
import com.rebook.auth.AuthDtos.RefreshRequest;
import com.rebook.auth.AuthDtos.RegisterRequest;
import com.rebook.auth.AuthDtos.ResetPasswordRequest;
import com.rebook.auth.AuthDtos.SendOtpRequest;
import com.rebook.auth.AuthDtos.VerifyOtpRequest;
import com.rebook.common.ApiException;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Auth")
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "Đăng ký — gửi OTP xác thực email")
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest req) {
        return authService.register(req);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest req) {
        return authService.login(req);
    }

    @Operation(summary = "Đổi refresh token lấy cặp token mới")
    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest req) {
        return authService.refresh(req.refreshToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest req) {
        authService.logout(req.refreshToken());
    }

    @Operation(summary = "Gửi OTP xác thực email / SĐT (cần đăng nhập)")
    @PostMapping("/send-otp")
    public OtpSentResponse sendOtp(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody SendOtpRequest req) {
        return authService.sendOtp(requireLogin(me), req.purpose());
    }

    @Operation(summary = "Xác thực OTP email / SĐT (cần đăng nhập)")
    @PostMapping("/verify-otp")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void verifyOtp(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody VerifyOtpRequest req) {
        authService.verifyOtp(requireLogin(me), req.purpose(), req.code());
    }

    @PostMapping("/forgot-password")
    public OtpSentResponse forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        return authService.forgotPassword(req.email());
    }

    @PostMapping("/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req);
    }

    private static Long requireLogin(UserPrincipal me) {
        if (me == null) {
            throw ApiException.unauthorized("UNAUTHORIZED", "Cần đăng nhập");
        }
        return me.id();
    }
}
