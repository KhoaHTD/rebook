# Tranh cần vẽ cho ReBook

Chỉ những chỗ **hình ảnh thật sự làm giao diện đẹp hơn**; các màn dữ liệu (giỏ hàng, ví, đơn hàng, quản trị…) giữ sạch, không ghép ảnh. Tranh đặt trong `assets/banners/` đúng tên, định dạng **WebP**, dưới 400 KB, sRGB. Thiếu file thì chỗ đó tự dùng nền tạm. **Không vẽ chữ vào tranh** (chữ, giá, nút do app vẽ).

## Nhóm 1 — Băng chuyền đầu trang chủ (6 tranh, 2400 × 1600)

Thẻ rộng ~600 px trên desktop, ~85% màn hình trên điện thoại; tranh phủ kín thẻ, cắt theo màn hình. Chủ thể quan trọng trong **khung giữa 60% ngang × 70% dọc**. Chữ chỉ hiện khi **rê chuột** (thẻ trắng góc dưới trái), nên không cần chừa chỗ chữ; trên điện thoại chỉ hiện tranh, chạm để mở.

| File | Banner | Bấm vào thì đi đâu |
|---|---|---|
| `live.webp` | Đấu giá trực tiếp (chỉ hiện khi có phiên LIVE; có thể 2 thẻ cùng tranh này) | phòng đấu giá |
| `picks.webp` | Những cuốn được săn nhiều nhất | trang tìm kiếm |
| `consign.webp` | Ký gửi đấu giá | màn tạo ký gửi |
| `new.webp` | Mới lên kệ | trang tìm kiếm |
| `shop.webp` | Mở shop (dành cho người bán) | màn mở shop |
| `rare.webp` | Sách hiếm & cổ | trang tìm kiếm |

## Nhóm 2 — Các khối trang chủ (9 tranh)

Mỗi tranh là **nền của một khung bo góc**, bìa sách và chữ nằm đè lên. Vẽ không khí và màu, không cần chủ thể rõ ràng; để một nửa tranh yên tĩnh cho chữ.

| File | Gắn ở đâu | Dùng như thế nào | Kích thước |
|---|---|---|---|
| `auction-live.webp` | Thẻ lớn "phiên đang LIVE", nửa trái khối Đấu giá | Nền thẻ, đè lên là bìa lô hiện tại, giá và nút vào phòng; chữ trắng nên tranh **tối** | 2000 × 1500 |
| `auction-upcoming.webp` | Thẻ "phiên sắp diễn ra" (cột phải khối Đấu giá, 1–2 thẻ cùng tranh) | Nền thẻ thấp và dài (~2.4:1), đè lên là tên phiên + đồng hồ đếm ngược; chữ trắng, tranh **tối** | 2000 × 830 |
| `rare-spotlight.webp` | Khối "Sách hiếm" (nền tối, 1 cuốn nổi bật) | Nền cả khối, đè lên là bìa cuốn đắt nhất + giá + nút; chữ trắng, tranh **tối**, chủ thể nghiêng về bên phải | 2400 × 1200 |
| `cat-vn.webp` | Ô danh mục **Văn học Việt Nam** (ô to, ngang) | Nền ô, đè lên là tên danh mục + quạt 3 bìa sách; chữ trắng | 2000 × 870 |
| `cat-rare.webp` | Ô danh mục **Sách hiếm & cổ** (ô to, ngang) | như trên | 2000 × 870 |
| `cat-foreign.webp` | Ô danh mục **Văn học nước ngoài** (ô nhỏ, gần vuông) | như trên | 1200 × 1100 |
| `cat-textbook.webp` | Ô danh mục **Giáo trình đại học** | như trên | 1200 × 1100 |
| `cat-skills.webp` | Ô danh mục **Kỹ năng sống** | như trên | 1200 × 1100 |
| `cat-kids.webp` | Ô danh mục **Thiếu nhi** | như trên | 1200 × 1100 |

(Ô to hay nhỏ phụ thuộc thứ tự danh mục; ô thứ nhất và cuối của lưới là ô to, nên `cat-vn` và `cat-rare` là hai tranh ngang. Chủ thể đặt giữa tranh để cắt thế nào cũng còn.)

## Nhóm 3 — Màn đăng nhập (1 tranh)

| File | Gắn ở đâu | Dùng như thế nào | Kích thước |
|---|---|---|---|
| `auth.webp` | Đăng nhập, đăng ký, quên mật khẩu, OTP (một tranh dùng chung) | Desktop: nửa trái màn hình là tranh, nửa phải là form. Điện thoại: dải tranh phía trên form (cao ~30% màn hình) | 2400 × 1600 |

**Chưa gắn code** — vẽ xong báo mình gắn.

## Tuỳ chọn (không bắt buộc)

| File | Dùng khi nào | Kích thước |
|---|---|---|
| `upcoming.webp` | Slide băng chuyền khi có phiên sắp mở | 2400 × 1600 |
| `season-tet.webp` | Banner dịp Tết, thay tạm một slide thường | 2400 × 1600 |
| `season-school.webp` | Banner khai giảng / mùa giáo trình | 2400 × 1600 |

## Không cần ảnh (cố ý bỏ)

Giỏ hàng, đơn mua, ví, kênh người bán, tạo ký gửi, tìm kiếm, thông báo, trạng thái rỗng, trang lỗi, bảng xếp hạng, "cùng một cuốn nhiều ấn bản", thẻ giá, khối shop nổi bật, dòng phiên đã kết thúc, chín cảnh trang giới thiệu web (vẫn dùng bìa sách thật). Những chỗ này nhiều chữ và số, thêm ảnh làm rối.

**Tổng: 16 tranh bắt buộc** (6 + 9 + 1), **3 tranh tuỳ chọn**.

## Hợp với app

App nền **trắng**, chữ đen, nút đen. Giữ **tông thống nhất** giữa các tranh (cùng độ bão hoà, cách xử lý ánh sáng) để băng chuyền và các khối trông như một bộ. Mép tranh nên có màu hoặc vignette nhẹ, tránh nền trắng tinh sát mép vì thẻ bo góc sẽ nhìn như thiếu nền. Xem thử ở kích thước thẻ thật (~600 px rộng) trước khi chốt.
