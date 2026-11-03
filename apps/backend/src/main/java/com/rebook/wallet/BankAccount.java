package com.rebook.wallet;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/** Tài khoản ngân hàng người dùng đã dùng để rút tiền; tự lưu / cập nhật mỗi lần tạo yêu cầu rút. */
@Entity
@Table(name = "bank_accounts")
@Getter
@Setter
@NoArgsConstructor
public class BankAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private String bankName;
    private String accountNumber;
    private String accountHolder;
    private boolean favorite;
    private Instant lastUsedAt;
}
