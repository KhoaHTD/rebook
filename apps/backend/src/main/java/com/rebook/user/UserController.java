package com.rebook.user;

import com.rebook.security.UserPrincipal;
import com.rebook.user.UserDtos.AddressRequest;
import com.rebook.user.UserDtos.AddressResponse;
import com.rebook.user.UserDtos.ChangePasswordRequest;
import com.rebook.user.UserDtos.ShopRequest;
import com.rebook.user.UserDtos.ShopResponse;
import com.rebook.user.UserDtos.UpdateProfileRequest;
import com.rebook.user.UserDtos.UserResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "User")
@RestController
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @Operation(summary = "Hồ sơ của tôi")
    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal UserPrincipal me) {
        return userService.me(me.id());
    }

    @PutMapping("/me")
    public UserResponse updateProfile(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody UpdateProfileRequest req) {
        return userService.updateProfile(me.id(), req);
    }

    @PostMapping("/me/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ChangePasswordRequest req) {
        userService.changePassword(me.id(), req);
    }

    @Operation(summary = "Sổ địa chỉ")
    @GetMapping("/me/addresses")
    public List<AddressResponse> addresses(@AuthenticationPrincipal UserPrincipal me) {
        return userService.addresses(me.id());
    }

    @PostMapping("/me/addresses")
    @ResponseStatus(HttpStatus.CREATED)
    public AddressResponse addAddress(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody AddressRequest req) {
        return userService.addAddress(me.id(), req);
    }

    @PutMapping("/me/addresses/{id}")
    public AddressResponse updateAddress(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                         @Valid @RequestBody AddressRequest req) {
        return userService.updateAddress(me.id(), id, req);
    }

    @DeleteMapping("/me/addresses/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAddress(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        userService.deleteAddress(me.id(), id);
    }

    @Operation(summary = "Shop của tôi (kèm thông tin nhận tiền)")
    @GetMapping("/me/shop")
    public ShopResponse myShop(@AuthenticationPrincipal UserPrincipal me) {
        return userService.myShop(me.id());
    }

    @Operation(summary = "Bật shop / cập nhật thông tin shop")
    @PutMapping("/me/shop")
    public ShopResponse upsertShop(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ShopRequest req) {
        return userService.upsertShop(me.id(), req);
    }

    @Operation(summary = "Trang shop công khai")
    @GetMapping("/shops/{id}")
    public ShopResponse shop(@PathVariable Long id) {
        return userService.publicShop(id);
    }
}
