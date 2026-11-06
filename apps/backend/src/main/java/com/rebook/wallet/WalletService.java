package com.rebook.wallet;

import com.rebook.audit.ActivityLogService;
import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.system.SystemConfigService;
import com.rebook.common.PageResponse;
import com.rebook.order.OrderRepository;
import com.rebook.order.OrderStatus;
import com.rebook.user.ShopRepository;
import com.rebook.user.User;
import com.rebook.user.UserRepository;
import com.rebook.wallet.WalletDtos.BankAccountResponse;
import com.rebook.wallet.WalletDtos.ProcessRequest;
import com.rebook.wallet.WalletDtos.TransactionResponse;
import com.rebook.wallet.WalletDtos.WalletResponse;
import com.rebook.wallet.WalletDtos.WithdrawableResponse;
import com.rebook.wallet.WalletDtos.WithdrawCreateRequest;
import com.rebook.wallet.WalletDtos.WithdrawResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
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
    private final BankAccountRepository bankAccountRepository;
    private final UserRepository userRepository;
    private final ActivityLogService activityLog;
    private final AuditLog audit;
    private final SystemConfigService config;
    private final AccountDebtRepository debtRepository;
    private final ShopRepository shopRepository;
    private final OrderRepository orderRepository;

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
        WalletTransaction saved = transactionRepository.save(tx);
        audit.record(EventCode.WALLET_TX_POSTED, "WALLET", wallet.getId(), null, note,
                "ledgerId", saved.getId(), "type", type, "availableChange", availableChange, "heldChange", heldChange,
                "availableAfter", newAvailable, "heldAfter", newHeld, "refType", refType, "refId", refId);
        return saved;
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

    /** Khoá dòng ví của người dùng trong giao dịch hiện tại (tuần tự hoá các thao tác tiền của họ). */
    public Wallet lock(Long userId) {
        return walletRepository.lockByUserId(userId).orElseThrow(() -> ApiException.notFound("ví"));
    }

    /**
     * Số tiền rút được ngay = số dư dùng được − tiền mới nạp chưa dùng trong {@code wallet.topup_hold_hours} giờ gần nhất.
     * Tiền nạp đã tiêu (thanh toán, cọc, phí) trong khoảng đó không còn bị khoá. Đặt 0 giờ để tắt khoá.
     */
    @Transactional(readOnly = true)
    public WithdrawableResponse withdrawable(Long userId) {
        Wallet wallet = get(userId);
        BigDecimal locked = BigDecimal.ZERO;
        Instant unlockAt = null;
        int hours = config.integer(SystemConfigService.TOPUP_HOLD_HOURS);
        if (hours > 0) {
            Instant since = Instant.now().minus(Duration.ofHours(hours));
            BigDecimal topUps = transactionRepository.sumAvailableChange(wallet.getId(), List.of(WalletTxType.TOP_UP), since);
            if (topUps.signum() > 0) {
                BigDecimal spent = transactionRepository.sumAvailableChange(wallet.getId(),
                        List.of(WalletTxType.PAYMENT, WalletTxType.DEPOSIT_HOLD, WalletTxType.FEE), since).negate();
                BigDecimal back = transactionRepository.sumAvailableChange(wallet.getId(),
                        List.of(WalletTxType.REFUND, WalletTxType.DEPOSIT_RELEASE), since);
                locked = topUps.subtract(spent.subtract(back).max(BigDecimal.ZERO)).max(BigDecimal.ZERO);
                unlockAt = transactionRepository
                        .findFirstByWalletIdAndTypeAndCreatedAtGreaterThanEqualOrderByCreatedAtAsc(wallet.getId(), WalletTxType.TOP_UP, since)
                        .map(t -> t.getCreatedAt().plus(Duration.ofHours(hours))).orElse(null);
            }
        }
        // Tiền bán hàng của shop mới giữ thêm vài ngày: chặn nạp thẻ trộm, mua của shop phụ rồi rút ngay (P0 mục 4)
        // shortcut: cộng tiền gộp SALE_RELEASE trước phí sàn nên giữ dư tối đa bằng phí sàn; tách khi cần chính xác từng đồng
        BigDecimal saleHeld = BigDecimal.ZERO;
        Instant saleUnlockAt = null;
        int holdDays = config.integer(SystemConfigService.SELLER_HOLD_DAYS);
        if (holdDays > 0 && isNewSeller(userId)) {
            Instant since = Instant.now().minus(Duration.ofDays(holdDays));
            saleHeld = transactionRepository.sumAvailableChange(wallet.getId(), List.of(WalletTxType.SALE_RELEASE), since)
                    .max(BigDecimal.ZERO);
            if (saleHeld.signum() > 0) {
                saleUnlockAt = transactionRepository
                        .findFirstByWalletIdAndTypeAndCreatedAtGreaterThanEqualOrderByCreatedAtAsc(wallet.getId(), WalletTxType.SALE_RELEASE, since)
                        .map(t -> t.getCreatedAt().plus(Duration.ofDays(holdDays))).orElse(null);
            }
        }
        BigDecimal available = wallet.getAvailableBalance();
        return new WithdrawableResponse(available, locked, available.subtract(locked).subtract(saleHeld).max(BigDecimal.ZERO),
                locked.signum() > 0 ? unlockAt : null, saleHeld, saleUnlockAt);
    }

    /** Shop mới: chưa được Admin gắn uy tín, và mở chưa đủ N ngày hoặc chưa đủ M đơn hoàn tất. */
    private boolean isNewSeller(Long userId) {
        Instant openedBefore = Instant.now().minus(Duration.ofDays(config.integer(SystemConfigService.SELLER_HOLD_SHOP_DAYS)));
        return shopRepository.findByUserId(userId).filter(s -> !s.isTrusted())
                .map(s -> s.getCreatedAt().isAfter(openedBefore)
                        || orderRepository.countByShopIdAndStatus(s.getId(), OrderStatus.COMPLETED)
                        < config.integer(SystemConfigService.SELLER_HOLD_MIN_ORDERS))
                .orElse(false);
    }

    /** Che số tài khoản trong log, chỉ giữ 4 số cuối. */
    static String mask(String accountNumber) {
        if (accountNumber == null || accountNumber.length() <= 4) {
            return "****";
        }
        return "****" + accountNumber.substring(accountNumber.length() - 4);
    }

    // ---- Truy vấn ----

    public Wallet get(Long userId) {
        return walletRepository.findByUserId(userId).orElseThrow(() -> ApiException.notFound("ví"));
    }

    public WalletResponse summary(Long userId) {
        return WalletResponse.of(get(userId));
    }

    public BigDecimal platformAvailable() {
        return walletRepository.findPlatform().orElseThrow(() -> ApiException.notFound("ví sàn")).getAvailableBalance();
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
        lock(userId); // hai yêu cầu cùng lúc không được lách hạn mức
        if (debtRepository.existsByUserIdAndStatus(userId, AccountDebt.Status.OPEN)) {
            audit.recordDenied(EventCode.WITHDRAW_BLOCKED, "DEBT_OPEN", "WALLET", userId, "Còn nợ phạt / phí kho chưa thanh toán",
                    "amount", req.amount());
            throw ApiException.conflict("DEBT_OPEN", "Bạn còn khoản nợ phạt hoặc phí kho chưa thanh toán, hãy thanh toán trước khi rút tiền");
        }
        WithdrawableResponse limit = withdrawable(userId);
        // Đủ số dư nhưng một phần là tiền mới nạp còn bị khoá. Thiếu số dư thì để bước khoá tiền báo INSUFFICIENT_BALANCE.
        boolean overTopupLock = req.amount().compareTo(limit.available().subtract(limit.locked())) > 0;
        if (req.amount().compareTo(limit.available()) <= 0 && req.amount().compareTo(limit.withdrawable()) > 0 && !overTopupLock) {
            audit.recordDenied(EventCode.WITHDRAW_BLOCKED, "SALE_HELD", "WALLET", userId,
                    "Rút vượt phần tiền được phép rút (shop mới, tiền bán hàng đang giữ)",
                    "amount", req.amount(), "available", limit.available(), "saleHeld", limit.saleHeld(),
                    "withdrawable", limit.withdrawable(), "saleUnlockAt", limit.saleUnlockAt());
            throw ApiException.conflict("SALE_HELD", "Hiện rút được tối đa " + limit.withdrawable().toPlainString()
                    + "đ. Shop mới: tiền bán hàng được rút sau " + config.integer(SystemConfigService.SELLER_HOLD_DAYS)
                    + " ngày kể từ khi đơn hoàn tất" + (limit.saleUnlockAt() == null ? ""
                    : ", khoản sớm nhất mở lúc " + limit.saleUnlockAt().atZone(CodeGenerator.VN).toLocalDateTime().toString().replace('T', ' ')));
        }
        if (req.amount().compareTo(limit.available()) <= 0 && req.amount().compareTo(limit.withdrawable()) > 0) {
            audit.recordDenied(EventCode.WITHDRAW_BLOCKED, "TOPUP_LOCKED", "WALLET", userId,
                    "Rút vượt phần tiền được phép rút (còn khoá tiền mới nạp)",
                    "amount", req.amount(), "available", limit.available(), "locked", limit.locked(),
                    "withdrawable", limit.withdrawable(), "unlockAt", limit.unlockAt());
            throw ApiException.conflict("TOPUP_LOCKED", "Hiện rút được tối đa " + limit.withdrawable().toPlainString()
                    + "đ. Tiền mới nạp được rút sau " + (limit.unlockAt() == null ? "ít giờ nữa"
                    : limit.unlockAt().atZone(CodeGenerator.VN).toLocalDateTime().toString().replace('T', ' ')));
        }
        Instant dayStart = LocalDate.now(CodeGenerator.VN).atStartOfDay(CodeGenerator.VN).toInstant();
        BigDecimal requestedToday = withdrawRepository.sumRequestedSince(userId, dayStart);
        BigDecimal dailyLimit = config.decimal(SystemConfigService.WITHDRAW_DAILY_LIMIT);
        if (requestedToday.add(req.amount()).compareTo(dailyLimit) > 0) {
            audit.recordDenied(EventCode.WITHDRAW_BLOCKED, "WITHDRAW_DAILY_LIMIT", "WALLET", userId,
                    "Vượt hạn mức rút trong ngày", "amount", req.amount(), "requestedToday", requestedToday,
                    "dailyLimit", dailyLimit);
            throw ApiException.conflict("WITHDRAW_DAILY_LIMIT", "Vượt hạn mức rút " + dailyLimit.toPlainString()
                    + "đ mỗi ngày, hôm nay bạn đã yêu cầu " + requestedToday.toPlainString() + "đ");
        }
        WithdrawRequest w = new WithdrawRequest();
        w.setTopupLocked(limit.locked());
        w.setUserId(userId);
        w.setAmount(req.amount());
        w.setBankName(req.bankName());
        w.setAccountNumber(req.accountNumber());
        w.setAccountHolder(req.accountHolder());
        w.setUserNote(req.note() == null || req.note().isBlank() ? null : req.note().trim());
        w = withdrawRepository.save(w);
        // Khoá tiền trong lúc chờ duyệt
        hold(userId, WalletTxType.WITHDRAW, req.amount(), "WITHDRAW", w.getId(), "Yêu cầu rút tiền");
        rememberBankAccount(userId, req);
        audit.record(EventCode.WITHDRAW_REQUESTED, "WITHDRAW", w.getId(), null, "Yêu cầu rút tiền",
                "amount", req.amount(), "bankName", req.bankName(), "accountMasked", mask(req.accountNumber()),
                "topupLocked", limit.locked());
        return toResponse(List.of(w)).get(0);
    }

    @Transactional(readOnly = true)
    public List<WithdrawResponse> myWithdrawals(Long userId) {
        return toResponse(withdrawRepository.findByUserIdOrderByIdDesc(userId));
    }

    // ---- Tài khoản ngân hàng đã dùng ----

    @Transactional(readOnly = true)
    public List<BankAccountResponse> bankAccounts(Long userId) {
        return bankAccountRepository.findByUserIdOrderByFavoriteDescLastUsedAtDesc(userId).stream()
                .map(BankAccountResponse::of).toList();
    }

    @Transactional
    public BankAccountResponse setBankAccountFavorite(Long userId, Long id, boolean on) {
        BankAccount a = bankAccountRepository.findById(id)
                .filter(x -> x.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("tài khoản ngân hàng"));
        a.setFavorite(on);
        return BankAccountResponse.of(a);
    }

    private void rememberBankAccount(Long userId, WithdrawCreateRequest req) {
        BankAccount a = bankAccountRepository
                .findByUserIdAndBankNameAndAccountNumber(userId, req.bankName(), req.accountNumber())
                .orElseGet(() -> {
                    BankAccount n = new BankAccount();
                    n.setUserId(userId);
                    n.setBankName(req.bankName());
                    n.setAccountNumber(req.accountNumber());
                    return n;
                });
        a.setAccountHolder(req.accountHolder());
        a.setLastUsedAt(Instant.now());
        bankAccountRepository.save(a);
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
