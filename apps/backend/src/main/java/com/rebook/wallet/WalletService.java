package com.rebook.wallet;

import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.wallet.WalletDtos.TransactionResponse;
import com.rebook.wallet.WalletDtos.WalletResponse;
import com.rebook.wallet.WalletDtos.WithdrawCreateRequest;
import com.rebook.wallet.WalletDtos.WithdrawResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Mọi thay đổi số dư đi qua {@link #move}: khoá dòng ví (FOR UPDATE), kiểm số dư không âm,
 * ghi một dòng sổ cái. Không sửa / xoá giao dịch cũ.
 */
@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final WalletTransactionRepository transactionRepository;
    private final WithdrawRequestRepository withdrawRepository;

    @Transactional
    public Wallet createFor(Long userId) {
        Wallet wallet = new Wallet();
        wallet.setUserId(userId);
        return walletRepository.save(wallet);
    }

    /**
     * Đổi số dư ví.
     *
     * @param userId          null = ví sàn
     * @param availableChange dương = cộng, âm = trừ
     * @param heldChange      dương = khoá thêm, âm = giảm phần đang khoá
     */
    @Transactional
    public WalletTransaction move(Long userId, WalletTxType type, BigDecimal availableChange, BigDecimal heldChange,
                                  String refType, Long refId, String note) {
        Wallet wallet = (userId == null ? walletRepository.lockPlatform() : walletRepository.lockByUserId(userId))
                .orElseThrow(() -> ApiException.notFound("ví"));
        BigDecimal newAvailable = wallet.getAvailableBalance().add(availableChange);
        BigDecimal newHeld = wallet.getHeldBalance().add(heldChange);
        if (newAvailable.signum() < 0) {
            throw ApiException.badRequest("INSUFFICIENT_BALANCE", "Số dư ví không đủ, vui lòng nạp thêm");
        }
        if (newHeld.signum() < 0) {
            throw new IllegalStateException("Held balance âm ở ví " + wallet.getId());
        }
        wallet.setAvailableBalance(newAvailable);
        wallet.setHeldBalance(newHeld);

        WalletTransaction tx = new WalletTransaction();
        tx.setWalletId(wallet.getId());
        tx.setType(type);
        tx.setAvailableChange(availableChange);
        tx.setHeldChange(heldChange);
        tx.setAvailableAfter(newAvailable);
        tx.setHeldAfter(newHeld);
        tx.setRefType(refType);
        tx.setRefId(refId);
        tx.setNote(note);
        return transactionRepository.save(tx);
    }

    // ---- Các thao tác hay dùng ----

    /** Cộng vào số dư dùng được. */
    public void credit(Long userId, WalletTxType type, BigDecimal amount, String refType, Long refId, String note) {
        if (amount.signum() > 0) {
            move(userId, type, amount, BigDecimal.ZERO, refType, refId, note);
        }
    }

    /** Trừ số dư dùng được (báo lỗi nếu không đủ). */
    public void debit(Long userId, WalletTxType type, BigDecimal amount, String refType, Long refId, String note) {
        if (amount.signum() > 0) {
            move(userId, type, amount.negate(), BigDecimal.ZERO, refType, refId, note);
        }
    }

    /** available → held (vd khoá tiền cọc). */
    public void hold(Long userId, WalletTxType type, BigDecimal amount, String refType, Long refId, String note) {
        if (amount.signum() > 0) {
            move(userId, type, amount.negate(), amount, refType, refId, note);
        }
    }

    /** held → available (vd hoàn cọc, giải ngân tiền bán hàng). */
    public void release(Long userId, WalletTxType type, BigDecimal amount, String refType, Long refId, String note) {
        if (amount.signum() > 0) {
            move(userId, type, amount, amount.negate(), refType, refId, note);
        }
    }

    /** Cộng thẳng vào held (vd tiền bán hàng chờ đơn hoàn tất). */
    public void addHeld(Long userId, WalletTxType type, BigDecimal amount, String refType, Long refId, String note) {
        if (amount.signum() > 0) {
            move(userId, type, BigDecimal.ZERO, amount, refType, refId, note);
        }
    }

    /** Trừ khỏi held (vd cọc bị thu, đơn bị huỷ sau khi đã ghi tiền chờ). */
    public void removeHeld(Long userId, WalletTxType type, BigDecimal amount, String refType, Long refId, String note) {
        if (amount.signum() > 0) {
            move(userId, type, BigDecimal.ZERO, amount.negate(), refType, refId, note);
        }
    }

    // ---- Truy vấn ----

    public Wallet get(Long userId) {
        return walletRepository.findByUserId(userId).orElseThrow(() -> ApiException.notFound("ví"));
    }

    public WalletResponse summary(Long userId) {
        return WalletResponse.of(get(userId));
    }

    public WalletResponse platformSummary() {
        return WalletResponse.of(walletRepository.findPlatform().orElseThrow(() -> ApiException.notFound("ví sàn")));
    }

    public PageResponse<TransactionResponse> transactions(Long userId, int page, int size) {
        Wallet wallet = get(userId);
        return PageResponse.of(transactionRepository.findByWalletIdOrderByIdDesc(wallet.getId(), PageRequest.of(page, size)),
                TransactionResponse::of);
    }

    // ---- Rút tiền (giả lập: Admin duyệt và đánh dấu đã chuyển) ----

    @Transactional
    public WithdrawResponse requestWithdraw(Long userId, WithdrawCreateRequest req) {
        WithdrawRequest w = new WithdrawRequest();
        w.setUserId(userId);
        w.setAmount(req.amount());
        w.setBankName(req.bankName());
        w.setAccountNumber(req.accountNumber());
        w.setAccountHolder(req.accountHolder());
        w = withdrawRepository.save(w);
        // Khoá tiền trong lúc chờ duyệt
        hold(userId, WalletTxType.WITHDRAW, req.amount(), "WITHDRAW", w.getId(), "Yêu cầu rút tiền");
        return WithdrawResponse.of(w);
    }

    public List<WithdrawResponse> myWithdrawals(Long userId) {
        return withdrawRepository.findByUserIdOrderByIdDesc(userId).stream().map(WithdrawResponse::of).toList();
    }

    public PageResponse<WithdrawResponse> pendingWithdrawals(int page, int size) {
        return PageResponse.of(withdrawRepository.findByStatusOrderByIdAsc(WithdrawRequest.Status.PENDING,
                PageRequest.of(page, size)), WithdrawResponse::of);
    }

    @Transactional
    public WithdrawResponse processWithdraw(Long adminId, Long withdrawId, boolean approve, String note) {
        WithdrawRequest w = withdrawRepository.findById(withdrawId).orElseThrow(() -> ApiException.notFound("yêu cầu rút tiền"));
        if (w.getStatus() != WithdrawRequest.Status.PENDING) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Yêu cầu đã được xử lý");
        }
        if (approve) {
            removeHeld(w.getUserId(), WalletTxType.WITHDRAW, w.getAmount(), "WITHDRAW", w.getId(), "Đã chuyển khoản");
            w.setStatus(WithdrawRequest.Status.APPROVED);
        } else {
            release(w.getUserId(), WalletTxType.REFUND, w.getAmount(), "WITHDRAW", w.getId(), "Từ chối rút tiền");
            w.setStatus(WithdrawRequest.Status.REJECTED);
        }
        w.setNote(note);
        w.setProcessedBy(adminId);
        w.setProcessedAt(Instant.now());
        return WithdrawResponse.of(w);
    }
}
