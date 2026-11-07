# Banner sự kiện (trang chủ)

Tranh banner nằm ở `assets/banners/<tên>.jpg` và đã được vẽ xong. Code (`HeroCarousel`, `home_blocks*.dart`) gọi tranh theo tên, **thiếu file thì thẻ tự rơi về nền bìa sách mờ**, nên thay hay bỏ từng tranh đều không làm vỡ app.

| Tên file | Dùng ở |
|---|---|
| `live`, `picks`, `consign`, `new`, `shop`, `rare` | băng chuyền đầu trang (`HeroCarousel`): phiên LIVE, gợi ý, ký gửi, mới lên kệ, mở shop, sách hiếm |
| `cat-vn`, `cat-foreign`, `cat-textbook`, `cat-skills`, `cat-kids`, `cat-rare` | mosaic danh mục trang chủ (`_categoryArt` trong `home_blocks_b.dart`, khớp theo mã danh mục gốc `c1`, `c2`, `c3`, `c5`, `c6`, `c7`) |

Các file còn lại trong thư mục (`upcoming`, `season-school`, `season-tet`, `auth`) hiện **chưa được code gọi tới**: để dành, xoá được nếu muốn gọn.

## Thay hoặc thêm tranh

1. Xuất tranh thành **JPG**, đặt vào `assets/banners/` đúng tên ở bảng trên (tranh mới cần thêm tên thì khai báo ở `hero_carousel.dart` / `home_blocks*.dart`).
2. Chạy lại app (hot restart).

Chữ, giá, nút bấm là widget thật do app vẽ phía trên tranh: **không vẽ chữ vào tranh** (trừ chữ là một phần của cảnh vẽ, ví dụ biển hiệu).
