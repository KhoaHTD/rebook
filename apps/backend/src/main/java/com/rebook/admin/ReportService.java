package com.rebook.admin;

import com.rebook.common.ApiException;
import com.rebook.common.CodeGenerator;
import com.rebook.order.Order;
import com.rebook.order.OrderStatus;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Báo cáo cho Admin: doanh thu, đơn hàng, người dùng mới theo ngày, cơ cấu theo thể loại và trạng thái. */
@Service
@RequiredArgsConstructor
public class ReportService {

    static final int MAX_DAYS = 366;

    private final EntityManager em;

    public record Day(LocalDate date, BigDecimal gmv, long orders, long newUsers) {
    }

    public record CategorySlice(String name, BigDecimal amount) {
    }

    public record StatusSlice(OrderStatus status, long count) {
    }

    public record ReportResponse(LocalDate from, LocalDate to, BigDecimal gmv, BigDecimal revenue, BigDecimal platformFees,
                                 long orders, long completedOrders, long cancelledOrders, long auctionOrders,
                                 long newUsers, List<Day> days, List<CategorySlice> categories, List<StatusSlice> statuses) {
    }

    /** [from, to] tính cả hai đầu theo giờ Việt Nam. GMV = tổng đơn không bị huỷ / giao thất bại; doanh thu = đơn đã hoàn tất. */
    @Transactional(readOnly = true)
    public ReportResponse report(LocalDate from, LocalDate to) {
        if (to.isBefore(from)) {
            throw ApiException.badRequest("BAD_RANGE", "Ngày kết thúc phải sau ngày bắt đầu");
        }
        if (from.plusDays(MAX_DAYS).isBefore(to)) {
            throw ApiException.badRequest("RANGE_TOO_LONG", "Chỉ xem được tối đa " + MAX_DAYS + " ngày");
        }
        Instant start = from.atStartOfDay(CodeGenerator.VN).toInstant();
        Instant end = to.plusDays(1).atStartOfDay(CodeGenerator.VN).toInstant();

        List<Order> orders = em.createQuery(
                        "select o from Order o where o.createdAt >= :s and o.createdAt < :e", Order.class)
                .setParameter("s", start).setParameter("e", end).getResultList();
        List<Instant> joined = em.createQuery(
                        "select u.createdAt from User u where u.createdAt >= :s and u.createdAt < :e", Instant.class)
                .setParameter("s", start).setParameter("e", end).getResultList();

        Map<LocalDate, BigDecimal> gmvByDay = new TreeMap<>();
        Map<LocalDate, long[]> countByDay = new TreeMap<>(); // [đơn, người dùng mới]
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
            gmvByDay.put(d, BigDecimal.ZERO);
            countByDay.put(d, new long[2]);
        }
        BigDecimal gmv = BigDecimal.ZERO;
        BigDecimal revenue = BigDecimal.ZERO;
        BigDecimal fees = BigDecimal.ZERO;
        long completed = 0;
        long cancelled = 0;
        long auction = 0;
        Map<OrderStatus, Long> byStatus = new EnumMap<>(OrderStatus.class);
        for (Order o : orders) {
            LocalDate day = o.getCreatedAt().atZone(CodeGenerator.VN).toLocalDate();
            byStatus.merge(o.getStatus(), 1L, Long::sum);
            countByDay.get(day)[0]++;
            if (o.getOrderType() == Order.Type.AUCTION) {
                auction++;
            }
            boolean lost = o.getStatus() == OrderStatus.CANCELLED || o.getStatus() == OrderStatus.FAILED_DELIVERY;
            if (o.getStatus() == OrderStatus.CANCELLED) {
                cancelled++;
            }
            if (!lost && o.getTotal() != null) {
                gmv = gmv.add(o.getTotal());
                gmvByDay.merge(day, o.getTotal(), BigDecimal::add);
            }
            if (o.getStatus() == OrderStatus.COMPLETED && o.getTotal() != null) {
                completed++;
                revenue = revenue.add(o.getTotal());
                if (o.getFeePercent() != null && o.getSubtotal() != null) {
                    fees = fees.add(o.getSubtotal().multiply(o.getFeePercent())
                            .divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP));
                }
            }
        }
        for (Instant at : joined) {
            LocalDate day = at.atZone(CodeGenerator.VN).toLocalDate();
            if (countByDay.containsKey(day)) {
                countByDay.get(day)[1]++;
            }
        }

        List<Day> days = new ArrayList<>();
        gmvByDay.forEach((d, v) -> days.add(new Day(d, v, countByDay.get(d)[0], countByDay.get(d)[1])));

        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createQuery("""
                        select c.name, sum(oi.unitPrice * oi.quantity) from OrderItem oi, Listing l, Category c
                        where oi.listingId = l.id and c.id = l.book.categoryId
                          and oi.order.createdAt >= :s and oi.order.createdAt < :e
                          and oi.order.status not in (com.rebook.order.OrderStatus.CANCELLED, com.rebook.order.OrderStatus.FAILED_DELIVERY)
                        group by c.name order by sum(oi.unitPrice * oi.quantity) desc""")
                .setParameter("s", start).setParameter("e", end).setMaxResults(6).getResultList();
        List<CategorySlice> categories = new ArrayList<>();
        for (Object[] r : rows) {
            categories.add(new CategorySlice((String) r[0], (BigDecimal) r[1]));
        }
        List<StatusSlice> statuses = new ArrayList<>();
        byStatus.forEach((s, n) -> statuses.add(new StatusSlice(s, n)));

        return new ReportResponse(from, to, gmv, revenue, fees, orders.size(), completed, cancelled, auction,
                joined.size(), days, categories, statuses);
    }
}
