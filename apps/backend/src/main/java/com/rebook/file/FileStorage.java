package com.rebook.file;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Optional;
import java.util.Set;

/**
 * Nơi lưu ảnh tải lên. Ảnh thường (sách, kiểm định, trả hàng) ở thư mục gốc, xem công khai qua {@code /files/<tên>}.
 * Ảnh nhạy cảm (biên lai chuyển khoản có số tài khoản, BE-34) chuyển vào {@code private/}, xem qua
 * {@code /files/private/<tên>} và cần đăng nhập + quyền.
 */
@Component
public class FileStorage {

    public static final String PUBLIC_PREFIX = "/files/";
    public static final String PRIVATE_PREFIX = "/files/private/";
    static final Set<String> EXTENSIONS = Set.of("png", "jpg", "webp");

    private final Path dir;
    private final Path privateDir;

    public FileStorage(@Value("${app.storage.dir:uploads}") String dir) {
        this.dir = Path.of(dir).toAbsolutePath().normalize();
        this.privateDir = this.dir.resolve("private");
    }

    Path publicDir() {
        return dir;
    }

    /** Đường dẫn file công khai theo tên; rỗng nếu tên không hợp lệ hoặc không có file. */
    Optional<Path> publicFile(String name) {
        return resolve(dir, name);
    }

    Optional<Path> privateFile(String name) {
        return resolve(privateDir, name);
    }

    /**
     * Chuyển một ảnh công khai ({@code /files/<tên>}) vào thư mục riêng, trả URL mới {@code /files/private/<tên>}.
     * URL đã riêng tư, URL ngoài hệ thống hoặc file không có trên đĩa thì trả nguyên (không làm hỏng nghiệp vụ).
     */
    public String makePrivate(String url) {
        if (url == null || url.startsWith(PRIVATE_PREFIX) || !url.startsWith(PUBLIC_PREFIX)) {
            return url;
        }
        String name = url.substring(PUBLIC_PREFIX.length());
        Optional<Path> source = publicFile(name);
        if (source.isEmpty()) {
            return url;
        }
        try {
            Files.createDirectories(privateDir);
            Files.move(source.get(), privateDir.resolve(name), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new UncheckedIOException("Không chuyển được ảnh biên lai vào thư mục riêng", e);
        }
        return PRIVATE_PREFIX + name;
    }

    private static Optional<Path> resolve(Path base, String name) {
        if (name == null || name.contains("/") || name.contains("\\") || !name.contains(".")) {
            return Optional.empty();
        }
        String ext = name.substring(name.lastIndexOf('.') + 1);
        Path path = base.resolve(name).normalize();
        if (!EXTENSIONS.contains(ext) || !path.startsWith(base) || !path.getParent().equals(base) || !Files.isRegularFile(path)) {
            return Optional.empty();
        }
        return Optional.of(path);
    }
}
