package com.rebook.auth;

import com.rebook.user.UserDtos;
import com.rebook.user.UserDtos.UserResponse;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class AuthDtos {

    private AuthDtos() {
    }

    public record RegisterRequest(
            @NotBlank @Email String email,
            @NotBlank @Size(min = 8, max = 72, message = "Mật khẩu 8–72 ký tự") String password,
            @NotBlank @Size(max = 120) String fullName,
            @Pattern(regexp = UserDtos.PHONE_REGEX, message = "Số điện thoại không hợp lệ") String phone) {
    }

    public record LoginRequest(@NotBlank @Email String email, @NotBlank String password) {
    }

    public record RefreshRequest(@NotBlank String refreshToken) {
    }

    /** devOtp chỉ có giá trị khi chạy dev (chưa có dịch vụ gửi email / SMS). */
    public record AuthResponse(String accessToken, String refreshToken, String tokenType, long expiresIn,
                               UserResponse user, String devOtp) {
    }

    public record SendOtpRequest(@NotNull OtpCode.Purpose purpose) {
    }

    public record VerifyOtpRequest(@NotNull OtpCode.Purpose purpose, @NotBlank String code) {
    }

    public record OtpSentResponse(String message, String devOtp) {
    }

    public record ForgotPasswordRequest(@NotBlank @Email String email) {
    }

    public record ResetPasswordRequest(@NotBlank @Email String email, @NotBlank String code,
                                       @NotBlank @Size(min = 8, max = 72) String newPassword) {
    }
}
