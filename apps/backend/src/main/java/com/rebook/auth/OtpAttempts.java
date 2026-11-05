package com.rebook.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Ghi số lần nhập sai OTP trong giao dịch riêng, để không bị hoàn lại cùng lỗi "Mã OTP không đúng". */
@Component
@RequiredArgsConstructor
class OtpAttempts {

    private final OtpCodeRepository repository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void increment(Long otpId) {
        repository.findById(otpId).ifPresent(o -> o.setAttempts(o.getAttempts() + 1));
    }
}
