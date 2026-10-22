package com.rebook.catalog;

import com.rebook.common.StatusFlow;

import java.util.EnumSet;
import java.util.Set;

/**
 * Chờ duyệt → Đang bán ⇄ Hết hàng / Ẩn; Bị từ chối → sửa lại → Chờ duyệt.
 * Chỉ ẩn được tin đã duyệt, nên hiện lại thì về thẳng Đang bán / Hết hàng.
 */
public enum ListingStatus implements StatusFlow<ListingStatus> {
    PENDING_REVIEW, ACTIVE, OUT_OF_STOCK, HIDDEN, REJECTED;

    @Override
    public Set<ListingStatus> nextStates() {
        return switch (this) {
            case PENDING_REVIEW -> EnumSet.of(ACTIVE, OUT_OF_STOCK, REJECTED);
            case ACTIVE -> EnumSet.of(OUT_OF_STOCK, HIDDEN, PENDING_REVIEW);
            case OUT_OF_STOCK -> EnumSet.of(ACTIVE, HIDDEN, PENDING_REVIEW);
            case HIDDEN -> EnumSet.of(ACTIVE, OUT_OF_STOCK, PENDING_REVIEW);
            case REJECTED -> EnumSet.of(PENDING_REVIEW);
        };
    }
}
