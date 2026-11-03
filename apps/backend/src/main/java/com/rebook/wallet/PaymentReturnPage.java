package com.rebook.wallet;

import org.springframework.web.util.HtmlUtils;

/**
 * Trang trình duyệt thấy sau khi thanh toán ZaloPay. App (đang mở ở tab / màn khác) tự hỏi lại trạng thái thanh toán,
 * nên trang này chỉ báo kết quả, có nút quay về app và tự chuyển về màn kết quả trong app (bản web).
 */
final class PaymentReturnPage {

    private PaymentReturnPage() {
    }

    /** [appUrl] khác rỗng và biết mã thanh toán: thêm nút "Quay lại ReBook" và tự chuyển về app sau 3 giây. */
    static String render(Payment.Status status, String paymentCode, String appUrl) {
        boolean success = status == Payment.Status.SUCCESS;
        boolean pending = status == Payment.Status.PENDING;
        String title = success ? "Thanh toán thành công" : pending ? "Đang chờ xác nhận" : "Thanh toán không thành công";
        String message = success
                ? "ReBook đã nhận được tiền. Bạn có thể đóng trang này và quay lại ứng dụng."
                : pending
                ? "ZaloPay chưa xác nhận giao dịch. Quay lại ứng dụng, kết quả sẽ tự cập nhật."
                : "Giao dịch chưa hoàn tất. Quay lại ứng dụng để thử lại hoặc chọn cách thanh toán khác.";
        String color = success ? "#1a7f37" : pending ? "#b26a00" : "#c62828";
        String icon = success ? "&#10003;" : pending ? "&#8987;" : "&#10005;";
        String code = paymentCode == null ? "" : "<p class=\"code\">Mã thanh toán: " + HtmlUtils.htmlEscape(paymentCode) + "</p>";
        String back = "";
        String redirect = "";
        if (appUrl != null && !appUrl.isBlank() && paymentCode != null && paymentCode.matches("[A-Za-z0-9_-]+")) {
            String base = appUrl.endsWith("/") ? appUrl.substring(0, appUrl.length() - 1) : appUrl;
            String target = HtmlUtils.htmlEscape(base + "/home/payments/" + paymentCode);
            back = "<a class=\"btn\" href=\"" + target + "\">Quay lại ReBook</a>";
            redirect = "<meta http-equiv=\"refresh\" content=\"3;url=" + target + "\">";
        }
        return """
                <!doctype html>
                <html lang="vi">
                <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>%s · ReBook</title>
                %s
                <style>
                  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
                         background: #ebeff4; font-family: -apple-system, "Segoe UI", Roboto, sans-serif; color: #1c1c1e; }
                  .card { background: #fff; border-radius: 20px; padding: 32px 28px; max-width: 360px; margin: 16px;
                          text-align: center; box-shadow: 0 8px 30px rgba(0,0,0,.08); }
                  .icon { width: 64px; height: 64px; border-radius: 50%%; margin: 0 auto 16px; display: flex;
                          align-items: center; justify-content: center; font-size: 32px; color: #fff; background: %s; }
                  h1 { font-size: 22px; margin: 0 0 8px; }
                  p { margin: 0 0 8px; line-height: 1.5; color: #48484a; }
                  .code { font-size: 13px; color: #8e8e93; }
                  .btn { display: inline-block; margin-top: 16px; padding: 12px 24px; border-radius: 999px;
                         background: #1c1c1e; color: #fff; text-decoration: none; font-weight: 600; }
                </style>
                </head>
                <body>
                <div class="card">
                  <div class="icon">%s</div>
                  <h1>%s</h1>
                  <p>%s</p>
                  %s
                  %s
                </div>
                </body>
                </html>
                """.formatted(title, redirect, color, icon, title, message, code, back);
    }
}
