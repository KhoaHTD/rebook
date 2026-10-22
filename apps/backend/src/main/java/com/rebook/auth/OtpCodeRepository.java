package com.rebook.auth;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface OtpCodeRepository extends JpaRepository<OtpCode, Long> {

    Optional<OtpCode> findFirstByUserIdAndPurposeAndUsedAtIsNullOrderByIdDesc(Long userId, OtpCode.Purpose purpose);
}
