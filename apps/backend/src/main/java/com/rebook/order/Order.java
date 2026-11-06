package com.rebook.order;

import io.swagger.v3.oas.annotations.media.Schema;
import com.rebook.wallet.Payment;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
public class Order {

    /** NORMAL: shop giao, shop nhận tiền. AUCTION: kho của sàn giao, người ký gửi nhận tiền. */
    @Schema(name = "OrderType", enumAsRef = true)
    public enum Type { NORMAL, AUCTION }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String code;
    private Long buyerId;
    /** null với đơn đấu giá. */
    private Long shopId;
    private Long lotId;

    @Enumerated(EnumType.STRING)
    private Type orderType;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    @Enumerated(EnumType.STRING)
    private Payment.Method paymentMethod;

    private Long paymentId;
    private Instant paidAt;

    private BigDecimal subtotal;
    private BigDecimal shippingFee = BigDecimal.ZERO;
    private BigDecimal buyerPremium = BigDecimal.ZERO;
    /** Tiền cọc đấu giá được trừ vào hoá đơn. */
    private BigDecimal depositApplied = BigDecimal.ZERO;
    private BigDecimal total;

    /** Ảnh chụp địa chỉ lúc đặt. */
    @JdbcTypeCode(SqlTypes.JSON)
    private Map<String, Object> addressSnapshot;

    private boolean pickupAtWarehouse;
    private String trackingCode;
    private String note;
    private String cancelReason;
    private boolean cancelRequested;
    private boolean secondChance;

    private Instant paymentDueAt;
    private Instant confirmDueAt;
    private Instant deliveredAt;
    private Instant completedAt;
    private Instant cancelledAt;

    /** Lúc giao cho vận chuyển: mốc để tự coi là đã giao nếu người mua không xác nhận. */
    private Instant shippedAt;

    /** Hạn shop giao cho vận chuyển sau khi xác nhận; lúc người mua gửi yêu cầu huỷ; đơn hỏng do lỗi của shop. */
    private Instant shipDueAt;
    /** Đã báo Staff / Admin hoá đơn đấu giá quá hạn xử lý của kho (một lần). */
    private Instant slaAlertedAt;
    private Instant cancelRequestedAt;
    private boolean sellerFault;

    /** Ai gây giao thất bại (Staff ghi theo hãng vận chuyển, BR-3.7). null = đơn cũ / không rõ. */
    @io.swagger.v3.oas.annotations.media.Schema(name = "DeliveryFault", enumAsRef = true)
    public enum DeliveryFault { BUYER, CARRIER, SHOP }

    @Enumerated(EnumType.STRING)
    private DeliveryFault deliveryFault;

    /** Đã gửi nhắc trước hạn (mỗi loại một lần). */
    private boolean shipReminderSent;
    private boolean cancelReminderSent;
    private boolean paymentReminderSent;

    /** Phí sàn (%) chụp lúc đặt; null = đơn cũ, dùng cấu hình hiện tại. */
    private BigDecimal feePercent;

    /** COD: lúc sàn nhận tiền đối soát từ hãng vận chuyển / lúc đã trả shop / trả hàng đang chờ tiền đối soát. */
    private Instant codRemittedAt;
    private Instant codPaidOutAt;
    private boolean codRefundPending;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    /** Số tiền người mua còn phải trả (đã trừ cọc). */
    public BigDecimal amountDue() {
        return total.subtract(depositApplied);
    }

    public boolean isPaidOnline() {
        return paidAt != null && paymentMethod != Payment.Method.COD;
    }

    public void addItem(OrderItem item) {
        item.setOrder(this);
        items.add(item);
    }
}
