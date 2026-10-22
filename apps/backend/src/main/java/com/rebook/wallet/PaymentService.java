package com.rebook.wallet;

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
    private final VnpayGateway vnpay;
    private final WalletService walletService;
    private final ApplicationEventPublisher events;
    private final AppProperties props;

    public record PaymentResponse(Long id, String code, Payment.Purpose purpose, Payment.Method method,
                                  BigDecimal amount, Payment.Status status, String paymentUrl,
                                  boolean simulateAvailable, Instant expiresAt, Instant paidAt) {

        static PaymentResponse of(Payment p, String url, boolean simulate) {
            return new PaymentResponse(p.getId(), p.getCode(), p.getPurpose(), p.getMethod(), p.getAmount(),
                    p.getStatus(), url, simulate && p.getStatus() == Payment.Status.PENDING, p.getExpiresAt(), p.getPaidAt());
        }
    }

    /** Tạo payment qua VNPay. Khi chưa cấu hình VNPay, paymentUrl = null và dùng /payments/{code}/simulate để giả lập. */
    @Transactional
    public PaymentResponse createVnpay(Long userId, Payment.Purpose purpose, BigDecimal amount, Duration ttl,
                                       String orderInfo, String clientIp) {
        Payment p = new Payment();
        p.setCode(CodeGenerator.next("PM"));
        p.setUserId(userId);
        p.setPurpose(purpose);
        p.setMethod(Payment.Method.VNPAY);
        p.setAmount(amount);
        p.setExpiresAt(Instant.now().plus(ttl));
        p = paymentRepository.save(p);
        String url = vnpay.isConfigured()
                ? vnpay.buildPaymentUrl(p.getCode(), amount, orderInfo, clientIp, p.getExpiresAt())
                : null;
        return PaymentResponse.of(p, url, props.payment().simulateEnabled());
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

    public PaymentResponse get(Long userId, String code) {
        Payment p = paymentRepository.findByCode(code).orElseThrow(() -> ApiException.notFound("thanh toán"));
        if (!p.getUserId().equals(userId)) {
            throw ApiException.forbidden("Không phải thanh toán của bạn");
        }
        return PaymentResponse.of(p, null, props.payment().simulateEnabled());
    }

    /**
     * Xử lý IPN của VNPay. Trả về mã phản hồi theo quy ước VNPay:
     * 00 thành công, 01 không tìm thấy, 02 đã xử lý, 04 sai số tiền, 97 sai chữ ký.
     */
    @Transactional
    public Map<String, String> handleVnpayCallback(Map<String, String> params) {
        if (!vnpay.verify(params)) {
            return rsp("97", "Invalid signature");
        }
        Payment p = paymentRepository.lockByCode(params.get("vnp_TxnRef")).orElse(null);
        if (p == null) {
            return rsp("01", "Order not found");
        }
        BigDecimal paid = new BigDecimal(params.getOrDefault("vnp_Amount", "0")).divide(BigDecimal.valueOf(100));
        if (paid.compareTo(p.getAmount()) != 0) {
            return rsp("04", "Invalid amount");
        }
        if (p.getStatus() == Payment.Status.SUCCESS) {
            return rsp("02", "Order already confirmed");
        }
        p.setRawCallback(params.toString());
        boolean ok = "00".equals(params.get("vnp_ResponseCode")) && "00".equals(params.get("vnp_TransactionStatus"));
        if (ok) {
            markSuccess(p, params.get("vnp_TransactionNo"));
        } else if (p.getStatus() == Payment.Status.PENDING) {
            p.setStatus(Payment.Status.FAILED);
        }
        return rsp("00", "Confirm Success");
    }

    /** Chỉ bật ở môi trường dev: giả lập cổng thanh toán trả về thành công. */
    @Transactional
    public PaymentResponse simulateSuccess(Long userId, String code) {
        if (!props.payment().simulateEnabled()) {
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

    private void markSuccess(Payment p, String gatewayTxnId) {
        p.setStatus(Payment.Status.SUCCESS);
        p.setGatewayTxnId(gatewayTxnId);
        p.setPaidAt(Instant.now());
        paymentRepository.saveAndFlush(p); // flush sớm để UNIQUE(gateway_txn_id) chặn cộng trùng
        log.info("Payment {} thành công ({} đ)", p.getCode(), p.getAmount());
        if (p.getPurpose() == Payment.Purpose.TOP_UP) {
            walletService.credit(p.getUserId(), WalletTxType.TOP_UP, p.getAmount(), "PAYMENT", p.getId(), "Nạp tiền qua VNPay");
        }
        events.publishEvent(new PaymentSucceededEvent(p));
    }

    /** Payment VNPay quá hạn mà chưa trả → EXPIRED (đơn liên quan do job đơn hàng huỷ). */
    @Transactional
    public int expireStalePayments() {
        var expired = paymentRepository.findExpired(Instant.now());
        expired.forEach(p -> p.setStatus(Payment.Status.EXPIRED));
        return expired.size();
    }

    private static Map<String, String> rsp(String code, String message) {
        return Map.of("RspCode", code, "Message", message);
    }
}
