package com.rebook.auction;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Người thắng bỏ thanh toán: chỉ mời người trả giá cao thứ hai khi giá của họ đạt giá sàn. */
class SecondChanceOfferTest extends IntegrationTest {

    private static final long RESERVE = 100_000;

    @Autowired
    AuctionSettlement settlement;

    private long winner;
    private long runnerUp;
    private long sessionId;
    private long lotId;
    private long winnerRegId;
    private long runnerRegId;

    private static String code(String prefix) {
        return prefix + UUID.randomUUID().toString().substring(0, 18);
    }

    @BeforeEach
    void setUp() {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        winner = createUser(Role.USER, "Người thắng", 0);
        runnerUp = createUser(Role.USER, "Người về nhì", 0);
        jdbc.update("UPDATE wallets SET held_balance = 50000 WHERE user_id = ?", winner);

        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id",
                Long.class, "test-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, 'Sách quý', 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, seller, category);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, code("CG-"), seller, book);
        sessionId = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên test', now() - interval '1 day', now() - interval '2 day', 50000, 'ENDED') RETURNING id""",
                Long.class);
        lotId = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price,
                                  estimate_low, estimate_high, current_price, opened_at, status, close_result,
                                  hammer_price, winner_id, rounds)
                VALUES (?, ?, ?, 1, 50000, ?, 100000, 200000, 120000, now() - interval '1 day', 'SOLD', 'SOLD', 120000, ?, 1)
                RETURNING id""", Long.class, sessionId, consignment, book, RESERVE, winner);
        winnerRegId = registration(winner, 1, "APPROVED");
        runnerRegId = registration(runnerUp, 2, "REFUNDED");
    }

    private long registration(long user, int paddle, String status) {
        return jdbc.queryForObject("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, ?, 50000, 1000000, ?) RETURNING id""", Long.class, sessionId, user, paddle, status);
    }

    private void bid(long user, long reg, long amount) {
        jdbc.update("INSERT INTO bids (lot_id, user_id, registration_id, amount) VALUES (?, ?, ?, ?)", lotId, user, reg, amount);
    }

    private long overdueInvoice() {
        return jdbc.queryForObject("""
                INSERT INTO orders (code, buyer_id, lot_id, order_type, status, subtotal, total, payment_due_at, pickup_at_warehouse)
                VALUES (?, ?, ?, 'AUCTION', 'PENDING_PAYMENT', 120000, 120000, now() - interval '1 hour', TRUE) RETURNING id""",
                Long.class, code("OD-"), winner, lotId);
    }

    private long secondChanceOrders() {
        return jdbc.queryForObject("SELECT count(*) FROM orders WHERE lot_id = ? AND second_chance", Long.class, lotId);
    }

    @Test
    void runnerUpBelowReserveIsNotOfferedAndLotGoesBackToQueue() {
        bid(runnerUp, runnerRegId, 90_000);
        bid(winner, winnerRegId, 120_000);

        settlement.handleOverdue(overdueInvoice());

        assertThat(secondChanceOrders()).isZero();
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lotId)).isEqualTo("READY");
    }

    @Test
    void runnerUpAtOrAboveReserveIsOffered() {
        bid(runnerUp, runnerRegId, RESERVE);
        bid(winner, winnerRegId, 120_000);

        settlement.handleOverdue(overdueInvoice());

        assertThat(secondChanceOrders()).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT buyer_id FROM orders WHERE lot_id = ? AND second_chance", Long.class, lotId))
                .isEqualTo(runnerUp);
        assertThat(jdbc.queryForObject("SELECT hammer_price FROM lots WHERE id = ?", Long.class, lotId)).isEqualTo(RESERVE);
    }
}
