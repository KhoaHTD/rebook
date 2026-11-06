package com.rebook.auction;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Nhiều người cùng trong một phiên: trả giá tay, giá tối đa tự động, tranh nhau song song, chốt từng lô,
 * hoàn cọc người không thắng. Bước giá: 10.000 dưới 200.000; 50.000 từ 200.000 đến dưới 1.000.000.
 */
class MultiBidderTest extends IntegrationTest {

    private static final long DEPOSIT = 50_000;

    @Autowired
    AuctionRunner runner;

    private long seller;
    private long session;
    private long lot;
    private long category;
    private long[] users; // 5 người trả giá, paddle 1..5

    @BeforeEach
    void setUp() {
        seller = createUser(Role.USER, "Người ký gửi", 0);
        category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "mb-" + UUID.randomUUID());
        session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status, started_at)
                VALUES ('Phiên nhiều người', now() - interval '1 hour', now() - interval '2 hour', ?, 'LIVE', now()) RETURNING id""",
                Long.class, DEPOSIT);
        lot = newLot(1, "OPEN", 50_000, 100_000);
        jdbc.update("UPDATE auction_sessions SET current_lot_id = ? WHERE id = ?", lot, session);
        users = new long[5];
        for (int i = 0; i < users.length; i++) {
            users[i] = createUser(Role.USER, "Người " + (i + 1), 1_000_000);
            jdbc.update("UPDATE wallets SET available_balance = available_balance - ?, held_balance = ? WHERE user_id = ?", DEPOSIT, DEPOSIT, users[i]);
            register(users[i], i + 1, 10_000_000);
        }
    }

    private long newLot(int number, String status, long start, long reserve) {
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, seller, "Sách " + UUID.randomUUID(), category);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, "KG-" + UUID.randomUUID().toString().substring(0, 18), seller, book);
        String open = status.equals("OPEN") ? "now()" : "NULL";
        String ends = status.equals("OPEN") ? "now() + interval '60 seconds'" : "NULL";
        return jdbc.queryForObject("INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low,"
                + " estimate_high, status, opened_at, ends_at, rounds) VALUES (?, ?, ?, ?, ?, ?, 100000, 200000, ?, " + open + ", " + ends
                + ", 1) RETURNING id", Long.class, session, consignment, book, number, start, reserve, status);
    }

    private void register(long user, int paddle, long limit) {
        jdbc.update("""
                INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                VALUES (?, ?, ?, ?, ?, 'APPROVED')""", session, user, paddle, DEPOSIT, limit);
    }

    private int bid(long user, long lotId, long amount) throws Exception {
        return mvc.perform(MockMvcRequestBuilders.post("/lots/" + lotId + "/bids").with(as(user, Role.USER))
                .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":" + amount + "}")).andReturn().getResponse().getStatus();
    }

    private int proxy(long user, long lotId, long max) throws Exception {
        return mvc.perform(MockMvcRequestBuilders.put("/lots/" + lotId + "/proxy-bid").with(as(user, Role.USER))
                .contentType(MediaType.APPLICATION_JSON).content("{\"maxAmount\":" + max + "}")).andReturn().getResponse().getStatus();
    }

    private Map<String, Object> lotRow(long lotId) {
        return jdbc.queryForMap("SELECT current_price, current_winner_id, bid_count, status, ends_at FROM lots WHERE id = ?", lotId);
    }

    private long price(long lotId) {
        return ((Number) lotRow(lotId).get("current_price")).longValue();
    }

    private Long leader(long lotId) {
        Object w = lotRow(lotId).get("current_winner_id");
        return w == null ? null : ((Number) w).longValue();
    }

    @Test
    void fiveBiddersTakeTurnsAndEveryRuleIsEnforced() throws Exception {
        assertThat(bid(users[0], lot, 50_000)).isEqualTo(200);
        assertThat(bid(users[0], lot, 60_000)).as("đang dẫn thì không tự đẩy giá").isEqualTo(409);
        assertThat(bid(users[1], lot, 55_000)).as("dưới giá + bước giá").isEqualTo(409);
        assertThat(bid(users[1], lot, 60_000)).isEqualTo(200);
        assertThat(bid(users[2], lot, 60_000)).as("đúng bằng giá hiện tại").isEqualTo(409);
        assertThat(bid(users[2], lot, 100_000)).as("nhảy giá cao hơn bước tối thiểu được").isEqualTo(200);
        assertThat(bid(users[3], lot, 110_000)).isEqualTo(200);
        assertThat(bid(users[4], lot, 120_000)).isEqualTo(200);
        assertThat(bid(users[0], lot, 130_000)).as("người từng bị vượt được trả lại").isEqualTo(200);

        assertThat(price(lot)).isEqualTo(130_000);
        assertThat(leader(lot)).isEqualTo(users[0]);
        assertThat(lotRow(lot).get("bid_count")).isEqualTo(6);
        List<Long> amounts = jdbc.queryForList("SELECT amount::bigint FROM bids WHERE lot_id = ? ORDER BY id", Long.class, lot);
        assertThat(amounts).isSorted().doesNotHaveDuplicates();
        // Mỗi lần bị vượt, người dẫn trước đó nhận đúng một thông báo
        assertThat(outbidNotices(users[0])).isEqualTo(1); // bị vượt sau lượt 50.000 của chính mình
        assertThat(outbidNotices(users[1])).isEqualTo(1);
        assertThat(outbidNotices(users[4])).isEqualTo(1);
        assertThat(outbidNotices(users[3])).isEqualTo(1);
        assertThat(outbidNotices(users[2])).isEqualTo(1);
    }

    private long outbidNotices(long user) {
        return jdbc.queryForObject("SELECT count(*) FROM notifications WHERE user_id = ? AND type = 'AUCTION_OUTBID'", Long.class, user);
    }

    @Test
    void platformStaffCannotRegisterOrBid() throws Exception {
        long published = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status)
                VALUES ('Phiên sắp tới', now() + interval '2 day', now() + interval '1 day', ?, 'PUBLISHED') RETURNING id""",
                Long.class, DEPOSIT);
        for (Role role : new Role[]{Role.STAFF, Role.ADMIN}) {
            long op = createUser(role, "Nhân viên " + role, 1_000_000);
            jdbc.update("UPDATE users SET phone_verified = true WHERE id = ?", op);
            var res = mvc.perform(MockMvcRequestBuilders.post("/sessions/" + published + "/register").with(as(op, role))
                    .contentType(MediaType.APPLICATION_JSON).content("{\"agreeRules\":true}")).andReturn().getResponse();
            assertThat(res.getStatus()).as(role + " đăng ký phiên").isEqualTo(403);
            assertThat(res.getContentAsString()).contains("STAFF_CANNOT_BID");
            assertThat(walletHeld(op)).as("không bị khoá cọc").isZero();

            // Kể cả đã có đăng ký từ trước (dữ liệu cũ) cũng không trả giá được
            register(op, role == Role.STAFF ? 21 : 22, 10_000_000);
            assertThat(bidAs(op, role, 50_000)).as(role + " trả giá tay").isEqualTo(403);
            assertThat(mvc.perform(MockMvcRequestBuilders.put("/lots/" + lot + "/proxy-bid").with(as(op, role))
                    .contentType(MediaType.APPLICATION_JSON).content("{\"maxAmount\":200000}")).andReturn().getResponse().getStatus())
                    .as(role + " đặt giá tối đa").isEqualTo(403);
        }
        assertThat(lotRow(lot).get("bid_count")).isEqualTo(0);
    }

    private int bidAs(long user, Role role, long amount) throws Exception {
        return mvc.perform(MockMvcRequestBuilders.post("/lots/" + lot + "/bids").with(as(user, role))
                .contentType(MediaType.APPLICATION_JSON).content("{\"amount\":" + amount + "}")).andReturn().getResponse().getStatus();
    }

    @Test
    void outsidersCannotBid() throws Exception {
        long stranger = createUser(Role.USER, "Chưa đăng ký", 1_000_000);
        long banned = createUser(Role.USER, "Bị cấm", 1_000_000);
        register(banned, 9, 10_000_000);
        jdbc.update("UPDATE users SET auction_banned_until = now() + interval '30 days' WHERE id = ?", banned);
        long cancelled = createUser(Role.USER, "Đã huỷ đăng ký", 1_000_000);
        register(cancelled, 8, 10_000_000);
        jdbc.update("UPDATE auction_registrations SET status = 'CANCELLED' WHERE user_id = ? AND session_id = ?", cancelled, session);
        long sellerRegistered = seller;
        register(sellerRegistered, 7, 10_000_000);

        assertThat(bid(stranger, lot, 50_000)).isEqualTo(403);
        assertThat(bid(banned, lot, 50_000)).isEqualTo(403);
        assertThat(bid(cancelled, lot, 50_000)).isEqualTo(403);
        assertThat(bid(sellerRegistered, lot, 50_000)).as("người ký gửi không tự đẩy giá lô của mình").isEqualTo(403);
        assertThat(lotRow(lot).get("bid_count")).isEqualTo(0);
    }

    @Test
    void bidLimitCapsBothManualAndAutomaticBids() throws Exception {
        long limited = createUser(Role.USER, "Hạn mức thấp", 1_000_000);
        register(limited, 6, 150_000);

        assertThat(bid(limited, lot, 160_000)).isEqualTo(400);
        assertThat(proxy(limited, lot, 160_000)).isEqualTo(400);
        assertThat(bid(limited, lot, 150_000)).isEqualTo(200);
        // Người khác vượt rồi, giá tối đa của người này không thể vượt hạn mức
        assertThat(bid(users[0], lot, 160_000)).isEqualTo(200);
        assertThat(proxy(limited, lot, 150_000)).as("dưới mức tối thiểu mới").isEqualTo(400);
        assertThat(leader(lot)).isEqualTo(users[0]);
    }

    @Test
    void competingMaxBidsEndAtOneStepAboveTheLoser() throws Exception {
        assertThat(proxy(users[0], lot, 300_000)).isEqualTo(200);
        assertThat(price(lot)).as("giá tối đa vượt giá sàn: trả hộ lên đúng giá sàn 100.000").isEqualTo(100_000);
        assertThat(proxy(users[1], lot, 200_000)).isEqualTo(200);
        assertThat(leader(lot)).isEqualTo(users[0]);
        assertThat(price(lot)).as("thua ở 200.000 thì người dẫn giữ ở 200.000 + 1 bước").isEqualTo(250_000);

        assertThat(proxy(users[2], lot, 250_000)).as("dưới mức tối thiểu 300.000").isEqualTo(400);
        assertThat(proxy(users[2], lot, 400_000)).isEqualTo(200);
        assertThat(leader(lot)).isEqualTo(users[2]);
        assertThat(price(lot)).isEqualTo(350_000);

        // Tay bấm 450.000 vượt giá tối đa của người dẫn, các proxy cũ hết hiệu lực
        assertThat(bid(users[3], lot, 450_000)).isEqualTo(200);
        assertThat(leader(lot)).isEqualTo(users[3]);
        assertThat(price(lot)).isEqualTo(450_000);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM proxy_bids WHERE lot_id = ? AND active", Long.class, lot)).isZero();
        List<Long> amounts = jdbc.queryForList("SELECT amount::bigint FROM bids WHERE lot_id = ? ORDER BY id", Long.class, lot);
        assertThat(amounts).isSorted().doesNotHaveDuplicates();
    }

    @Test
    void maxBidAboveReserveSellsTheLotInsteadOfReserveNotMet() throws Exception {
        // Trước đây: một người đặt giá tối đa 300.000 (giá sàn 100.000) thì lô đứng ở 50.000 và chốt "Không đạt giá"
        assertThat(proxy(users[0], lot, 300_000)).isEqualTo(200);
        assertThat(price(lot)).isEqualTo(100_000);
        assertThat(leader(lot)).isEqualTo(users[0]);

        jdbc.update("UPDATE lots SET ends_at = now() - interval '1 second' WHERE id = ?", lot);
        runner.tick(session);

        assertThat(jdbc.queryForMap("SELECT status, close_result, hammer_price::bigint AS hammer FROM lots WHERE id = ?", lot))
                .containsEntry("status", "SOLD").containsEntry("close_result", "SOLD").containsEntry("hammer", 100_000L);
    }

    @Test
    void lotThatExpiredWhileTheBackendWasDownIsExtendedInsteadOfClosed() throws Exception {
        assertThat(bid(users[0], lot, 50_000)).isEqualTo(200);
        // Backend tắt 30 giây quá giờ chốt của lô: không ai trả giá được trong lúc đó
        jdbc.update("UPDATE lots SET ends_at = now() - interval '30 seconds' WHERE id = ?", lot);

        runner.recoverAfterRestart(session);
        runner.tick(session);

        assertThat(lotRow(lot).get("status")).as("không bị chốt ngay khi bật lại").isEqualTo("OPEN");
        long left = jdbc.queryForObject("SELECT extract(epoch FROM ends_at - now())::bigint FROM lots WHERE id = ?", Long.class, lot);
        assertThat(left).as("còn ít nhất thời gian soft close").isGreaterThanOrEqualTo(10);
        assertThat(bid(users[1], lot, 60_000)).as("trả giá tiếp được").isEqualTo(200);
    }

    @Test
    void lotWithEnoughTimeLeftIsNotTouchedOnRestart() {
        Object before = lotRow(lot).get("ends_at");
        runner.recoverAfterRestart(session);
        assertThat(lotRow(lot).get("ends_at")).isEqualTo(before);
    }

    @Test
    void maxBidBelowReserveIsNotLifted() throws Exception {
        assertThat(proxy(users[0], lot, 90_000)).isEqualTo(200);
        assertThat(price(lot)).as("giá tối đa dưới giá sàn: giữ ở giá khởi điểm").isEqualTo(50_000);
    }

    @Test
    void proxyAnswersAManualBidWithoutExceedingItsMax() throws Exception {
        assertThat(proxy(users[0], lot, 200_000)).isEqualTo(200);
        assertThat(price(lot)).as("đã được trả hộ lên giá sàn").isEqualTo(100_000);
        assertThat(bid(users[1], lot, 110_000)).isEqualTo(200);

        assertThat(leader(lot)).as("proxy trả lời lại").isEqualTo(users[0]);
        assertThat(price(lot)).isEqualTo(120_000);
        assertThat(outbidNotices(users[1])).isEqualTo(1);
    }

    @Test
    void manualBidEqualToTheLeadersMaxDoesNotStealTheLead() throws Exception {
        jdbc.update("UPDATE lots SET reserve_price = 200000 WHERE id = ?", lot); // giá tối đa dưới giá sàn: không trả hộ lên giá sàn
        assertThat(proxy(users[0], lot, 100_000)).isEqualTo(200);
        assertThat(price(lot)).isEqualTo(50_000);
        assertThat(bid(users[1], lot, 100_000)).isEqualTo(200);

        // Quy tắc của hệ thống (BidService.resolveProxies): bằng giá tối đa thì người đặt trước giữ giá
        assertThat(leader(lot)).isEqualTo(users[0]);
        assertThat(price(lot)).isEqualTo(100_000);
    }

    @Test
    void maxBidPlacedWhilePausedIsAppliedWhenTheSessionResumes() throws Exception {
        assertThat(bid(users[0], lot, 50_000)).isEqualTo(200);
        runner.pause(session);
        jdbc.update("UPDATE lots SET ends_at = now() - interval '10 minutes' WHERE id = ?", lot); // tạm dừng đã lâu hơn giờ cũ của lô

        assertThat(bid(users[1], lot, 60_000)).as("đang tạm dừng").isEqualTo(409);
        assertThat(proxy(users[1], lot, 200_000)).as("đặt giá tối đa khi tạm dừng được nhận").isEqualTo(200);
        assertThat(price(lot)).as("chưa chạy khi còn tạm dừng").isEqualTo(50_000);

        runner.resume(session);

        assertThat(leader(lot)).isEqualTo(users[1]);
        assertThat(price(lot)).as("vượt người dẫn rồi trả hộ lên giá sàn").isEqualTo(100_000);
        assertThat(outbidNotices(users[0])).isEqualTo(1);
        long left = jdbc.queryForObject("SELECT extract(epoch FROM ends_at - now())::bigint FROM lots WHERE id = ?", Long.class, lot);
        assertThat(left).as("đồng hồ được đặt lại").isGreaterThanOrEqualTo(10);
    }

    @Test
    void bidInTheLastSecondsExtendsTheClock() throws Exception {
        jdbc.update("UPDATE lots SET ends_at = now() + interval '3 seconds' WHERE id = ?", lot);

        assertThat(bid(users[0], lot, 50_000)).isEqualTo(200);

        long left = jdbc.queryForObject("SELECT extract(epoch FROM ends_at - now())::bigint FROM lots WHERE id = ?", Long.class, lot);
        assertThat(left).as("soft close 15 giây").isGreaterThanOrEqualTo(12);
    }

    @Test
    void noBidIsAcceptedAfterTheClockRunsOut() throws Exception {
        assertThat(bid(users[0], lot, 50_000)).isEqualTo(200);
        jdbc.update("UPDATE lots SET ends_at = now() - interval '1 second' WHERE id = ?", lot);

        assertThat(bid(users[1], lot, 60_000)).isEqualTo(409);
        assertThat(proxy(users[1], lot, 200_000)).as("đặt giá tối đa sau giờ chốt cũng bị từ chối").isEqualTo(409);
        assertThat(price(lot)).isEqualTo(50_000);
        assertThat(leader(lot)).isEqualTo(users[0]);
    }

    @Test
    void manyBiddersRacingKeepTheLotConsistent() throws Exception {
        // 5 người cùng trả giá khác nhau, mỗi người 4 lượt tăng dần, tất cả cùng lúc
        List<Callable<Integer>> calls = new ArrayList<>();
        for (int round = 0; round < 4; round++) {
            for (int i = 0; i < users.length; i++) {
                long user = users[i];
                long amount = 50_000 + (round * 5L + i) * 10_000;
                calls.add(() -> bid(user, lot, amount));
            }
        }
        List<Integer> codes = race(calls);

        long ok = codes.stream().filter(c -> c == 200).count();
        assertThat(codes).allMatch(c -> c == 200 || c == 409);
        assertThat(ok).isGreaterThanOrEqualTo(1);
        Map<String, Object> row = lotRow(lot);
        long bids = jdbc.queryForObject("SELECT count(*) FROM bids WHERE lot_id = ?", Long.class, lot);
        assertThat(((Number) row.get("bid_count")).longValue()).as("bid_count khớp số dòng").isEqualTo(bids).isEqualTo(ok);
        List<Long> amounts = jdbc.queryForList("SELECT amount::bigint FROM bids WHERE lot_id = ? ORDER BY id", Long.class, lot);
        assertThat(amounts).as("mỗi lượt được nhận phải cao hơn lượt trước").isSorted().doesNotHaveDuplicates();
        assertThat(price(lot)).isEqualTo(amounts.get(amounts.size() - 1));
        long lastBidder = jdbc.queryForObject("SELECT user_id FROM bids WHERE lot_id = ? ORDER BY id DESC LIMIT 1", Long.class, lot);
        assertThat(leader(lot)).isEqualTo(lastBidder);
    }

    @Test
    void racingBiddersWithMaxBidsStillEndWithASingleConsistentLeader() throws Exception {
        List<Callable<Integer>> calls = new ArrayList<>();
        for (int i = 0; i < users.length; i++) {
            long user = users[i];
            long max = 200_000 + i * 50_000L;
            calls.add(() -> proxy(user, lot, max));
        }
        race(calls);

        // Thứ tự tới server không cố định (có người bị từ chối vì thấp hơn mức tối thiểu lúc đó),
        // nhưng người đặt giá tối đa cao nhất luôn phải đang dẫn và giá không vượt giá tối đa của họ
        assertThat(leader(lot)).isEqualTo(users[4]);
        assertThat(price(lot)).isLessThanOrEqualTo(400_000);
        List<Long> amounts = jdbc.queryForList("SELECT amount::bigint FROM bids WHERE lot_id = ? ORDER BY id", Long.class, lot);
        assertThat(amounts).isSorted().doesNotHaveDuplicates();
    }

    @Test
    void wholeSessionTwoLotsSettlesWinnersAndRefundsLosers() throws Exception {
        long lot2 = newLot(2, "SCHEDULED", 50_000, 100_000);
        // Lô 1: người 1 thắng ở 120.000 sau khi người 2, 3 trả giá
        assertThat(bid(users[1], lot, 60_000)).isEqualTo(200);
        assertThat(bid(users[2], lot, 100_000)).isEqualTo(200);
        assertThat(bid(users[0], lot, 120_000)).isEqualTo(200);
        jdbc.update("UPDATE lots SET ends_at = now() - interval '1 second' WHERE id = ?", lot);
        runner.tick(session);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot)).isEqualTo("SOLD");
        assertThat(bid(users[3], lot, 200_000)).as("lô đã chốt").isEqualTo(409);

        // Lô 2: người 4 trả 90.000, thấp hơn giá sàn 100.000 nên lô không bán
        jdbc.update("UPDATE auction_sessions SET next_lot_at = now() - interval '1 second' WHERE id = ?", session);
        runner.tick(session);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot2)).isEqualTo("OPEN");
        assertThat(bid(users[3], lot2, 90_000)).isEqualTo(200);
        jdbc.update("UPDATE lots SET ends_at = now() - interval '1 second' WHERE id = ?", lot2);
        runner.tick(session);
        assertThat(jdbc.queryForObject("SELECT status FROM lots WHERE id = ?", String.class, lot2)).isEqualTo("UNSOLD");

        jdbc.update("UPDATE auction_sessions SET next_lot_at = now() - interval '1 second' WHERE id = ?", session);
        runner.tick(session); // hết lô → kết thúc phiên
        assertThat(jdbc.queryForObject("SELECT status FROM auction_sessions WHERE id = ?", String.class, session)).isEqualTo("ENDED");

        // Chỉ người 1 thắng: có hoá đơn; bốn người còn lại (kể cả người trả giá nhưng thua / lô không bán) nhận lại cọc
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE lot_id = ? AND buyer_id = ?", Long.class, lot, users[0])).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE lot_id IN (?, ?)", Long.class, lot, lot2)).isEqualTo(1);
        assertThat(walletHeld(users[0])).as("cọc người thắng giữ tới khi thanh toán").isEqualTo(DEPOSIT);
        for (int i = 1; i < users.length; i++) {
            assertThat(walletHeld(users[i])).as("người " + (i + 1) + " hết bị giữ cọc").isZero();
            assertThat(walletAvailable(users[i])).as("người " + (i + 1) + " nhận lại đủ tiền").isEqualTo(1_000_000);
        }
        // Mỗi người thua có đúng một dòng hoàn cọc
        assertThat(jdbc.queryForObject("SELECT count(*) FROM wallet_transactions t JOIN wallets w ON w.id = t.wallet_id "
                + "WHERE w.user_id IN (?, ?, ?, ?) AND t.held_change < 0", Long.class,
                users[1], users[2], users[3], users[4])).isEqualTo(4);
    }

    /** Chạy các lời gọi cùng lúc (chờ chung một vạch xuất phát), trả về mã HTTP theo thứ tự. */
    private List<Integer> race(List<Callable<Integer>> calls) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(calls.size());
        CountDownLatch ready = new CountDownLatch(calls.size());
        CountDownLatch go = new CountDownLatch(1);
        List<Future<Integer>> futures = new ArrayList<>();
        for (Callable<Integer> c : calls) {
            futures.add(pool.submit(() -> {
                ready.countDown();
                go.await();
                return c.call();
            }));
        }
        ready.await();
        go.countDown();
        List<Integer> codes = new ArrayList<>();
        for (Future<Integer> f : futures) {
            codes.add(f.get());
        }
        pool.shutdown();
        return codes;
    }
}
