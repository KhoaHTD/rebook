# Banner sự kiện — danh sách tranh cần vẽ

Băng chuyền đầu trang Mua sách (`HeroCarousel`) dùng **một tranh cho mỗi sự kiện**. Tranh do người dùng tự vẽ (2D, hội họa, sang trọng, không linh vật); code chỉ gắn vào.

## Cách gắn

1. Xuất tranh thành **WebP**, đặt vào `assets/banners/` đúng tên ở bảng dưới.
2. Chạy lại app (hot restart). Không cần sửa code.
3. File thiếu thì thẻ tự rơi về nền gradient tạm, nên có thể thêm từng tranh một.

Chữ, giá, nút bấm là widget thật do app vẽ phía trên tranh — **không vẽ chữ vào tranh** (trừ chữ là một phần của cảnh vẽ, ví dụ biển hiệu).

## Thông số chung

| | |
|---|---|
| Kích thước | **2400 × 1600 px** (tỉ lệ 3:2) |
| Định dạng | WebP, chất lượng ~80, **dưới 400 KB** mỗi tranh |
| Màu | sRGB |
| Dùng cho | desktop (thẻ ~600×343, cắt bớt trên/dưới) và điện thoại (thẻ ~343×300, cắt bớt trái/phải) |

**Vùng an toàn:** mọi thứ quan trọng nằm trong **khung giữa 60% chiều ngang × 70% chiều dọc** (từ 20% đến 80% ngang, từ 15% đến 85% dọc). Phần ngoài có thể bị cắt.

**Vùng chữ:** trên desktop, khung kính chứa chữ nằm **góc dưới trái** (rộng ~340px trên thẻ 600px, tức ~57% bề ngang, cao ~35%). Trên điện thoại, khung chữ nằm **dải dưới cùng**, cao ~40%. Hãy để các vùng này **yên tĩnh** (ít chi tiết, trung tính hoặc tối hơn). App phủ thêm một lớp tối nhẹ từ trái sang phải (desktop) hoặc từ dưới lên (điện thoại).

**Chủ thể chính** (hình to nhất, điểm nhấn) đặt ở **nửa phải** trên desktop và **nửa trên** trên điện thoại.

## Danh sách tranh — nhóm A: băng chuyền đầu trang (đã gắn code)

Kích thước **2400 × 1600**. Chủ thể nửa phải, góc dưới trái yên tĩnh.

| # | File | Sự kiện | Gợi ý nội dung |
|---|---|---|---|
| 1 | `live.webp` | Đấu giá trực tiếp (có phiên LIVE) | Phòng đấu giá cổ điển: búa gỗ, màn nhung, ánh đèn rọi. Tông đêm, vàng đồng, đỏ rượu. |
| 2 | `picks.webp` | Được săn nhiều nhất | Chồng sách cao dưới ánh sáng ấm, bàn đọc buổi chiều. |
| 3 | `consign.webp` | Ký gửi đấu giá | Kho sách cổ, thùng gỗ, dây cột, nhãn thẩm định. |
| 4 | `new.webp` | Mới lên kệ | Thư viện ngập nắng, kệ cao, thang trượt. Tông xanh lá / vàng nhạt. |
| 5 | `shop.webp` | Mở shop | Con phố nhỏ có cửa hiệu sách, mái hiên, đèn chiều tối. |
| 6 | `rare.webp` | Sách hiếm & cổ | Trang sách cổ, bìa da, dấu sáp, bản đồ cũ, kính lúp. |

## Nhóm B: các khối trên trang chủ (đã gắn code)

Mỗi khối là **một khung bo góc rộng**, chữ và bìa sách nằm đè lên; thiếu file thì khối dùng nền bìa sách mờ như cũ. Vẽ **tranh nền thuần**, không có chữ; để vùng chữ ít chi tiết; tranh **không cần chủ thể rõ**, có thể thiên về không khí và màu sắc.

| # | File | Khối | Kích thước | Gợi ý nội dung |
|---|---|---|---|---|
| 7 | `auction-live.webp` | Thẻ phiên đang LIVE (to, bên trái) | 2000 × 1500 | Sân khấu đấu giá về đêm, ánh đèn nóng, đỏ rượu và vàng. |
| 8 | `auction-upcoming.webp` | Thẻ phiên sắp diễn ra | 1600 × 900 | Cùng không khí với #7 nhưng trước giờ mở màn: màn khép, đèn mờ, xanh đêm. |
| 9 | `auction-ended.webp` | Dòng phiên đã kết thúc | 1600 × 500 (dài, thấp) | Phòng đấu giá vắng sau buổi, ánh chiều, tông dịu. |
| 10 | `auctions-empty.webp` | Khối "chưa có phiên nào đang diễn ra" | 1600 × 900 | Phòng đấu giá yên tĩnh, ghế trống, ánh sáng một cửa sổ. |
| 11 | `cat-vn.webp` | Danh mục **Văn học Việt Nam** | 1600 × 1200 | Mái ngói, lũy tre, ngõ nhỏ, đèn dầu — không khí làng quê / phố cổ. |
| 12 | `cat-foreign.webp` | **Văn học nước ngoài** | 1600 × 1200 | Bản đồ cổ, tàu biển, thư tín đóng dấu, phương xa. |
| 13 | `cat-textbook.webp` | **Giáo trình đại học** | 1600 × 1200 | Giảng đường, bàn học gỗ, bảng phấn, ánh sáng buổi sáng. |
| 14 | `cat-skills.webp` | **Kỹ năng sống** | 1600 × 1200 | Bình minh, con đường, bàn làm việc gọn gàng. |
| 15 | `cat-kids.webp` | **Thiếu nhi** | 1600 × 1200 | Khu vườn đồ chơi, màu tươi, nét mềm. |
| 16 | `cat-rare.webp` | **Sách hiếm & cổ** | 1600 × 1200 | Phòng cổ, kệ da, đèn bàn xanh, giấy ố vàng. |
| 17 | `chart.webp` | Khối "Bảng xếp hạng tuần" | 2400 × 1000 | Sảnh triển lãm, ánh vàng ấm, khung tranh mờ phía xa. Phần trên sáng hơn (chữ đen đè lên). |
| 18 | `rare-spotlight.webp` | Khối "Sách hiếm" (nền tối, chữ trắng) | 2000 × 1400 | Căn phòng tối, ánh đèn rọi một chỗ, bụi sáng. |
| 19 | `editions.webp` | Khối "Cùng một cuốn, nhiều ấn bản" (nền sáng, chữ đen) | 2400 × 1000 | Dãy bìa/trang sách trải ngang trên bàn, ánh sáng tự nhiên. |
| 20 | `price-low.webp` | Thẻ "Dưới 50.000 ₫" | 1600 × 800 | Tông nhẹ, màu tươi: sách mỏng, ấm áp. |
| 21 | `price-mid.webp` | Thẻ "50.000 – 100.000 ₫" | 1600 × 800 | Tông trung, cân bằng. |
| 22 | `price-high.webp` | Thẻ "Trên 100.000 ₫" | 1600 × 800 | Tông sang, vàng đồng, da và gỗ. |
| 23 | `shops.webp` | Khối "Shop nổi bật" (chữ đen) | 2400 × 900 | Dãy cửa hiệu sách, mái hiên, đèn đường — nền sáng. |

Khối dùng chữ **trắng** (nền tối): #7, #8, #9, #10, #11–#16, #18, #20–#22. Khối dùng chữ **đen** (nền sáng): #17, #19, #23.

## Nhóm C: chưa gắn code, vẽ sẵn nếu muốn (mình sẽ gắn khi bạn gửi)

| File | Dùng ở đâu | Kích thước |
|---|---|---|
| `auth.webp` | Nền màn đăng nhập / đăng ký / quên mật khẩu / OTP (một tranh dùng chung) | 2400 × 1600 |
| `upcoming.webp` | Slide băng chuyền "phiên sắp diễn ra" (đếm ngược) | 2400 × 1600 |
| `season-tet.webp`, `season-school.webp` | Banner theo dịp (Tết, khai giảng) thay tạm cho slide thường | 2400 × 1600 |
| `header-auctions.webp` | Đầu trang Đấu giá | 2400 × 700 |
| `header-wallet.webp` | Đầu trang Ví | 2400 × 600 |
| `header-seller.webp` | Đầu trang Kênh người bán | 2400 × 700 |
| `consign-new.webp` | Màn tạo ký gửi | 2400 × 900 |
| `empty-cart.webp`, `empty-orders.webp`, `empty-search.webp`, `empty-notifications.webp` | Trạng thái rỗng (giỏ hàng, đơn mua, không có kết quả, không có thông báo) | 1200 × 800 mỗi tranh, chủ thể đơn giản, nhiều khoảng trống |
| `error-404.webp`, `error-network.webp` | Trang lỗi | 1200 × 800 |
| `landing-1.webp` … `landing-9.webp` | Chín cảnh trang giới thiệu web (hero, showcase, gateway, story, among, features, market, pricing, outro) làm nền thay thẻ bìa sách | 2400 × 1500 |

**Tổng cộng:** 6 tranh băng chuyền + 17 tranh khối trang chủ = **23 tranh đã có chỗ gắn**; thêm khoảng **27 tranh** ở nhóm C nếu muốn phủ hết app.

## Thứ tự nên vẽ

1. Băng chuyền (#1–#6): người dùng nhìn thấy đầu tiên.
2. Danh mục (#11–#16) và khối đấu giá (#7–#10).
3. Các khối còn lại của trang chủ (#17–#23).
4. Nhóm C, bắt đầu từ `auth` và các trạng thái rỗng.

## Gợi ý để tranh hợp với app

- App nền **trắng**, chữ đen, nút xanh `#0A6CFF`. Tranh nên có **tông thống nhất** giữa 6 cái (cùng độ bão hòa, cùng cách xử lý ánh sáng) để băng chuyền nhìn như một bộ.
- Tránh nền trắng tinh sát mép (thẻ có bo góc, mép trắng nhìn như thiếu nền); dùng mép màu hoặc có vignette nhẹ.
- Thử xem trước tranh ở kích thước thẻ thật (~600 px rộng) trước khi chốt: chi tiết nhỏ hơn ~12 px sẽ không đọc được.
