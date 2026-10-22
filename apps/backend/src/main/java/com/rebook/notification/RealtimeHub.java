package com.rebook.notification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.security.JwtService;
import com.rebook.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WebSocket thuần, gửi JSON. Khớp với RealtimeClient của frontend:
 * mỗi kênh là một URL {@code <WS_BASE_URL>/<channel>?token=<jwt>}.
 * <ul>
 *   <li>{@code /ws/sessions/{id}} — phòng đấu giá, ai cũng xem được (Guest không cần token)</li>
 *   <li>{@code /ws/notifications} — thông báo riêng của user, bắt buộc token</li>
 * </ul>
 * Server chỉ phát; mọi thao tác (trả giá...) đi qua REST.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RealtimeHub extends TextWebSocketHandler {

    private final JwtService jwtService;
    private final ObjectMapper objectMapper;

    private final Map<String, Set<WebSocketSession>> channels = new ConcurrentHashMap<>();

    public static String sessionChannel(Long sessionId) {
        return "sessions/" + sessionId;
    }

    public static String userChannel(Long userId) {
        return "users/" + userId;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession raw) throws IOException {
        var uri = raw.getUri();
        String path = uri == null ? "" : uri.getPath();
        String token = uri == null ? null
                : UriComponentsBuilder.fromUri(uri).build().getQueryParams().getFirst("token");
        Optional<UserPrincipal> user = token == null ? Optional.empty() : jwtService.parse(token);

        String channel;
        if (path.matches(".*/ws/sessions/\\d+$")) {
            channel = "sessions/" + path.substring(path.lastIndexOf('/') + 1);
        } else if (path.endsWith("/ws/notifications") && user.isPresent()) {
            channel = userChannel(user.get().id());
        } else {
            raw.close(CloseStatus.POLICY_VIOLATION.withReason("Kênh không hợp lệ hoặc thiếu token"));
            return;
        }
        WebSocketSession session = new ConcurrentWebSocketSessionDecorator(raw, 5_000, 512 * 1024);
        raw.getAttributes().put("channel", channel);
        raw.getAttributes().put("decorated", session);
        channels.computeIfAbsent(channel, k -> ConcurrentHashMap.newKeySet()).add(session);
        log.debug("WS connect {} ({})", channel, user.map(UserPrincipal::email).orElse("guest"));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession raw, CloseStatus status) {
        Object channel = raw.getAttributes().get("channel");
        Object decorated = raw.getAttributes().get("decorated");
        if (channel != null && decorated != null) {
            Set<WebSocketSession> set = channels.get(channel.toString());
            if (set != null) {
                set.remove(decorated);
            }
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // Kênh chỉ phát một chiều; client gửi gì cũng bỏ qua (có thể dùng làm ping).
    }

    /** Gửi sau khi transaction hiện tại commit (nếu có), để client không thấy dữ liệu chưa lưu. */
    public void publish(String channel, Object payload) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    send(channel, payload);
                }
            });
        } else {
            send(channel, payload);
        }
    }

    public int subscriberCount(String channel) {
        Set<WebSocketSession> set = channels.get(channel);
        return set == null ? 0 : set.size();
    }

    private void send(String channel, Object payload) {
        Set<WebSocketSession> set = channels.get(channel);
        if (set == null || set.isEmpty()) {
            return;
        }
        TextMessage message;
        try {
            message = new TextMessage(objectMapper.writeValueAsString(payload));
        } catch (IOException e) {
            log.error("Không serialize được message WS", e);
            return;
        }
        for (WebSocketSession s : set) {
            try {
                if (s.isOpen()) {
                    s.sendMessage(message);
                } else {
                    set.remove(s);
                }
            } catch (Exception e) {
                log.debug("Gửi WS lỗi, bỏ session: {}", e.getMessage());
                set.remove(s);
            }
        }
    }
}
