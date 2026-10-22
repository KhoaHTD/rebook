package com.rebook.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public final class UserDtos {

    private UserDtos() {
    }

    public static final String PHONE_REGEX = "^0\\d{9,10}$";

    public record UserResponse(Long id, String email, String phone, String fullName, String avatarUrl,
                               Role role, UserStatus status, boolean emailVerified, boolean phoneVerified,
                               Instant auctionBannedUntil, Long shopId, Instant createdAt) {

        public static UserResponse of(User u, Long shopId) {
            return new UserResponse(u.getId(), u.getEmail(), u.getPhone(), u.getFullName(), u.getAvatarUrl(),
                    u.getRole(), u.getStatus(), u.isEmailVerified(), u.isPhoneVerified(),
                    u.getAuctionBannedUntil(), shopId, u.getCreatedAt());
        }
    }

    public record UpdateProfileRequest(
            @NotBlank @Size(max = 120) String fullName,
            @Pattern(regexp = PHONE_REGEX, message = "Số điện thoại không hợp lệ") String phone,
            @Size(max = 500) String avatarUrl) {
    }

    public record ChangePasswordRequest(@NotBlank String currentPassword,
                                        @NotBlank @Size(min = 8, max = 72) String newPassword) {
    }

    public record AddressRequest(
            @NotBlank @Size(max = 120) String receiverName,
            @NotBlank @Pattern(regexp = PHONE_REGEX, message = "Số điện thoại không hợp lệ") String phone,
            @NotBlank String province,
            @NotBlank String district,
            @NotBlank String ward,
            @NotBlank @Size(max = 300) String detail,
            boolean isDefault) {
    }

    public record AddressResponse(Long id, String receiverName, String phone, String province, String district,
                                  String ward, String detail, boolean isDefault) {

        public static AddressResponse of(Address a) {
            return new AddressResponse(a.getId(), a.getReceiverName(), a.getPhone(), a.getProvince(),
                    a.getDistrict(), a.getWard(), a.getDetail(), a.isDefaultAddress());
        }
    }

    public record ShopRequest(
            @NotBlank @Size(max = 120) String name,
            @Size(max = 2000) String description,
            @NotBlank @Size(max = 500) String pickupAddress,
            @NotBlank String pickupProvince,
            @NotBlank String bankName,
            @NotBlank @Size(max = 50) String bankAccountNumber,
            @NotBlank @Size(max = 120) String bankAccountHolder) {
    }

    /** Thông tin ngân hàng chỉ trả cho chủ shop (null với người xem khác). */
    public record ShopResponse(Long id, Long ownerId, String name, String description, String pickupProvince,
                               String pickupAddress, BigDecimal ratingAvg, int ratingCount, boolean trusted,
                               String bankName, String bankAccountNumber, String bankAccountHolder,
                               Instant createdAt) {

        public static ShopResponse publicView(Shop s) {
            return new ShopResponse(s.getId(), s.getUserId(), s.getName(), s.getDescription(), s.getPickupProvince(),
                    null, s.getRatingAvg(), s.getRatingCount(), s.isTrusted(), null, null, null, s.getCreatedAt());
        }

        public static ShopResponse ownerView(Shop s) {
            return new ShopResponse(s.getId(), s.getUserId(), s.getName(), s.getDescription(), s.getPickupProvince(),
                    s.getPickupAddress(), s.getRatingAvg(), s.getRatingCount(), s.isTrusted(), s.getBankName(),
                    s.getBankAccountNumber(), s.getBankAccountHolder(), s.getCreatedAt());
        }
    }

    public record EmailRequest(@NotBlank @Email String email) {
    }
}
