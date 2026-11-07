package com.rebook.file;

import com.rebook.common.ApiException;
import com.rebook.security.UserPrincipal;
import com.rebook.wallet.WalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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
 * Tải ảnh lên và phục vụ lại. File lưu trong thư mục {@code app.storage.dir};
 * tên file do server sinh nên không đoán được và không lọt ra ngoài thư mục.
 * Ảnh biên lai chuyển khoản nằm ở {@code /files/private/*}: cần đăng nhập, chỉ người rút và Admin / Staff xem được (BE-34).
 */
@Tag(name = "Files")
@RestController
public class FileController {

    private static final Map<String, String> TYPES = Map.of(
            "image/png", "png", "image/jpeg", "jpg", "image/webp", "webp");

    /** Thư mục (do app gửi kèm khi tải lên) chứa ảnh nhạy cảm: luôn lưu cục bộ, không đưa lên Cloudinary. */
    private static final java.util.Set<String> SENSITIVE_FOLDERS = java.util.Set.of("withdrawal-receipts");

    private final FileStorage storage;
    private final WalletService walletService;
    private final com.rebook.audit.AuditLog audit;

    private final CloudinaryStorage cloudinary;

    public FileController(FileStorage storage, WalletService walletService, com.rebook.audit.AuditLog audit,
                          CloudinaryStorage cloudinary) {
        this.storage = storage;
        this.walletService = walletService;
        this.audit = audit;
        this.cloudinary = cloudinary;
    }

    public record FileResponse(String url, String contentType, long size) {
    }

    @Operation(summary = "Tải ảnh lên (PNG / JPEG / WebP, tối đa 5MB). Trả về URL (tương đối khi lưu cục bộ, https đầy đủ khi bật Cloudinary) để gắn vào nghiệp vụ")
    @PostMapping(value = "/files", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public FileResponse upload(@RequestParam("file") MultipartFile file,
                               @RequestParam(value = "folder", required = false) String folder) throws IOException {
        String ext = TYPES.get(file.getContentType());
        if (file.isEmpty() || ext == null) {
            audit.recordDenied(com.rebook.audit.EventCode.FILE_REJECTED, "INVALID_FILE", "FILE", null, "Tệp tải lên bị từ chối",
                    "contentType", file.getContentType(), "size", file.getSize());
            throw ApiException.badRequest("INVALID_FILE", "Chỉ nhận ảnh PNG, JPEG hoặc WebP");
        }
        // Biên lai chuyển khoản có số tài khoản (BE-34) phải ở lại máy chủ: khi hoàn tất rút tiền sẽ được chuyển vào
        // thư mục riêng cần đăng nhập mới xem (FileStorage.makePrivate), điều mà link công khai trên Cloudinary không làm được.
        boolean sensitive = folder != null && SENSITIVE_FOLDERS.contains(folder);
        if (cloudinary.enabled() && !sensitive) {
            String url = cloudinary.upload(file);
            // target_id chỉ chứa 60 ký tự: URL Cloudinary dài hơn nên chỉ ghi tên tệp (đoạn cuối của URL).
            String shortName = url.substring(url.lastIndexOf('/') + 1);
            audit.record(com.rebook.audit.EventCode.FILE_UPLOADED, "FILE",
                    shortName.length() > 60 ? shortName.substring(0, 60) : shortName, null, "Tải ảnh lên Cloudinary",
                    "contentType", file.getContentType(), "size", file.getSize());
            return new FileResponse(url, file.getContentType(), file.getSize());
        }
        Path dir = storage.publicDir();
        Files.createDirectories(dir);
        String name = UUID.randomUUID() + "." + ext;
        Files.copy(file.getInputStream(), dir.resolve(name), StandardCopyOption.REPLACE_EXISTING);
        audit.record(com.rebook.audit.EventCode.FILE_UPLOADED, "FILE", name, null, "Tải ảnh lên",
                "contentType", file.getContentType(), "size", file.getSize());
        return new FileResponse(FileStorage.PUBLIC_PREFIX + name, file.getContentType(), file.getSize());
    }

    @Operation(summary = "Xem ảnh đã tải lên")
    @GetMapping("/files/{name}")
    public ResponseEntity<Resource> download(@PathVariable String name) {
        Path path = storage.publicFile(name).orElseThrow(() -> ApiException.notFound("tệp"));
        return ResponseEntity.ok().contentType(type(name))
                .cacheControl(CacheControl.maxAge(7, TimeUnit.DAYS).cachePublic())
                .header("X-Content-Type-Options", "nosniff")
                .body(new FileSystemResource(path));
    }

    @Operation(summary = "Xem ảnh biên lai chuyển khoản (cần đăng nhập: người rút hoặc Admin / Staff)")
    @GetMapping("/files/private/{name}")
    public ResponseEntity<Resource> downloadPrivate(@AuthenticationPrincipal UserPrincipal me, @PathVariable String name) {
        Path path = storage.privateFile(name).orElseThrow(() -> ApiException.notFound("tệp"));
        // Không có quyền thì trả 404 như không có file, để không lộ tên file nào tồn tại
        if (!walletService.canViewProof(me, FileStorage.PRIVATE_PREFIX + name)) {
            throw ApiException.notFound("tệp");
        }
        return ResponseEntity.ok().contentType(type(name))
                .cacheControl(CacheControl.noStore().cachePrivate())
                .header("X-Content-Type-Options", "nosniff")
                .body(new FileSystemResource(path));
    }

    private static MediaType type(String name) {
        return switch (name.substring(name.lastIndexOf('.') + 1)) {
            case "png" -> MediaType.IMAGE_PNG;
            case "webp" -> MediaType.parseMediaType("image/webp");
            default -> MediaType.IMAGE_JPEG;
        };
    }
}
