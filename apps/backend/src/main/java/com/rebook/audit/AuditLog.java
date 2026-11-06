package com.rebook.audit;

import com.rebook.security.UserPrincipal;
import com.rebook.user.Role;
import lombok.RequiredArgsConstructor;
import org.slf4j.MDC;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Cửa duy nhất để ghi sự kiện (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D).
 * {@link #record} chạy chung giao dịch với việc nghiệp vụ (việc lỗi thì log cũng rollback);
 * {@link #recordDenied} chạy giao dịch riêng để việc bị từ chối vẫn có dấu vết.
 * Người làm lấy từ phiên đăng nhập hiện tại; không có thì là SYSTEM (job tự động).
 */
@Service
@RequiredArgsConstructor
public class AuditLog {

    static final String MDC_REQUEST_ID = "requestId";
    static final String MDC_IP = "ip";

    private final AuditEventRepository repository;

    /** details: các cặp khoá, giá trị (BigDecimal ghi dạng chuỗi số nguyên, enum ghi tên). */
    @Transactional(propagation = Propagation.REQUIRED)
    public void record(EventCode code, String targetType, Object targetId, String refCode, String summary, Object... details) {
        save(code, "SUCCESS", null, targetType, targetId, refCode, summary, details, null);
    }

    /** Ghi thay mặt một người khi chưa có phiên đăng nhập (đăng nhập, đăng ký, đặt lại mật khẩu). actorId null = khách chưa rõ danh tính. */
    @Transactional(propagation = Propagation.REQUIRED)
    public void recordBy(Long actorId, Role role, EventCode code, String targetType, Object targetId, String refCode,
                         String summary, Object... details) {
        save(code, "SUCCESS", null, targetType, targetId, refCode, summary, details, new Actor(actorId, role));
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordDeniedBy(Long actorId, Role role, EventCode code, String reasonCode, String targetType, Object targetId,
                               String summary, Object... details) {
        save(code, "DENIED", reasonCode, targetType, targetId, null, summary, details, new Actor(actorId, role));
    }

    private record Actor(Long id, Role role) {
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordDenied(EventCode code, String reasonCode, String targetType, Object targetId, String summary,
                             Object... details) {
        save(code, "DENIED", reasonCode, targetType, targetId, null, summary, details, null);
    }

    private void save(EventCode code, String result, String reasonCode, String targetType, Object targetId,
                      String refCode, String summary, Object[] details, Actor actor) {
        AuditEvent e = new AuditEvent();
        e.setEventCode(code.code());
        e.setCategory(code.category().name());
        e.setResult(result);
        e.setReasonCode(reasonCode);
        e.setTargetType(targetType);
        e.setTargetId(targetId == null ? null : String.valueOf(targetId));
        e.setRefCode(refCode);
        e.setSummary(summary == null ? null : (summary.length() > 500 ? summary.substring(0, 500) : summary));
        e.setRequestId(MDC.get(MDC_REQUEST_ID));
        e.setIp(MDC.get(MDC_IP));
        e.setChannel(RequestContextHolder.getRequestAttributes() == null ? "JOB" : "API");
        e.setDetails(toMap(details));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (actor != null) {
            e.setActorId(actor.id());
            e.setActorRole(actor.role() == null ? null : actor.role().name());
            e.setActorType(actor.role() == null ? "USER" : actor.role().name()); // không rõ danh tính = khách
        } else if (auth != null && auth.getPrincipal() instanceof UserPrincipal p) {
            e.setActorId(p.id());
            e.setActorRole(p.role().name());
            e.setActorType(p.role().name()); // USER / STAFF / ADMIN trùng tên với actor_type
        } else {
            e.setActorType("SYSTEM");
        }
        repository.save(e);
    }

    private static Map<String, Object> toMap(Object[] kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; kv != null && i + 1 < kv.length; i += 2) {
            Object v = kv[i + 1];
            if (v instanceof BigDecimal b) {
                v = b.toPlainString();
            } else if (v instanceof Enum<?> en) {
                v = en.name();
            } else if (v != null && !(v instanceof Number) && !(v instanceof Boolean) && !(v instanceof String)) {
                v = String.valueOf(v);
            }
            m.put(String.valueOf(kv[i]), v);
        }
        return m;
    }
}
