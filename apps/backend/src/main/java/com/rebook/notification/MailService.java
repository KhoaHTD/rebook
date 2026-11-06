package com.rebook.notification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Gửi mail văn bản thuần qua SMTP (docs/ra-soat-nghiep-vu/THIET_KE_GUI_MAIL.md).
 * Tắt (app.mail.enabled=false) thì chỉ ghi log người nhận và tiêu đề, không ghi nội dung (có thể chứa OTP).
 */
@Slf4j
@Service
public class MailService {

    private final ObjectProvider<JavaMailSender> sender;
    private final boolean enabled;
    private final String from;

    public MailService(ObjectProvider<JavaMailSender> sender,
                       @Value("${app.mail.enabled:false}") boolean enabled,
                       @Value("${app.mail.from:ReBook <no-reply@rebook.vn>}") String from,
                       @Value("${spring.mail.host:}") String host) {
        if (enabled && host.isBlank()) {
            throw new IllegalStateException("app.mail.enabled=true nhưng chưa đặt MAIL_HOST");
        }
        this.sender = sender;
        this.enabled = enabled;
        this.from = from;
    }

    public boolean enabled() {
        return enabled;
    }

    /** Ném {@link MailException} khi SMTP từ chối hoặc không kết nối được. */
    public void send(String to, String subject, String body) {
        if (!enabled) {
            log.info("[MAIL] (đang tắt) tới {}: {}", mask(to), subject);
            return;
        }
        SimpleMailMessage m = new SimpleMailMessage();
        m.setFrom(from);
        m.setTo(to);
        m.setSubject(subject);
        m.setText(body);
        sender.getObject().send(m);
    }

    /** a***@gmail.com: đủ để dò log mà không lộ địa chỉ. */
    public static String mask(String email) {
        int at = email == null ? -1 : email.indexOf('@');
        return at <= 0 ? "***" : email.charAt(0) + "***" + email.substring(at);
    }
}
