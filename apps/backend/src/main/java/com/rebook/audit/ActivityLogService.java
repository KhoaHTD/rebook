package com.rebook.audit;

import com.rebook.common.PageResponse;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Ghi và đọc nhật ký thao tác Admin. {@link #record} chạy chung transaction với thao tác nghiệp vụ. */
@Service
@RequiredArgsConstructor
public class ActivityLogService {

    public static final String LISTING = "LISTING";
    public static final String WITHDRAWAL = "WITHDRAWAL";
    public static final String USER = "USER";
    public static final String SHOP = "SHOP";
    public static final String CONFIG = "CONFIG";

    public record ActivityLogResponse(Long id, Long adminId, String adminName, String action, String targetType,
                                      String targetId, String summary, Instant createdAt) {
    }

    private final ActivityLogRepository repository;
    private final UserRepository userRepository;

    @Transactional(propagation = Propagation.MANDATORY)
    public void record(Long adminId, String action, String targetType, Object targetId, String summary) {
        ActivityLog log = new ActivityLog();
        log.setAdminId(adminId);
        log.setAction(action);
        log.setTargetType(targetType);
        log.setTargetId(targetId == null ? null : String.valueOf(targetId));
        log.setSummary(summary.length() > 500 ? summary.substring(0, 500) : summary);
        repository.save(log);
    }

    @Transactional(readOnly = true)
    public PageResponse<ActivityLogResponse> search(String targetType, String action, Long adminId, int page, int size) {
        var result = repository.search(blankToNull(targetType), blankToNull(action), adminId, PageRequest.of(page, size));
        Map<Long, String> names = userRepository.findAllById(result.getContent().stream().map(ActivityLog::getAdminId).distinct().toList())
                .stream().collect(Collectors.toMap(User::getId, User::getFullName, (a, b) -> a));
        return PageResponse.of(result, l -> new ActivityLogResponse(l.getId(), l.getAdminId(), names.get(l.getAdminId()),
                l.getAction(), l.getTargetType(), l.getTargetId(), l.getSummary(), l.getCreatedAt()));
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
