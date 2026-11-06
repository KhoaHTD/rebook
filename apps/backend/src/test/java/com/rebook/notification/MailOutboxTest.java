package com.rebook.notification;

import com.rebook.auction.AuctionSettlement;
import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Gửi mail thật qua SMTP giả (docs/ra-soat-nghiep-vu/THIET_KE_GUI_MAIL.md): hàng đợi, thử lại, OTP, luật không phạt khi chưa báo được. */
@TestPropertySource(properties = {"app.mail.enabled=true", "spring.mail.host=smtp.test.local"})
class MailOutboxTest extends IntegrationTest {

    @MockitoBean
    JavaMailSender mailSender;
    @Autowired
    NotificationService notifications;
    @Autowired
    EmailOutboxJob job;
    @Autowired
    AuctionSettlement settlement;
    @Autowired
    TransactionTemplate tx;

    private String email(long user) {
        return jdbc.queryForObject("SELECT email FROM users WHERE id = ?", String.class, user);
    }

    private SimpleMailMessage to(String address) {
        return argThat(m -> m != null && m.getTo() != null && m.getTo()[0].equals(address));
    }

    private Long outboxId(long user) {
        return jdbc.queryForObject("SELECT max(id) FROM email_outbox WHERE user_id = ?", Long.class, user);
    }

    private String outboxStatus(long id) {
        return jdbc.queryForObject("SELECT status FROM email_outbox WHERE id = ?", String.class, id);
    }

    @Test
    void importantNotificationIsQueuedThenSentExactlyOnce() {
        long user = createUser(Role.USER, "Người nhận thư", 0);
        tx.executeWithoutResult(s -> notifications.notify(user, NotificationService.AUCTION, "Sắp hết hạn", "Nội dung", Map.of(), true));
        long id = outboxId(user);
        assertThat(outboxStatus(id)).isEqualTo("PENDING");

        job.run();
        job.run();

        verify(mailSender, times(1)).send(to(email(user)));
        assertThat(outboxStatus(id)).isEqualTo("SENT");
    }

    @Test
    void ordinaryNotificationAndUnverifiedEmailGetNoMail() {
        long user = createUser(Role.USER, "Không cần thư", 0);
        long unverified = createUser(Role.USER, "Chưa xác thực", 0);
        jdbc.update("UPDATE users SET email_verified = FALSE WHERE id = ?", unverified);
        tx.executeWithoutResult(s -> {
            notifications.notify(user, NotificationService.ORDER, "Cập nhật", "Đơn đang giao", Map.of());
            notifications.notify(unverified, NotificationService.AUCTION, "Quan trọng", "Nội dung", Map.of(), true);
        });
        assertThat(outboxId(user)).isNull();
        assertThat(outboxId(unverified)).isNull();
    }

    @Test
    void rolledBackTransactionLeavesNoMail() {
        long user = createUser(Role.USER, "Giao dịch huỷ", 0);
        tx.executeWithoutResult(s -> {
            notifications.notify(user, NotificationService.AUCTION, "Quan trọng", "Nội dung", Map.of(), true);
            s.setRollbackOnly();
        });
        assertThat(outboxId(user)).isNull();
    }

    @Test
    void smtpFailureIsRetriedThenMarkedFailed() {
        long user = createUser(Role.USER, "SMTP hỏng", 0);
        doThrow(new MailSendException("SMTP down")).when(mailSender).send(to(email(user)));
        tx.executeWithoutResult(s -> notifications.notify(user, NotificationService.AUCTION, "Quan trọng", "Nội dung", Map.of(), true));
        long id = outboxId(user);

        tx.executeWithoutResult(s -> job.deliver(id));
        assertThat(outboxStatus(id)).isEqualTo("PENDING");
        assertThat(jdbc.queryForObject("SELECT next_attempt_at > now() FROM email_outbox WHERE id = ?", Boolean.class, id)).isTrue();

        for (int i = 0; i < EmailOutboxJob.RETRY_AFTER.size(); i++) {
            tx.executeWithoutResult(s -> job.deliver(id));
        }
        assertThat(outboxStatus(id)).isEqualTo("FAILED");
        assertThat(jdbc.queryForObject("SELECT attempts FROM email_outbox WHERE id = ?", Integer.class, id)).isEqualTo(5);
    }

    @Test
    void otpCodeArrivesByMail() throws Exception {
        long user = createUser(Role.USER, "Nhận OTP", 0);
        mvc.perform(post("/auth/send-otp").with(as(user, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"purpose\":\"VERIFY_EMAIL\"}")).andExpect(status().isOk());
        String code = jdbc.queryForObject("SELECT code FROM otp_codes WHERE user_id = ?", String.class, user);
        verify(mailSender).send(org.mockito.ArgumentMatchers.<SimpleMailMessage>argThat(m -> m != null && m.getTo() != null
                && m.getTo()[0].equals(email(user)) && m.getText().contains(code) && !m.getSubject().contains(code)));
    }

    @Test
    void otpMailFailureIsReportedAndNoCodeIsKept() throws Exception {
        long user = createUser(Role.USER, "OTP lỗi", 0);
        doThrow(new MailSendException("SMTP down")).when(mailSender).send(to(email(user)));
        mvc.perform(post("/auth/send-otp").with(as(user, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"purpose\":\"VERIFY_EMAIL\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("EMAIL_SEND_FAILED"));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM otp_codes WHERE user_id = ?", Long.class, user)).isZero();
    }

    // ---- P0 mục 2: chưa báo được người thắng thì chưa phạt ----

    private record Invoice(long order, long winner, long registration) {
    }

    /** Lô đã bán trong phiên đã kết thúc, hoá đơn quá hạn, thông báo thắng chưa đọc, thư báo thắng ở trạng thái mailStatus. */
    private Invoice overdueWin(String mailStatus) {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long winner = createUser(Role.USER, "Người thắng", 0);
        jdbc.update("UPDATE wallets SET held_balance = 50000 WHERE user_id = ?", winner);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "mo-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade, weight_gram)
                VALUES (?, 'Sách thư', 'Tác giả', ?, 'GOOD', 300) RETURNING id""", Long.class, seller, category);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, "KG-" + UUID.randomUUID().toString().substring(0, 18), seller, book);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên thư', now() - interval '1 day', now() - interval '2 day', 50000, 'ENDED') RETURNING id""", Long.class);
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                                  current_price, opened_at, closed_at, status, close_result, hammer_price, winner_id, rounds)
                VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, 120000, now() - interval '1 day', now() - interval '1 day',
                        'SOLD', 'SOLD', 120000, ?, 1) RETURNING id""", Long.class, session, consignment, book, winner);
        long registration = jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, 1, 50000, 10000000, 'APPROVED') RETURNING id""", Long.class, session, winner);
        long order = jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, lot_id, order_type, status, subtotal, total, payment_due_at, pickup_at_warehouse)
                VALUES (?, ?, ?, 'AUCTION', 'PENDING_PAYMENT', 120000, 120000, now() - interval '1 hour', TRUE) RETURNING id""",
                Long.class, "OD-" + UUID.randomUUID().toString().substring(0, 18), winner, lot);
        long notification = jdbc.queryForObject("""
                INSERT INTO notifications (user_id, type, title, body, data)
                VALUES (?, 'AUCTION_WON', 'Bạn đã thắng đấu giá!', 'Hãy thanh toán', jsonb_build_object('orderId', CAST(? AS bigint))) RETURNING id""",
                Long.class, winner, order);
        jdbc.update("""
                INSERT INTO email_outbox (notification_id, user_id, to_email, subject, body, status, attempts)
                VALUES (?, ?, 'x@test.local', 'ReBook: thắng', 'b', ?, 5)""", notification, winner, mailStatus);
        return new Invoice(order, winner, registration);
    }

    private String orderStatus(long order) {
        return jdbc.queryForObject("SELECT status FROM orders WHERE id = ?", String.class, order);
    }

    @Test
    void winnerWhoWasNeverReachedGetsOneExtensionInsteadOfAPenalty() {
        Invoice inv = overdueWin("FAILED");

        settlement.handleOverdue(inv.order());

        assertThat(orderStatus(inv.order())).isEqualTo("PENDING_PAYMENT");
        assertThat(jdbc.queryForObject("SELECT notice_extended AND payment_due_at > now() + interval '23 hours' FROM orders WHERE id = ?",
                Boolean.class, inv.order())).isTrue();
        assertThat(jdbc.queryForObject("SELECT status FROM auction_registrations WHERE id = ?", String.class, inv.registration()))
                .isEqualTo("APPROVED");
        assertThat(jdbc.queryForObject("SELECT auction_banned_until IS NULL FROM users WHERE id = ?", Boolean.class, inv.winner())).isTrue();

        // Hết hạn lần hai: phạt như thường, không gia hạn nữa
        jdbc.update("UPDATE orders SET payment_due_at = now() - interval '1 minute' WHERE id = ?", inv.order());
        settlement.handleOverdue(inv.order());
        assertThat(orderStatus(inv.order())).isEqualTo("CANCELLED");
        assertThat(jdbc.queryForObject("SELECT status FROM auction_registrations WHERE id = ?", String.class, inv.registration()))
                .isEqualTo("FORFEITED");
    }

    @Test
    void winnerWhoGotTheMailOrReadTheNotificationIsPenalizedOnTime() {
        Invoice mailed = overdueWin("SENT");
        settlement.handleOverdue(mailed.order());
        assertThat(orderStatus(mailed.order())).isEqualTo("CANCELLED");

        Invoice read = overdueWin("FAILED");
        jdbc.update("UPDATE notifications SET is_read = TRUE WHERE user_id = ?", read.winner());
        settlement.handleOverdue(read.order());
        assertThat(orderStatus(read.order())).isEqualTo("CANCELLED");
        verify(mailSender, never()).send(to("x@test.local"));
    }
}
