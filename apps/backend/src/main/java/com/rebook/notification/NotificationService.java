package com.rebook.notification;

import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Collection;
import java.util.Map;

/**
 * Lưu lịch sử thông báo, đẩy realtime qua kênh {@code /ws/notifications}, và với việc quan trọng thì xếp thêm thư
 * vào {@code email_outbox}. (Frontend không dùng Firebase SDK nên không gửi FCM; muốn thêm push thì gắn vào {@link #notify}.)
 */
@Service
@RequiredArgsConstructor
public class NotificationService {

    // Loại thông báo
    public static final String ORDER = "ORDER";
    public static final String LISTING = "LISTING";
    public static final String CONSIGNMENT = "CONSIGNMENT";
    public static final String AUCTION_REMINDER = "AUCTION_REMINDER";
    public static final String AUCTION_OUTBID = "AUCTION_OUTBID";
    public static final String AUCTION_WON = "AUCTION_WON";
    public static final String AUCTION = "AUCTION";
    public static final String WALLET = "WALLET";

    private final NotificationRepository repository;
    private final RealtimeHub hub;
    private final EmailOutboxRepository outbox;
    private final UserRepository userRepository;
    private final MailService mail;

    @Value("${app.payment.app-url:}")
    private String appUrl;

    public record NotificationResponse(Long id, String type, String title, String body, Map<String, Object> data,
                                       boolean read, Instant createdAt) {

        static NotificationResponse of(Notification n) {
            return new NotificationResponse(n.getId(), n.getType(), n.getTitle(), n.getBody(), n.getData(),
                    n.isRead(), n.getCreatedAt());
        }
    }

    @Transactional
    public void notify(Long userId, String type, String title, String body, Map<String, Object> data) {
        notify(userId, type, title, body, data, false);
    }

    /**
     * email = true cho việc có hạn hoặc có hậu quả tiền (docs/ra-soat-nghiep-vu/THIET_KE_GUI_MAIL.md mục 3):
     * xếp thêm một thư vào hàng đợi cùng giao dịch; giao dịch huỷ thì thư cũng không gửi.
     * Không xếp thư khi mail đang tắt hoặc email chưa xác thực.
     */
    @Transactional
    public void notify(Long userId, String type, String title, String body, Map<String, Object> data, boolean email) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setType(type);
        n.setTitle(title);
        n.setBody(body);
        n.setData(data);
        n = repository.save(n);
        if (email && mail.enabled()) {
            Long notificationId = n.getId();
            userRepository.findById(userId).filter(User::isEmailVerified).ifPresent(u -> {
                EmailOutbox e = new EmailOutbox();
                e.setNotificationId(notificationId);
                e.setUserId(u.getId());
                e.setToEmail(u.getEmail());
                e.setSubject("ReBook: " + title);
                e.setBody(body + "\n\nMở ứng dụng ReBook để xem chi tiết"
                        + (appUrl == null || appUrl.isBlank() ? "" : ": " + appUrl) + "\n\n"
                        + "Đây là thư tự động về giao dịch của bạn trên ReBook, vui lòng không trả lời thư này.");
                outbox.save(e);
            });
        }
        hub.publish(RealtimeHub.userChannel(userId), Map.of("type", "NOTIFICATION", "notification", NotificationResponse.of(n)));
    }

    public void notifyAll(Collection<Long> userIds, String type, String title, String body, Map<String, Object> data) {
        userIds.stream().distinct().forEach(id -> notify(id, type, title, body, data));
    }

    public PageResponse<NotificationResponse> list(Long userId, int page, int size) {
        return PageResponse.of(repository.findByUserIdOrderByIdDesc(userId, PageRequest.of(page, size)), NotificationResponse::of);
    }

    public long unreadCount(Long userId) {
        return repository.countByUserIdAndReadFalse(userId);
    }

    @Transactional
    public void markRead(Long userId, Long id) {
        Notification n = repository.findById(id).filter(x -> x.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("thông báo"));
        n.setRead(true);
    }

    @Transactional
    public int markAllRead(Long userId) {
        return repository.markAllRead(userId);
    }
}
