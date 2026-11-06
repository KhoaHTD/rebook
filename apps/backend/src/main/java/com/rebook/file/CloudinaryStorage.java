package com.rebook.file;

import com.rebook.common.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import java.util.TreeMap;

/**
 * Đẩy ảnh lên Cloudinary (upload có ký, gọi REST, không cần thêm thư viện).
 * Bật khi biến môi trường {@code CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>} có giá trị thật;
 * không có (hoặc còn là chữ mẫu {@code <...>}) thì {@link FileController} lưu vào thư mục {@code app.storage.dir}.
 * API secret chỉ nằm trong biến môi trường, không ghi log, không đưa vào repo.
 */
@Component
public class CloudinaryStorage {

    private static final Logger log = LoggerFactory.getLogger(CloudinaryStorage.class);

    /** Kết quả phân tích CLOUDINARY_URL. */
    record Credentials(String cloudName, String apiKey, String apiSecret) {
    }

    private final Credentials credentials;
    private final String folder;
    private final RestClient http = RestClient.create();

    public CloudinaryStorage(@Value("${app.cloudinary.url:}") String url,
                             @Value("${app.cloudinary.folder:rebook}") String folder) {
        this.credentials = parse(url);
        this.folder = folder;
        if (!url.isBlank() && credentials == null) {
            log.warn("CLOUDINARY_URL có nhưng chưa hợp lệ (còn chữ mẫu?), ảnh vẫn lưu vào thư mục cục bộ.");
        } else if (credentials != null) {
            log.info("Ảnh tải lên được lưu trên Cloudinary (cloud '{}', thư mục '{}').", credentials.cloudName(), folder);
        }
    }

    public boolean enabled() {
        return credentials != null;
    }

    /** Tải ảnh lên, trả URL https đầy đủ. Lỗi mạng / Cloudinary từ chối thì trả 502 để app báo "thử lại". */
    public String upload(MultipartFile file) throws IOException {
        String timestamp = String.valueOf(System.currentTimeMillis() / 1000);
        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("file", new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                String n = file.getOriginalFilename();
                return n == null || n.isBlank() ? "upload" : n;
            }
        });
        form.add("api_key", credentials.apiKey());
        form.add("timestamp", timestamp);
        form.add("folder", folder);
        form.add("signature", sign(Map.of("folder", folder, "timestamp", timestamp), credentials.apiSecret()));
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = http.post()
                    .uri(URI.create("https://api.cloudinary.com/v1_1/" + credentials.cloudName() + "/image/upload"))
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(form)
                    .retrieve()
                    .body(Map.class);
            Object secureUrl = body == null ? null : body.get("secure_url");
            if (secureUrl == null) {
                throw new ApiException(HttpStatus.BAD_GATEWAY, "STORAGE_FAILED", "Không lưu được ảnh, thử lại sau");
            }
            return secureUrl.toString();
        } catch (RestClientException e) {
            log.warn("Upload Cloudinary lỗi: {}", e.getMessage());
            throw new ApiException(HttpStatus.BAD_GATEWAY, "STORAGE_FAILED", "Không lưu được ảnh, thử lại sau");
        }
    }

    /** {@code cloudinary://key:secret@cloud}; trả null nếu trống hoặc còn chữ mẫu. */
    static Credentials parse(String url) {
        if (url == null || url.isBlank() || url.contains("<") || url.contains(">")) {
            return null;
        }
        String prefix = "cloudinary://";
        if (!url.startsWith(prefix)) {
            return null;
        }
        String rest = url.substring(prefix.length());
        int at = rest.lastIndexOf('@');
        int colon = rest.indexOf(':');
        if (at < 0 || colon < 0 || colon > at) {
            return null;
        }
        String key = rest.substring(0, colon);
        String secret = rest.substring(colon + 1, at);
        String cloud = rest.substring(at + 1);
        if (key.isBlank() || secret.isBlank() || cloud.isBlank()) {
            return null;
        }
        return new Credentials(cloud, key, secret);
    }

    /** Chữ ký Cloudinary: SHA-1 của "k1=v1&k2=v2" (khoá xếp theo chữ cái) nối với API secret. */
    static String sign(Map<String, String> params, String secret) {
        StringBuilder sb = new StringBuilder();
        new TreeMap<>(params).forEach((k, v) -> {
            if (sb.length() > 0) {
                sb.append('&');
            }
            sb.append(k).append('=').append(v);
        });
        sb.append(secret);
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-1").digest(sb.toString().getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
