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

## Danh sách tranh

| # | File | Sự kiện | Khi nào hiện | Gợi ý nội dung tranh |
|---|---|---|---|---|
| 1 | `live.webp` | **Đấu giá trực tiếp** | Có phiên đang LIVE (hiện 1–2 thẻ, cùng một tranh) | Không khí phòng đấu giá cổ điển: búa gỗ, tấm màn nhung, ánh đèn rọi, bóng người ngồi xa. Tông đêm, vàng đồng và đỏ rượu. Căng thẳng nhưng sang. |
| 2 | `picks.webp` | **Được săn nhiều nhất / bảng xếp hạng** | Luôn hiện | Chồng sách cao dưới ánh sáng ấm, hoặc bàn đọc sách buổi chiều. Ấm, đông đúc, náo nhiệt vừa phải. |
| 3 | `consign.webp` | **Ký gửi đấu giá** | Luôn hiện | Kho sách cổ, thùng gỗ, dây cột, nhãn thẩm định, ánh đèn bàn. Cảm giác tin cậy, cất giữ, kho báu. |
| 4 | `new.webp` | **Mới lên kệ** | Có sách mới | Thư viện ngập nắng, kệ cao, thang trượt, bụi sáng. Tươi, sáng, hy vọng (tông xanh lá hoặc vàng nhạt). |
| 5 | `shop.webp` | **Mở shop** | Luôn hiện | Con phố nhỏ với cửa hiệu sách, mái hiên, bảng treo, ánh đèn buổi chiều tối. Ấm cúng, nhỏ nhắn, của người bán. |
| 6 | `rare.webp` | **Sách hiếm & cổ** | Luôn hiện | Trang sách cổ, bìa da, dấu sáp, bản đồ cũ, kính lúp. Tông nâu, đỏ rượu, vàng cổ; giấy ố vàng, chi tiết kỹ. |

## Sẽ cần thêm (chưa có trong app)

Báo trước để vẽ cùng phong cách; chưa gắn code, khi nào cần mình sẽ thêm khe tương ứng:

| File | Sự kiện | Ghi chú |
|---|---|---|
| `upcoming.webp` | Phiên sắp diễn ra (đếm ngược) | Cùng không khí với `live`, nhưng trước giờ mở màn: màn khép, đèn mờ. |
| `season-tet.webp` | Tết / mùa lễ | Tông đỏ vàng, hoa mai/đào, sách và lì xì. Thay thế tạm thời cho banner thường trong dịp lễ. |
| `season-school.webp` | Khai giảng / mùa giáo trình | Giảng đường, sách giáo trình, lá bàng. Mùa mua bán giáo trình. |
| `empty.webp` | Trạng thái rỗng (giỏ hàng, không có kết quả) | Nhỏ gọn hơn: 1200 × 800, một chủ thể đơn giản, nhiều khoảng trống. |

## Gợi ý để tranh hợp với app

- App nền **trắng**, chữ đen, nút xanh `#0A6CFF`. Tranh nên có **tông thống nhất** giữa 6 cái (cùng độ bão hòa, cùng cách xử lý ánh sáng) để băng chuyền nhìn như một bộ.
- Tránh nền trắng tinh sát mép (thẻ có bo góc, mép trắng nhìn như thiếu nền); dùng mép màu hoặc có vignette nhẹ.
- Thử xem trước tranh ở kích thước thẻ thật (~600 px rộng) trước khi chốt: chi tiết nhỏ hơn ~12 px sẽ không đọc được.
