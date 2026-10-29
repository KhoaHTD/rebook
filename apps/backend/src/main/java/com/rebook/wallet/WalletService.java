package com.rebook.wallet;

import com.rebook.audit.ActivityLogService;
import com.rebook.common.ApiException;
import com.rebook.common.PageResponse;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import com.rebook.wallet.WalletDtos.ProcessRequest;
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
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

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
    private final WithdrawTransferRepository transferRepository;
    private final UserRepository userRepository;
    private final ActivityLogService activityLog;

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

    // ---- Rút tiền (tiền khoá lúc yêu cầu; Admin chuyển khoản tay rồi lưu biên lai khi duyệt) ----

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
        return toResponse(List.of(w)).get(0);
    }

    @Transactional(readOnly = true)
    public List<WithdrawResponse> myWithdrawals(Long userId) {
        return toResponse(withdrawRepository.findByUserIdOrderByIdDesc(userId));
    }

    /** Admin xem yêu cầu theo trạng thái: mặc định chờ duyệt, truyền status khác để xem lịch sử duyệt. */
    @Transactional(readOnly = true)
    public PageResponse<WithdrawResponse> withdrawals(WithdrawRequest.Status status, int page, int size) {
        var result = withdrawRepository.findByStatusOrderByIdDesc(status == null ? WithdrawRequest.Status.PENDING : status,
                PageRequest.of(page, size));
        return new PageResponse<>(toResponse(result.getContent()), result.getNumber(), result.getSize(),
                result.getTotalElements(), result.getTotalPages());
    }

    @Transactional
    public WithdrawResponse processWithdraw(Long adminId, Long withdrawId, ProcessRequest req) {
        WithdrawRequest w = withdrawRepository.findByIdForUpdate(withdrawId)
                .orElseThrow(() -> ApiException.notFound("yêu cầu rút tiền"));
        if (w.getStatus() != WithdrawRequest.Status.PENDING) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION", "Yêu cầu đã được xử lý");
        }
        String adminName = userRepository.findById(adminId).map(User::getFullName).orElse("#" + adminId);
        if (req.approve()) {
            WithdrawTransfer transfer = recordTransfer(adminId, w, req);
            // Bản ghi 1: bút toán trừ tiền đã khoá của người rút (sổ cái ví). Bản ghi 2: biên lai ở withdraw_transfers.
            removeHeld(w.getUserId(), WalletTxType.WITHDRAW, w.getAmount(), "WITHDRAW", w.getId(),
                    "Đã chuyển khoản bởi " + transfer.getSenderName());
            w.setStatus(WithdrawRequest.Status.APPROVED);
            activityLog.record(adminId, "APPROVE_WITHDRAWAL", ActivityLogService.WITHDRAWAL, w.getId(),
                    adminName + " duyệt rút " + w.getAmount().toPlainString() + "đ của user #" + w.getUserId());
        } else {
            release(w.getUserId(), WalletTxType.REFUND, w.getAmount(), "WITHDRAW", w.getId(), "Từ chối rút tiền");
            w.setStatus(WithdrawRequest.Status.REJECTED);
            activityLog.record(adminId, "REJECT_WITHDRAWAL", ActivityLogService.WITHDRAWAL, w.getId(),
                    adminName + " từ chối rút " + w.getAmount().toPlainString() + "đ của user #" + w.getUserId()
                            + (req.note() == null || req.note().isBlank() ? "" : ": " + req.note()));
        }
        w.setNote(req.note());
        w.setProcessedBy(adminId);
        w.setProcessedAt(Instant.now());
        return toResponse(List.of(w)).get(0);
    }

    private WithdrawTransfer recordTransfer(Long adminId, WithdrawRequest w, ProcessRequest req) {
        if (req.senderName() == null || req.senderName().isBlank()) {
            throw ApiException.badRequest("TRANSFER_INFO_REQUIRED", "Cần nhập người chuyển khoản");
        }
        if (req.transferTime() == null) {
            throw ApiException.badRequest("TRANSFER_INFO_REQUIRED", "Cần nhập giờ chuyển khoản");
        }
        if (req.transferTime().isAfter(Instant.now().plusSeconds(300))) {
            throw ApiException.badRequest("INVALID_TRANSFER_TIME", "Giờ chuyển khoản không được ở tương lai");
        }
        if (req.transferAmount() == null || req.transferAmount().compareTo(w.getAmount()) != 0) {
            throw ApiException.badRequest("TRANSFER_AMOUNT_MISMATCH",
                    "Số tiền chuyển phải bằng số tiền yêu cầu rút (" + w.getAmount().toPlainString() + "đ)");
        }
        if (req.proofImageUrl() == null || req.proofImageUrl().isBlank()) {
            throw ApiException.badRequest("TRANSFER_INFO_REQUIRED", "Cần tải lên ảnh biên lai chuyển khoản");
        }
        WithdrawTransfer t = new WithdrawTransfer();
        t.setWithdrawId(w.getId());
        t.setAdminId(adminId);
        t.setSenderName(req.senderName().trim());
        t.setTransferTime(req.transferTime());
        t.setAmount(req.transferAmount());
        t.setProofImageUrl(req.proofImageUrl().trim());
        return transferRepository.save(t);
    }

    /** Gắn tên người rút, tên Admin duyệt và biên lai (nếu có) vào danh sách yêu cầu. */
    private List<WithdrawResponse> toResponse(List<WithdrawRequest> list) {
        Map<Long, WithdrawTransfer> transfers = transferRepository
                .findByWithdrawIdIn(list.stream().map(WithdrawRequest::getId).toList()).stream()
                .collect(Collectors.toMap(WithdrawTransfer::getWithdrawId, Function.identity()));
        Set<Long> userIds = new HashSet<>();
        for (WithdrawRequest w : list) {
            userIds.add(w.getUserId());
            if (w.getProcessedBy() != null) {
                userIds.add(w.getProcessedBy());
            }
        }
        Map<Long, String> names = userRepository.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, User::getFullName, (a, b) -> a));
        return list.stream().map(w -> WithdrawResponse.of(w, names.get(w.getUserId()),
                w.getProcessedBy() == null ? null : names.get(w.getProcessedBy()), transfers.get(w.getId()))).toList();
    }
}
