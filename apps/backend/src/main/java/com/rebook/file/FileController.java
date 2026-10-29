package com.rebook.file;

import com.rebook.common.ApiException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Tải ảnh lên (biên lai chuyển khoản...) và phục vụ lại. File lưu trong thư mục {@code app.storage.dir};
 * tên file do server sinh nên không đoán được và không lọt ra ngoài thư mục.
 */
@Tag(name = "Files")
@RestController
public class FileController {

    private static final Map<String, String> TYPES = Map.of(
            "image/png", "png", "image/jpeg", "jpg", "image/webp", "webp");

    private final Path dir;

    public FileController(@Value("${app.storage.dir:uploads}") String dir) {
        this.dir = Path.of(dir).toAbsolutePath().normalize();
    }

    public record FileResponse(String url, String contentType, long size) {
    }

    @Operation(summary = "Tải ảnh lên (PNG / JPEG / WebP, tối đa 5MB). Trả về URL tương đối để gắn vào nghiệp vụ")
    @PostMapping("/files")
    public FileResponse upload(@RequestParam("file") MultipartFile file) throws IOException {
        String ext = TYPES.get(file.getContentType());
        if (file.isEmpty() || ext == null) {
            throw ApiException.badRequest("INVALID_FILE", "Chỉ nhận ảnh PNG, JPEG hoặc WebP");
        }
        Files.createDirectories(dir);
        String name = UUID.randomUUID() + "." + ext;
        Files.copy(file.getInputStream(), dir.resolve(name), StandardCopyOption.REPLACE_EXISTING);
        return new FileResponse("/files/" + name, file.getContentType(), file.getSize());
    }

    @Operation(summary = "Xem ảnh đã tải lên")
    @GetMapping("/files/{name}")
    public ResponseEntity<Resource> download(@PathVariable String name) {
        Path path = dir.resolve(name).normalize();
        String ext = name.substring(name.lastIndexOf('.') + 1);
        if (!path.startsWith(dir) || !name.contains(".") || !TYPES.containsValue(ext) || !Files.isRegularFile(path)) {
            throw ApiException.notFound("tệp");
        }
        MediaType type = switch (ext) {
            case "png" -> MediaType.IMAGE_PNG;
            case "webp" -> MediaType.parseMediaType("image/webp");
            default -> MediaType.IMAGE_JPEG;
        };
        return ResponseEntity.ok().contentType(type)
                .cacheControl(CacheControl.maxAge(7, TimeUnit.DAYS).cachePublic())
                .header("X-Content-Type-Options", "nosniff")
                .body(new FileSystemResource(path));
    }
}
