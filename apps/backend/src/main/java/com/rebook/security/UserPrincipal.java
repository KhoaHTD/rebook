package com.rebook.security;

import com.rebook.user.Role;

/** Người dùng đang đăng nhập, lấy trong controller bằng {@code @AuthenticationPrincipal UserPrincipal me}. */
public record UserPrincipal(Long id, String email, Role role) {

    public boolean isStaffOrAdmin() {
        return role == Role.STAFF || role == Role.ADMIN;
    }
}
