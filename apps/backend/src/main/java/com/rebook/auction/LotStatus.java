package com.rebook.auction;

import com.rebook.common.StatusFlow;

import java.util.EnumSet;
import java.util.Set;

/**
 * Trạng thái lô đấu giá. Lô sinh ra khi người bán chấp nhận kết quả kiểm định.
 * Nhánh phụ: phiên huỷ thì SCHEDULED → READY; người thắng bỏ thanh toán thì SOLD → READY
 * (hoặc mời người trả giá cao thứ hai); UNSOLD → READY / RETURNED / CONVERTED (sang bán giá cố định).
 */
public enum LotStatus implements StatusFlow<LotStatus> {
    /** Trong kho, chờ xếp phiên. */
    READY,
    /** Đã xếp vào phiên. */
    SCHEDULED,
    /** Đang đấu. */
    OPEN,
    /** Đã gõ búa, chờ người thắng thanh toán. */
    SOLD,
    /** Không ai trả hoặc không đạt giá sàn. */
    UNSOLD,
    /** Người thắng đã thanh toán, chờ giao. */
    PAID,
    /** Người mua đã nhận, đã trả tiền người bán. */
    COMPLETED,
    /** Staff huỷ lô khi có sự cố. */
    CANCELLED,
    /** Đã trả sách về cho người bán. */
    RETURNED,
    /** Đã chuyển sang bán giá cố định. */
    CONVERTED,
    /** Đã bán nhưng bị trả về kho (trả hàng / giao thất bại): chờ Staff kiểm định lại trước khi xếp phiên. */
    INSPECTING,
    /** Kho làm mất sách, sàn đã bồi thường (BR-4.2). */
    LOST;

    @Override
    public Set<LotStatus> nextStates() {
        return switch (this) {
            case READY -> EnumSet.of(SCHEDULED, RETURNED, CONVERTED, LOST);
            case SCHEDULED -> EnumSet.of(READY, OPEN, CANCELLED);
            case OPEN -> EnumSet.of(SOLD, UNSOLD, CANCELLED);
            case SOLD -> EnumSet.of(PAID, READY);
            case UNSOLD -> EnumSet.of(READY, RETURNED, CONVERTED, LOST);
            // PAID → RETURNED / LOST: kho làm hỏng / mất sách sau khi người thắng đã trả tiền (BR-4.2)
            case PAID -> EnumSet.of(COMPLETED, READY, INSPECTING, RETURNED, LOST);
            case INSPECTING -> EnumSet.of(READY, RETURNED, LOST);
            case CANCELLED -> EnumSet.of(READY, RETURNED, LOST);
            case COMPLETED, RETURNED, CONVERTED, LOST -> EnumSet.noneOf(LotStatus.class);
        };
    }
}
