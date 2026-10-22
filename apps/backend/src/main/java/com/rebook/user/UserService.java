package com.rebook.user;

import com.rebook.common.ApiException;
import com.rebook.user.UserDtos.AddressRequest;
import com.rebook.user.UserDtos.AddressResponse;
import com.rebook.user.UserDtos.ChangePasswordRequest;
import com.rebook.user.UserDtos.ShopRequest;
import com.rebook.user.UserDtos.ShopResponse;
import com.rebook.user.UserDtos.UpdateProfileRequest;
import com.rebook.user.UserDtos.UserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final ShopRepository shopRepository;
    private final AddressRepository addressRepository;
    private final PasswordEncoder passwordEncoder;

    public User getUser(Long id) {
        return userRepository.findById(id).orElseThrow(() -> ApiException.notFound("người dùng"));
    }

    public UserResponse me(Long userId) {
        User user = getUser(userId);
        Long shopId = shopRepository.findByUserId(userId).map(Shop::getId).orElse(null);
        return UserResponse.of(user, shopId);
    }

    @Transactional
    public UserResponse updateProfile(Long userId, UpdateProfileRequest req) {
        User user = getUser(userId);
        user.setFullName(req.fullName().trim());
        user.setAvatarUrl(req.avatarUrl());
        if (req.phone() != null && !Objects.equals(req.phone(), user.getPhone())) {
            if (userRepository.existsByPhone(req.phone())) {
                throw ApiException.conflict("PHONE_TAKEN", "Số điện thoại đã được dùng");
            }
            user.setPhone(req.phone());
            user.setPhoneVerified(false); // đổi số thì phải xác thực lại
        }
        return me(userId);
    }

    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest req) {
        User user = getUser(userId);
        if (!passwordEncoder.matches(req.currentPassword(), user.getPasswordHash())) {
            throw ApiException.badRequest("WRONG_PASSWORD", "Mật khẩu hiện tại không đúng");
        }
        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
    }

    // ---- Sổ địa chỉ ----

    public List<AddressResponse> addresses(Long userId) {
        return addressRepository.findByUserIdOrderByDefaultAddressDescIdAsc(userId).stream()
                .map(AddressResponse::of).toList();
    }

    public Address getAddress(Long userId, Long addressId) {
        return addressRepository.findByIdAndUserId(addressId, userId)
                .orElseThrow(() -> ApiException.notFound("địa chỉ"));
    }

    @Transactional
    public AddressResponse addAddress(Long userId, AddressRequest req) {
        Address a = new Address();
        a.setUserId(userId);
        apply(a, req);
        // Địa chỉ đầu tiên luôn là mặc định
        a.setDefaultAddress(req.isDefault() || addressRepository.countByUserId(userId) == 0);
        a = addressRepository.save(a);
        if (a.isDefaultAddress()) {
            addressRepository.clearDefault(userId, a.getId());
        }
        return AddressResponse.of(a);
    }

    @Transactional
    public AddressResponse updateAddress(Long userId, Long id, AddressRequest req) {
        Address a = getAddress(userId, id);
        apply(a, req);
        if (req.isDefault()) {
            a.setDefaultAddress(true);
            addressRepository.clearDefault(userId, a.getId());
        }
        return AddressResponse.of(a);
    }

    @Transactional
    public void deleteAddress(Long userId, Long id) {
        addressRepository.delete(getAddress(userId, id));
    }

    private void apply(Address a, AddressRequest req) {
        a.setReceiverName(req.receiverName().trim());
        a.setPhone(req.phone());
        a.setProvince(req.province().trim());
        a.setDistrict(req.district().trim());
        a.setWard(req.ward().trim());
        a.setDetail(req.detail().trim());
    }

    // ---- Shop ----

    public Shop requireShop(Long userId) {
        return shopRepository.findByUserId(userId)
                .orElseThrow(() -> ApiException.forbidden("Bạn cần bật Shop trước khi bán hàng"));
    }

    public ShopResponse myShop(Long userId) {
        return ShopResponse.ownerView(requireShop(userId));
    }

    public ShopResponse publicShop(Long shopId) {
        return ShopResponse.publicView(shopRepository.findById(shopId).orElseThrow(() -> ApiException.notFound("shop")));
    }

    /** Bật shop lần đầu hoặc cập nhật thông tin shop. */
    @Transactional
    public ShopResponse upsertShop(Long userId, ShopRequest req) {
        User user = getUser(userId);
        if (!user.isEmailVerified()) {
            throw ApiException.forbidden("Cần xác thực email trước khi mở shop");
        }
        Shop shop = shopRepository.findByUserId(userId).orElse(null);
        if (shop == null) {
            if (shopRepository.existsByNameIgnoreCase(req.name().trim())) {
                throw ApiException.conflict("SHOP_NAME_TAKEN", "Tên shop đã tồn tại");
            }
            shop = new Shop();
            shop.setUserId(userId);
        } else if (!shop.getName().equalsIgnoreCase(req.name().trim())
                && shopRepository.existsByNameIgnoreCase(req.name().trim())) {
            throw ApiException.conflict("SHOP_NAME_TAKEN", "Tên shop đã tồn tại");
        }
        shop.setName(req.name().trim());
        shop.setDescription(req.description());
        shop.setPickupAddress(req.pickupAddress().trim());
        shop.setPickupProvince(req.pickupProvince().trim());
        shop.setBankName(req.bankName().trim());
        shop.setBankAccountNumber(req.bankAccountNumber().trim());
        shop.setBankAccountHolder(req.bankAccountHolder().trim());
        return ShopResponse.ownerView(shopRepository.save(shop));
    }
}
