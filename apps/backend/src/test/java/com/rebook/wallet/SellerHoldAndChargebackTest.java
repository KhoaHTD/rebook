package com.rebook.wallet;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** P0 mục 4: giữ tiền bán hàng của shop mới, ghi nợ khi ngân hàng đòi lại tiền nạp. */
class SellerHoldAndChargebackTest extends IntegrationTest {

    @Autowired
    WalletService walletService;
    @Autowired
    org.springframework.transaction.support.TransactionTemplate tx;

    private void saleRelease(long owner, long amount) {
        tx.executeWithoutResult(s -> walletService.credit(owner, WalletTxType.SALE_RELEASE, BigDecimal.valueOf(amount), "ORDER", 1L,
                "Giải ngân đơn test"));
    }

    private long seller(boolean trusted, String openedAgo) {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        jdbc.update("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder,
                                   trusted, created_at)
                VALUES (?, ?, 'Kho', 'Hà Nội', 'VCB', '123456', 'X', ?, now() - CAST(? AS interval))""",
                owner, "Shop " + UUID.randomUUID(), trusted, openedAgo);
        return owner;
    }

    private org.springframework.test.web.servlet.ResultActions withdraw(long user, long amount) throws Exception {
        return mvc.perform(post("/wallet/withdrawals").with(as(user, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"bankName\":\"VCB\",\"accountNumber\":\"0123456789\",\"accountHolder\":\"NGUYEN VAN A\"}"));
    }

    @Test
    void newShopCannotWithdrawFreshSalesButCanWithdrawOlderMoney() throws Exception {
        long owner = seller(false, "2 days");
        jdbc.update("UPDATE wallets SET available_balance = 100000 WHERE user_id = ?", owner); // tiền cũ, không phải tiền bán
        saleRelease(owner, 300_000);

        mvc.perform(get("/wallet/withdrawable").with(as(owner, Role.USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.saleHeld").value(300000))
                .andExpect(jsonPath("$.withdrawable").value(100000))
                .andExpect(jsonPath("$.saleUnlockAt").exists());
        withdraw(owner, 200_000).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("SALE_HELD"));
        withdraw(owner, 100_000).andExpect(status().isCreated());
    }

    @Test
    void trustedShopIsNotHeld() throws Exception {
        long owner = seller(true, "2 days");
        saleRelease(owner, 300_000);

        withdraw(owner, 300_000).andExpect(status().isCreated());
    }

    @Test
    void chargebackTakesWhatIsInTheWalletAndBlocksWithdrawalForTheRest() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin", 0);
        long user = createUser(Role.USER, "Người nạp thẻ trộm", 30_000);

        mvc.perform(post("/admin/debts/chargeback").with(as(admin, Role.ADMIN)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":" + user + ",\"amount\":100000,\"reason\":\"ZaloPay báo hoàn giao dịch nạp\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("CHARGEBACK"))
                .andExpect(jsonPath("$.paidAmount").value(30000))
                .andExpect(jsonPath("$.status").value("OPEN"));
        assertThat(walletAvailable(user)).isZero();

        jdbc.update("UPDATE wallets SET available_balance = 60000 WHERE user_id = ?", user);
        withdraw(user, 50_000).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("DEBT_OPEN"));

        mvc.perform(post("/admin/debts/chargeback").with(as(user, Role.USER)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":" + user + ",\"amount\":100000,\"reason\":\"tự ghi nợ\"}"))
                .andExpect(status().isForbidden());
    }
}
