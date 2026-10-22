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
    CONVERTED;

    @Override
    public Set<LotStatus> nextStates() {
        return switch (this) {
            case READY -> EnumSet.of(SCHEDULED, RETURNED, CONVERTED);
            case SCHEDULED -> EnumSet.of(READY, OPEN, CANCELLED);
            case OPEN -> EnumSet.of(SOLD, UNSOLD, CANCELLED);
            case SOLD -> EnumSet.of(PAID, READY);
            case UNSOLD -> EnumSet.of(READY, RETURNED, CONVERTED);
            case PAID -> EnumSet.of(COMPLETED, READY);
            case CANCELLED -> EnumSet.of(READY, RETURNED);
            case COMPLETED, RETURNED, CONVERTED -> EnumSet.noneOf(LotStatus.class);
        };
    }
}
