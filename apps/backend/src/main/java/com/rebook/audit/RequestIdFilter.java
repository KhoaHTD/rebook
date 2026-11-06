package com.rebook.audit;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/** Gán mã yêu cầu (đọc hoặc sinh {@code X-Request-Id}) và IP vào MDC để mọi dòng log / sự kiện nối được với nhau. */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {

    public static final String HEADER = "X-Request-Id";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String id = request.getHeader(HEADER);
        // Chỉ nhận mã ngắn, ký tự an toàn; ngoài ra tự sinh (tránh nhồi nội dung tuỳ ý vào log).
        if (id == null || !id.matches("[A-Za-z0-9._-]{8,40}")) {
            id = UUID.randomUUID().toString();
        }
        MDC.put(AuditLog.MDC_REQUEST_ID, id);
        MDC.put(AuditLog.MDC_IP, request.getRemoteAddr());
        response.setHeader(HEADER, id);
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.remove(AuditLog.MDC_REQUEST_ID);
            MDC.remove(AuditLog.MDC_IP);
        }
    }
}
