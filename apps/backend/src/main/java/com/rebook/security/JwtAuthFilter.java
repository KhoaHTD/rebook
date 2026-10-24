package com.rebook.security;

import com.rebook.user.UserRepository;
import com.rebook.user.UserStatus;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/** Đọc "Authorization: Bearer <jwt>", gắn UserPrincipal vào SecurityContext. Vai trò lấy từ DB (đổi vai trò có hiệu lực ngay); tài khoản bị khoá coi như chưa đăng nhập. */
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            jwtService.parse(header.substring(7)).ifPresent(parsed -> {
                userRepository.findStatusRoleById(parsed.id())
                        .filter(sr -> sr.getStatus() == UserStatus.ACTIVE)
                        .ifPresent(sr -> {
                            var principal = new UserPrincipal(parsed.id(), parsed.email(), sr.getRole());
                            var auth = new UsernamePasswordAuthenticationToken(principal, null,
                                    List.of(new SimpleGrantedAuthority("ROLE_" + principal.role().name())));
                            SecurityContextHolder.getContext().setAuthentication(auth);
                        });
            });
        }
        chain.doFilter(request, response);
    }
}
