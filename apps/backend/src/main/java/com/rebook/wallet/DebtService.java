package com.rebook.wallet;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.common.ApiException;
import com.rebook.common.Money;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Nợ phạt / nợ phí kho (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần B mục 3.2). Phần chưa thu đủ ghi thành nợ; thu dần từ số dư dùng được,
 * cũ nhất trước. Mỗi lần thu là các dòng sổ cái bình thường qua {@link WalletService}.
 */
@Service
@RequiredArgsConstructor
public class DebtService {

    private final AccountDebtRepository repository;
    private final WalletService walletService;
    private final AuditLog audit;

    public record DebtResponse(Long id, AccountDebt.Type type, BigDecimal amount, BigDecimal paidAmount,
                               BigDecimal remaining, AccountDebt.Status status, String note, Instant createdAt,
                               Instant settledAt) {

        static DebtResponse of(AccountDebt d) {
            return new DebtResponse(d.getId(), d.getType(), d.getAmount(), d.getPaidAmount(), d.remaining(), d.getStatus(),
                    d.getNote(), d.getCreatedAt(), d.getSettledAt());
        }
    }

    public record CollectResult(BigDecimal collected, BigDecimal stillOwed) {
    }

    /** Ghi nợ rồi thu ngay phần ví đang có. */
    @Transactional
    public AccountDebt create(Long userId, AccountDebt.Type type, BigDecimal amount, String refType, Long refId,
                              Long beneficiaryId, BigDecimal beneficiaryPercent, String note) {
        AccountDebt d = new AccountDebt();
        d.setUserId(userId);
        d.setType(type);
        d.setAmount(amount);
        d.setRefType(refType);
        d.setRefId(refId);
        d.setBeneficiaryId(beneficiaryId);
        d.setBeneficiaryPercent(beneficiaryPercent == null ? BigDecimal.ZERO : beneficiaryPercent);
        d.setNote(note);
        d = repository.saveAndFlush(d);
        audit.record(EventCode.DEBT_CREATED, "DEBT", d.getId(), null, note, "userId", userId, "type", type, "amount", amount,
                "refType", refType, "refId", refId);
        collect(userId);
        return d;
    }

    /** Thu nợ từ số dư dùng được, cũ nhất trước. Trả về số tiền đã thu lần này. */
    @Transactional
    public BigDecimal collect(Long userId) {
        // Khoá ví trước rồi mới đọc nợ: đọc trước thì lượt thu chạy song song thấy số đã trả cũ và trừ ví lần nữa
        walletService.lock(userId);
        List<AccountDebt> open = repository.findByUserIdAndStatusOrderByIdAsc(userId, AccountDebt.Status.OPEN);
        BigDecimal total = BigDecimal.ZERO;
        for (AccountDebt d : open) {
            BigDecimal pay = d.remaining().min(walletService.get(userId).getAvailableBalance());
            if (pay.signum() <= 0) {
                break;
            }
            boolean penalty = d.getType() == AccountDebt.Type.AUCTION_PENALTY;
            WalletTxType tx = penalty ? WalletTxType.AUCTION_PENALTY : WalletTxType.FEE;
            walletService.debit(userId, tx, pay, "DEBT", d.getId(), "Thu nợ: " + d.getNote());
            BigDecimal share = d.getBeneficiaryId() == null ? BigDecimal.ZERO : Money.percent(pay, d.getBeneficiaryPercent());
            if (share.signum() > 0) {
                walletService.credit(d.getBeneficiaryId(), WalletTxType.DEPOSIT_FORFEIT, share, "DEBT", d.getId(),
                        "Bồi thường từ khoản phạt người thắng bỏ thanh toán");
            }
            walletService.credit(null, tx, pay.subtract(share), "DEBT", d.getId(), "Thu nợ: " + d.getNote());
            d.setPaidAmount(d.getPaidAmount().add(pay));
            if (d.remaining().signum() <= 0) {
                d.setStatus(AccountDebt.Status.PAID);
                d.setSettledAt(Instant.now());
            }
            total = total.add(pay);
            audit.record(EventCode.DEBT_COLLECTED, "DEBT", d.getId(), null, "Thu nợ", "userId", userId, "collected", pay,
                    "remaining", d.remaining(), "status", d.getStatus());
        }
        return total;
    }

    public BigDecimal platformPenaltyCollectedForLot(Long lotId) {
        return repository.platformPenaltyCollectedForLot(lotId).setScale(0, java.math.RoundingMode.DOWN);
    }

    public boolean hasOpenDebt(Long userId) {
        return repository.existsByUserIdAndStatus(userId, AccountDebt.Status.OPEN);
    }

    @Transactional
    public CollectResult collectNow(Long userId) {
        BigDecimal collected = collect(userId);
        BigDecimal owed = repository.findByUserIdAndStatusOrderByIdAsc(userId, AccountDebt.Status.OPEN).stream()
                .map(AccountDebt::remaining).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new CollectResult(collected, owed);
    }

    @Transactional(readOnly = true)
    public List<DebtResponse> mine(Long userId) {
        return repository.findByUserIdOrderByIdDesc(userId).stream().map(DebtResponse::of).toList();
    }

    /** Admin miễn nợ. Không gỡ lệnh cấm đấu giá. */
    @Transactional
    public DebtResponse waive(Long adminId, Long debtId, String reason) {
        AccountDebt d = repository.findById(debtId).orElseThrow(() -> ApiException.notFound("khoản nợ"));
        if (d.getStatus() != AccountDebt.Status.OPEN) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Khoản nợ đã được xử lý");
        }
        d.setStatus(AccountDebt.Status.WAIVED);
        d.setWaivedBy(adminId);
        d.setSettledAt(Instant.now());
        audit.record(EventCode.DEBT_WAIVED, "DEBT", d.getId(), null, reason, "userId", d.getUserId(),
                "remaining", d.remaining(), "waivedBy", adminId);
        return DebtResponse.of(d);
    }
}
