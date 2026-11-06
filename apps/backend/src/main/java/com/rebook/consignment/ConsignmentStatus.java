package com.rebook.consignment;

import com.rebook.common.StatusFlow;

import java.util.EnumSet;
import java.util.Set;

/** Giai đoạn A–B: ký gửi → sơ duyệt → hẹn lịch → nhận sách → kiểm định → người bán quyết định. */
public enum ConsignmentStatus implements StatusFlow<ConsignmentStatus> {
    /** Người bán gửi yêu cầu, chờ Staff sơ duyệt (48h). */
    SUBMITTED,
    /** Được duyệt, chờ người bán đặt lịch mang sách tới. */
    APPROVED,
    /** Bị từ chối (sách phổ thông, giá trị thấp...). */
    REJECTED,
    /** Đã đặt lịch hẹn mang sách tới kho. */
    APPOINTMENT_BOOKED,
    /** Quá 7 ngày không mang sách tới. */
    EXPIRED,
    /** Kho đã nhận sách, chờ kiểm định. */
    RECEIVED,
    /** Không đạt kiểm định, người bán có 14 ngày đến nhận lại. */
    INSPECTION_FAILED,
    /** Đạt kiểm định, chờ người bán chấp nhận giá đề xuất. */
    AWAITING_SELLER,
    /** Người bán đồng ý hợp đồng ký gửi → đã tạo lô. */
    ACCEPTED,
    /** Người bán rút sách. */
    WITHDRAWN,
    /** Sách đã trả lại người bán. */
    RETURNED,
    /** Kho làm mất sách, sàn đã bồi thường (BR-4.2). */
    LOST;

    @Override
    public Set<ConsignmentStatus> nextStates() {
        return switch (this) {
            case SUBMITTED -> EnumSet.of(APPROVED, REJECTED, WITHDRAWN);
            case APPROVED -> EnumSet.of(APPOINTMENT_BOOKED, EXPIRED, WITHDRAWN);
            case APPOINTMENT_BOOKED -> EnumSet.of(RECEIVED, EXPIRED, WITHDRAWN);
            // RECEIVED → WITHDRAWN: kho làm hỏng sách trước kiểm định, trả lại người bán kèm bồi thường
            case RECEIVED -> EnumSet.of(INSPECTION_FAILED, AWAITING_SELLER, WITHDRAWN, LOST);
            case INSPECTION_FAILED -> EnumSet.of(RETURNED, LOST);
            case AWAITING_SELLER -> EnumSet.of(ACCEPTED, WITHDRAWN, LOST);
            case ACCEPTED -> EnumSet.of(RETURNED, LOST);
            case WITHDRAWN -> EnumSet.of(RETURNED, LOST);
            case REJECTED, EXPIRED, RETURNED, LOST -> EnumSet.noneOf(ConsignmentStatus.class);
        };
    }
}
