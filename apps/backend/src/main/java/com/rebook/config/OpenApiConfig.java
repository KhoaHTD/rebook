package com.rebook.config;

import com.rebook.auction.AuctionDtos.AuctionEvent;
import io.swagger.v3.core.converter.ModelConverters;
import io.swagger.v3.core.jackson.ModelResolver;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info = @Info(title = "ReBook API", version = "0.1.0",
                description = "Chợ sách cũ: bán giá cố định + đấu giá. Realtime đấu giá qua WebSocket ws://<host>/ws/sessions/{id}"),
        servers = @Server(url = "http://localhost:8080"),
        security = @SecurityRequirement(name = "bearerAuth"))
@SecurityScheme(name = "bearerAuth", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT")
public class OpenApiConfig {

    static {
        // Enum thành schema dùng chung (ConditionGrade, LotStatus...) thay vì lặp lại trong từng model,
        // để client sinh ra chỉ có một kiểu enum cho mỗi loại.
        ModelResolver.enumsAsRef = true;
    }

    /**
     * Sự kiện WebSocket không đi qua endpoint REST nào nên springdoc không tự thấy.
     * Đăng ký thủ công để client frontend sinh được model `AuctionEvent`.
     */
    @Bean
    OpenApiCustomizer websocketSchemas() {
        return openApi -> ModelConverters.getInstance().readAll(AuctionEvent.class)
                .forEach((name, schema) -> openApi.getComponents().addSchemas(name, schema));
    }
}
