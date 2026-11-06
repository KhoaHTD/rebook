package com.rebook.common;

/**
 * Chuẩn hoá và kiểm ISBN (docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần C BR-2.2, BR-2.3).
 * Bỏ dấu gạch / khoảng trắng; ISBN-10 đổi sang ISBN-13 (thêm 978, tính lại số kiểm tra) để lưu và tìm kiếm thống nhất.
 */
public final class Isbn {

    private Isbn() {
    }

    /** Rỗng → null; hợp lệ → ISBN-13; sai → {@code INVALID_ISBN}. */
    public static String normalize(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String v = toIsbn13(raw);
        if (v == null) {
            throw ApiException.badRequest("INVALID_ISBN", "ISBN không hợp lệ (sai số kiểm tra hoặc sai độ dài)");
        }
        return v;
    }

    /** ISBN-13 nếu chuỗi là một ISBN hợp lệ, ngược lại null (dùng cho ô tìm kiếm). */
    public static String toIsbn13(String raw) {
        if (raw == null) {
            return null;
        }
        String s = raw.replaceAll("[\\s-]", "").toUpperCase();
        if (s.matches("\\d{9}[\\dX]")) {
            int sum = 0;
            for (int i = 0; i < 10; i++) {
                int d = s.charAt(i) == 'X' ? 10 : s.charAt(i) - '0';
                sum += d * (10 - i);
            }
            if (sum % 11 != 0) {
                return null;
            }
            String body = "978" + s.substring(0, 9);
            return body + check13(body);
        }
        if (s.matches("97[89]\\d{10}")) {
            return check13(s.substring(0, 12)) == s.charAt(12) - '0' ? s : null;
        }
        return null;
    }

    private static int check13(String first12) {
        int sum = 0;
        for (int i = 0; i < 12; i++) {
            sum += (first12.charAt(i) - '0') * (i % 2 == 0 ? 1 : 3);
        }
        return (10 - sum % 10) % 10;
    }
}
