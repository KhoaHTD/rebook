package com.rebook.auction;

import com.rebook.common.StatusFlow;

import java.util.EnumSet;
import java.util.Set;

/** Trạng thái phiên đấu giá (mục 7.2 của đặc tả). */
public enum SessionStatus implements StatusFlow<SessionStatus> {
    /** Admin đang tạo, xếp lô. */
    DRAFT,
    /** Catalogue công khai, đang nhận đăng ký. */
    PUBLISHED,
    /** Dời lịch, mở lại đăng ký. */
    POSTPONED,
    /** Đủ người, chờ đến giờ. */
    CONFIRMED,
    /** Đang chạy từng lô. */
    LIVE,
    /** Tạm dừng (sự cố kỹ thuật). */
    PAUSED,
    /** Đã chạy hết lô, có kết quả. */
    ENDED,
    /** Huỷ, đã hoàn cọc. */
    CANCELLED;

    @Override
    public Set<SessionStatus> nextStates() {
        return switch (this) {
            case DRAFT -> EnumSet.of(PUBLISHED, CANCELLED);
            case PUBLISHED -> EnumSet.of(CONFIRMED, POSTPONED, CANCELLED);
            case POSTPONED -> EnumSet.of(PUBLISHED, CANCELLED);
            case CONFIRMED -> EnumSet.of(LIVE, CANCELLED);
            case LIVE -> EnumSet.of(PAUSED, ENDED);
            case PAUSED -> EnumSet.of(LIVE, ENDED);
            case ENDED, CANCELLED -> EnumSet.noneOf(SessionStatus.class);
        };
    }

    /** Các trạng thái khách được xem catalogue. */
    public static final Set<SessionStatus> PUBLIC = EnumSet.of(PUBLISHED, POSTPONED, CONFIRMED, LIVE, PAUSED, ENDED);
}
