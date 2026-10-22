package com.rebook.config;

import com.rebook.notification.RealtimeHub;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final RealtimeHub hub;
    private final AppProperties props;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(hub, "/ws/sessions/*", "/ws/notifications")
                .setAllowedOriginPatterns(props.cors().allowedOrigins().toArray(String[]::new));
    }
}
