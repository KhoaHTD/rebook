package com.rebook.wallet;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Đối soát hằng đêm: số dư mỗi ví phải bằng tổng các dòng sổ cái của ví đó. Lệch là có tiền đổi mà không qua
 * {@link WalletService#move} (hoặc dữ liệu bị sửa tay). Mỗi ví lệch ghi một sự kiện {@code RECONCILE.MISMATCH} và log ERROR.
 * Cũng đếm đơn COD đã giao quá 7 ngày mà sàn vẫn chưa nhận tiền đối soát từ hãng vận chuyển.
 * Ví dữ liệu mẫu (dev) được nạp số dư trực tiếp, không có sổ cái, nên sẽ báo lệch: bình thường ở môi trường dev.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WalletReconciliationJob {

    private final JdbcTemplate jdbc;
    private final AuditLog audit;

    @Scheduled(cron = "0 0 3 * * *", zone = "Asia/Ho_Chi_Minh")
    public void run() {
        try {
            reconcile();
        } catch (Exception e) {
            log.error("Đối soát ví lỗi", e);
        }
    }

    /** Trả về số ví bị lệch. */
    public int reconcile() {
        List<Map<String, Object>> mismatches = jdbc.queryForList("""
                SELECT w.id, w.user_id, w.available_balance, w.held_balance,
                       COALESCE(SUM(t.available_change), 0) AS ledger_available,
                       COALESCE(SUM(t.held_change), 0)      AS ledger_held
                FROM wallets w LEFT JOIN wallet_transactions t ON t.wallet_id = w.id
                GROUP BY w.id
                HAVING w.available_balance <> COALESCE(SUM(t.available_change), 0)
                    OR w.held_balance      <> COALESCE(SUM(t.held_change), 0)
                """);
        for (Map<String, Object> m : mismatches) {
            log.error("Ví {} lệch sổ cái: số dư {}/{} nhưng sổ cái {}/{}", m.get("id"), m.get("available_balance"),
                    m.get("held_balance"), m.get("ledger_available"), m.get("ledger_held"));
            audit.record(EventCode.RECONCILE_MISMATCH, "WALLET", m.get("id"), null, "Số dư ví lệch sổ cái",
                    "userId", m.get("user_id"), "available", m.get("available_balance"), "held", m.get("held_balance"),
                    "ledgerAvailable", m.get("ledger_available"), "ledgerHeld", m.get("ledger_held"));
        }
        Long wallets = jdbc.queryForObject("SELECT count(*) FROM wallets", Long.class);
        Long codOverdue = jdbc.queryForObject("""
                SELECT count(*) FROM orders
                WHERE payment_method = 'COD' AND cod_remitted_at IS NULL
                  AND status IN ('DELIVERED', 'COMPLETED', 'RETURN_REQUESTED', 'RETURNED')
                  AND delivered_at < now() - interval '7 days'
                """, Long.class);
        // shortcut: ngưỡng 7 ngày cứng cho cảnh báo, cùng giá trị mặc định của order.auto_deliver_days; chỉ để cảnh báo, không đổi dữ liệu
        Long codInTransit = jdbc.queryForObject("""
                SELECT count(*) FROM orders
                WHERE payment_method = 'COD' AND status = 'SHIPPING' AND shipped_at < now() - interval '7 days'
                """, Long.class);
        if (codInTransit != null && codInTransit > 0) {
            log.warn("{} đơn COD đang giao quá 7 ngày chưa có kết quả, cần Staff đối chiếu hãng vận chuyển", codInTransit);
        }
        if (codOverdue != null && codOverdue > 0) {
            log.warn("{} đơn COD đã giao quá 7 ngày mà sàn chưa nhận tiền đối soát", codOverdue);
        }
        audit.record(EventCode.RECONCILE_RUN, "SYSTEM", null, null, "Đối soát ví",
                "wallets", wallets, "mismatches", mismatches.size(), "codAwaitingRemittanceOver7Days", codOverdue,
                "codInTransitOver7Days", codInTransit);
        return mismatches.size();
    }
}
