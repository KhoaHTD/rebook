package com.rebook.notification;

import com.rebook.common.PageResponse;
import com.rebook.notification.NotificationService.NotificationResponse;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Tag(name = "Notification")
@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService service;

    @GetMapping
    public PageResponse<NotificationResponse> list(@AuthenticationPrincipal UserPrincipal me,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        return service.list(me.id(), page, size);
    }

    @GetMapping("/unread-count")
    public Map<String, Long> unread(@AuthenticationPrincipal UserPrincipal me) {
        return Map.of("count", service.unreadCount(me.id()));
    }

    @PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void read(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        service.markRead(me.id(), id);
    }

    @PostMapping("/read-all")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void readAll(@AuthenticationPrincipal UserPrincipal me) {
        service.markAllRead(me.id());
    }
}
