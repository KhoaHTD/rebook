package com.rebook.wallet;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.config.AppProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final ZaloPayGateway zalopay;
    private final WalletService walletService;
    private final ApplicationEventPublisher events;
    private final AppProperties props;
    private final ObjectMapper json;

    public record PaymentResponse(Long id, String code, Payment.Purpose purpose, Payment.Method method,
                                  BigDecimal amount, Payment.Status status, String paymentUrl,
                                  boolean simulateAvailable, Instant expiresAt, Instant paidAt) {

        static PaymentResponse of(Payment p, String url, boolean simulate) {
            return new PaymentResponse(p.getId(), p.getCode(), p.getPurpose(), p.getMethod(), p.getAmount(),
                    p.getStatus(), url, simulate && p.getStatus() == Payment.Status.PENDING, p.getExpiresAt(), p.getPaidAt());
        }
    }

    /** Kết quả khi trình duyệt quay về từ ZaloPay. code = null nếu không nhận ra giao dịch (sai checksum...). */
    public record ReturnResult(String code, Payment.Status status) {
    }

    /**
     * Tạo payment qua ZaloPay: app mở {@code paymentUrl}. Chưa cấu hình ZaloPay thì paymentUrl = null và
     * dùng /payments/{code}/simulate (chỉ bật ở dev) để giả lập.
     */
    @Transactional
    public PaymentResponse createZaloPay(Long userId, Payment.Purpose purpose, BigDecimal amount, Duration ttl,
                                         String description) {
        Payment p = new Payment();
        p.setCode(CodeGenerator.next("PM"));
        p.setUserId(userId);
        p.setPurpose(purpose);
        p.setMethod(Payment.Method.ZALOPAY);
        p.setAmount(amount);
        p.setExpiresAt(Instant.now().plus(ttl));
        p.setGatewayRef(ZaloPayGateway.appTransId(Instant.now(), p.getCode()));
        p = paymentRepository.save(p);
        String url = zalopay.isConfigured()
                ? zalopay.createOrder(p.getGatewayRef(), userId, amount, description, ttl)
                : null;
        p.setPaymentUrl(url);
        return PaymentResponse.of(p, url, simulateAvailable());
    }

    /** Payment nội bộ (ví / COD) — ghi lại để đối soát, ví thì thành công ngay. */
    @Transactional
    public Payment createInternal(Long userId, Payment.Method method, BigDecimal amount) {
        Payment p = new Payment();
        p.setCode(CodeGenerator.next("PM"));
        p.setUserId(userId);
        p.setPurpose(Payment.Purpose.ORDER);
        p.setMethod(method);
        p.setAmount(amount);
        if (method == Payment.Method.WALLET) {
            p.setStatus(Payment.Status.SUCCESS);
            p.setPaidAt(Instant.now());
        }
        return paymentRepository.save(p);
    }

    /** Trạng thái một thanh toán. Đang chờ ZaloPay thì hỏi lại ZaloPay trước (app hỏi định kỳ khi chờ kết quả). */
    @Transactional
    public PaymentResponse get(Long userId, String code) {
        Payment p = paymentRepository.lockByCode(code).orElseThrow(() -> ApiException.notFound("thanh toán"));
        if (!p.getUserId().equals(userId)) {
            throw ApiException.forbidden("Không phải thanh toán của bạn");
        }
        syncQuietly(p);
        // Còn chờ thì trả lại link ZaloPay để app mở lại trang thanh toán.
        String url = p.getStatus() == Payment.Status.PENDING ? p.getPaymentUrl() : null;
        return PaymentResponse.of(p, url, simulateAvailable());
    }

    /** Trình duyệt quay về từ ZaloPay: kiểm checksum, rồi hỏi ZaloPay để chốt (không tin tham số `status` trên URL). */
    @Transactional
    public ReturnResult handleZaloPayReturn(Map<String, String> params) {
        if (!zalopay.verifyRedirect(params)) {
            return new ReturnResult(null, Payment.Status.FAILED);
        }
        Payment p = paymentRepository.lockByGatewayRef(params.get("apptransid")).orElse(null);
        if (p == null) {
            return new ReturnResult(null, Payment.Status.FAILED);
        }
        syncQuietly(p);
        return new ReturnResult(p.getCode(), p.getStatus());
    }

    /**
     * Callback server-to-server của ZaloPay (chỉ tới được khi backend có địa chỉ công khai).
     * Trả return_code: 1 đã xử lý, 2 trùng (đã xử lý trước đó), -1 sai chữ ký / không tìm thấy.
     */
    @Transactional
    public Map<String, Object> handleZaloPayCallback(String data, String mac) {
        if (!zalopay.verifyCallback(data, mac)) {
            return Map.of("return_code", -1, "return_message", "mac not equal");
        }
        try {
            JsonNode d = json.readTree(data);
            Payment p = paymentRepository.lockByGatewayRef(d.path("app_trans_id").asText()).orElse(null);
            if (p == null) {
                return Map.of("return_code", -1, "return_message", "order not found");
            }
            if (p.getStatus() == Payment.Status.SUCCESS) {
                return Map.of("return_code", 2, "return_message", "already confirmed");
            }
            if (new BigDecimal(d.path("amount").asText("0")).compareTo(p.getAmount()) != 0) {
                return Map.of("return_code", -1, "return_message", "invalid amount");
            }
            p.setRawCallback(data);
            markSuccess(p, d.path("zp_trans_id").asText());
            return Map.of("return_code", 1, "return_message", "success");
        } catch (Exception e) {
            log.warn("Callback ZaloPay lỗi: {}", e.getMessage());
            return Map.of("return_code", 0, "return_message", "error");
        }
    }

    /** Có ZaloPay thật thì app đi qua ZaloPay: không hiện nút giả lập và endpoint giả lập cũng bị chặn (không tự nạp tiền ảo). */
    private boolean simulateAvailable() {
        return props.payment().simulateEnabled() && !zalopay.isConfigured();
    }

    /** Chỉ bật ở môi trường dev: giả lập cổng thanh toán trả về thành công. */
    @Transactional
    public PaymentResponse simulateSuccess(Long userId, String code) {
        if (!simulateAvailable()) {
            throw ApiException.forbidden("Giả lập thanh toán đang tắt");
        }
        Payment p = paymentRepository.lockByCode(code).orElseThrow(() -> ApiException.notFound("thanh toán"));
        if (!p.getUserId().equals(userId)) {
            throw ApiException.forbidden("Không phải thanh toán của bạn");
        }
        if (p.getStatus() == Payment.Status.SUCCESS) {
            throw ApiException.conflict("ALREADY_PAID", "Thanh toán đã hoàn tất");
        }
        markSuccess(p, "SIM-" + p.getCode());
        return PaymentResponse.of(p, null, false);
    }

    /** Hỏi lại cổng cho một thanh toán đang chờ, trả trạng thái sau khi hỏi. Thành công thì đơn liên quan được ghi nhận qua sự kiện. */
    @Transactional
    public Payment.Status refresh(Long paymentId) {
        Payment p = paymentRepository.lockById(paymentId).orElse(null);
        if (p == null) {
            return null;
        }
        syncQuietly(p);
        return p.getStatus();
    }

    /** Hỏi ZaloPay rồi cập nhật thanh toán đang chờ; ZaloPay không trả lời thì giữ nguyên để lần sau hỏi tiếp. */
    private void syncQuietly(Payment p) {
        if (p.getStatus() != Payment.Status.PENDING || p.getMethod() != Payment.Method.ZALOPAY
                || p.getGatewayRef() == null || !zalopay.isConfigured()) {
            return;
        }
        try {
            ZaloPayGateway.QueryResult r = zalopay.query(p.getGatewayRef());
            if (r.paid()) {
                if (r.amount() != null && r.amount().compareTo(p.getAmount()) != 0) {
                    log.warn("ZaloPay báo số tiền {} khác thanh toán {} ({})", r.amount(), p.getCode(), p.getAmount());
                    return;
                }
                markSuccess(p, r.zpTransId() == null ? "ZP-" + p.getGatewayRef() : r.zpTransId());
            } else if (r.failed()) {
                p.setStatus(Payment.Status.FAILED);
            }
        } catch (ApiException e) {
            log.warn("Không hỏi được ZaloPay cho {}: {}", p.getCode(), e.getMessage());
        }
    }

    private void markSuccess(Payment p, String gatewayTxnId) {
        p.setStatus(Payment.Status.SUCCESS);
        p.setGatewayTxnId(gatewayTxnId);
        p.setPaidAt(Instant.now());
        paymentRepository.saveAndFlush(p); // flush sớm để UNIQUE(gateway_txn_id) chặn cộng trùng
        log.info("Payment {} thành công ({} đ)", p.getCode(), p.getAmount());
        if (p.getPurpose() == Payment.Purpose.TOP_UP) {
            walletService.credit(p.getUserId(), WalletTxType.TOP_UP, p.getAmount(), "PAYMENT", p.getId(), "Nạp tiền qua ZaloPay");
        }
        events.publishEvent(new PaymentSucceededEvent(p));
    }

    /** Payment ZaloPay quá hạn mà chưa trả → EXPIRED (đơn liên quan do job đơn hàng huỷ). */
    @Transactional
    public int expireStalePayments() {
        var expired = paymentRepository.findExpired(Instant.now());
        expired.forEach(p -> p.setStatus(Payment.Status.EXPIRED));
        return expired.size();
    }
}
