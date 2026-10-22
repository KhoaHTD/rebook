package com.rebook.catalog;

/** Thang tình trạng sách chuẩn (bắt buộc khi đăng bán). */
public enum ConditionGrade {
    /** Mới: chưa đọc, còn nguyên. */
    NEW,
    /** Như mới: đã đọc, không dấu vết. */
    LIKE_NEW,
    /** Tốt: dấu hiệu dùng nhẹ, không ghi chú. */
    VERY_GOOD,
    /** Khá: có ghi chú / gấp góc / ố vàng nhẹ, đủ trang. */
    GOOD,
    /** Trung bình: hư hại rõ, vẫn đọc được. */
    ACCEPTABLE
}
