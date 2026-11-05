package com.rebook.order;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/** Các thao tác tiền / tồn kho / trả giá chạy song song: chỉ một bên thắng, không tạo trùng, không âm. */
class ConcurrencyTest extends IntegrationTest {

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

    private int post(String url, long user, Role role, String body) throws Exception {
        return mvc.perform(MockMvcRequestBuilders.post(url).with(as(user, role)).contentType(MediaType.APPLICATION_JSON).content(body))
                .andReturn().getResponse().getStatus();
    }

    // ---- Đặt hàng ----

    private record Market(long shop, long listing) {
    }

    private Market market(int stock) {
        long owner = createUser(Role.USER, "Chủ shop", 0);
        long shop = jdbc.queryForObject("""
                INSERT INTO shops (user_id, name, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder)
                VALUES (?, ?, 'Kho', 'Hồ Chí Minh', 'VCB', '1', 'X') RETURNING id""", Long.class, owner, "Shop " + UUID.randomUUID());
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "cc-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, owner, "Sách " + UUID.randomUUID(), category);
        long listing = jdbc.queryForObject("INSERT INTO listings (book_id, shop_id, price, stock, status) VALUES (?, ?, 45000, ?, 'ACTIVE') RETURNING id",
                Long.class, book, shop, stock);
        return new Market(shop, listing);
    }

    private long buyerWithCart(long listing) throws Exception {
        long buyer = createUser(Role.USER, "Người mua", 0);
        long address = jdbc.queryForObject("""
                INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail)
                VALUES (?, 'Người Mua', '0900000000', 'Hồ Chí Minh', 'Q1', 'P1', '1 Lê Lợi') RETURNING id""", Long.class, buyer);
        assertThat(post("/cart", buyer, Role.USER, "{\"listingId\":" + listing + ",\"quantity\":1}")).isEqualTo(200);
        jdbc.update("UPDATE users SET email_verified = TRUE WHERE id = ?", buyer);
        return buyer * 1_000_000_000L + address; // gói hai số vào một giá trị để trả về
    }

    private String checkoutBody(long address) {
        return "{\"addressId\":" + address + ",\"paymentMethod\":\"COD\"}";
    }

    @Test
    void twoSimultaneousCheckoutsOfTheSameCartCreateOnlyOneOrder() throws Exception {
        Market m = market(5);
        long packed = buyerWithCart(m.listing());
        long buyer = packed / 1_000_000_000L;
        long address = packed % 1_000_000_000L;

        List<Integer> codes = race(List.of(
                () -> post("/orders/checkout", buyer, Role.USER, checkoutBody(address)),
                () -> post("/orders/checkout", buyer, Role.USER, checkoutBody(address))));

        assertThat(codes).containsExactlyInAnyOrder(201, 400); // lần hai thấy giỏ đã trống
        assertThat(jdbc.queryForObject("SELECT count(*) FROM orders WHERE buyer_id = ?", Long.class, buyer)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT stock FROM listings WHERE id = ?", Integer.class, m.listing())).isEqualTo(4);
    }

    @Test
    void twoBuyersRacingForTheLastCopyOnlyOneGetsIt() throws Exception {
        Market m = market(1);
        long a = buyerWithCart(m.listing());
        long b = buyerWithCart(m.listing());

        List<Integer> codes = race(List.of(
                () -> post("/orders/checkout", a / 1_000_000_000L, Role.USER, checkoutBody(a % 1_000_000_000L)),
                () -> post("/orders/checkout", b / 1_000_000_000L, Role.USER, checkoutBody(b % 1_000_000_000L))));

        assertThat(codes).containsExactlyInAnyOrder(201, 409);
        assertThat(jdbc.queryForObject("SELECT stock FROM listings WHERE id = ?", Integer.class, m.listing())).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM order_items WHERE listing_id = ?", Long.class, m.listing())).isEqualTo(1);
    }

    // ---- Ví ----

    @Test
    void twoSimultaneousWithdrawalsCannotOverdrawTheWallet() throws Exception {
        long me = createUser(Role.USER, "Người rút", 100_000);
        String body = "{\"amount\":100000,\"bankName\":\"VCB\",\"accountNumber\":\"123456789\",\"accountHolder\":\"NGUOI RUT\"}";

        List<Integer> codes = race(List.of(
                () -> post("/wallet/withdrawals", me, Role.USER, body),
                () -> post("/wallet/withdrawals", me, Role.USER, body)));

        assertThat(codes.stream().filter(c -> c == 201).count()).isEqualTo(1);
        assertThat(walletAvailable(me)).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM withdraw_requests WHERE user_id = ?", Long.class, me)).isEqualTo(1);
    }

    // ---- Trả giá ----

    @Test
    void twoEqualBidsAtTheSameMomentOnlyOneIsAccepted() throws Exception {
        long seller = createUser(Role.USER, "Người ký gửi", 0);
        long a = createUser(Role.USER, "Người A", 0);
        long b = createUser(Role.USER, "Người B", 0);
        long category = jdbc.queryForObject("INSERT INTO categories (name, slug) VALUES ('Test', ?) RETURNING id", Long.class, "cb-" + UUID.randomUUID());
        long book = jdbc.queryForObject("""
                INSERT INTO books (owner_id, title, author, category_id, condition_grade)
                VALUES (?, ?, 'Tác giả', ?, 'GOOD') RETURNING id""", Long.class, seller, "Sách " + UUID.randomUUID(), category);
        long consignment = jdbc.queryForObject("""
                INSERT INTO consignments (code, seller_id, book_id, expected_price, status)
                VALUES (?, ?, ?, 100000, 'ACCEPTED') RETURNING id""", Long.class, "KG-" + UUID.randomUUID().toString().substring(0, 18), seller, book);
        long session = jdbc.queryForObject("""
                INSERT INTO auction_sessions (title, start_at, registration_deadline, deposit_amount, status, started_at)
                VALUES ('Phiên đang chạy', now() - interval '1 hour', now() - interval '2 hour', 50000, 'LIVE', now()) RETURNING id""", Long.class);
        long lot = jdbc.queryForObject("""
                INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low,
                                  estimate_high, status, opened_at, ends_at, rounds)
                VALUES (?, ?, ?, 1, 50000, 100000, 100000, 200000, 'OPEN', now(), now() + interval '60 seconds', 1) RETURNING id""",
                Long.class, session, consignment, book);
        for (long user : new long[]{a, b}) {
            jdbc.update("""
                    INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status)
                    VALUES (?, ?, ?, 50000, 10000000, 'APPROVED')""", session, user, user == a ? 1 : 2);
        }

        List<Integer> codes = race(List.of(
                () -> post("/lots/" + lot + "/bids", a, Role.USER, "{\"amount\":50000}"),
                () -> post("/lots/" + lot + "/bids", b, Role.USER, "{\"amount\":50000}")));

        assertThat(codes).containsExactlyInAnyOrder(200, 409);
        assertThat(jdbc.queryForObject("SELECT bid_count FROM lots WHERE id = ?", Integer.class, lot)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM bids WHERE lot_id = ?", Long.class, lot)).isEqualTo(1);
    }
}
