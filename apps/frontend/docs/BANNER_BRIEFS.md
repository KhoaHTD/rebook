# Brief vẽ banner ReBook — chi tiết từng tranh

Bổ sung cho [BANNERS.md](BANNERS.md) (tên file, kích thước, chỗ gắn). File này nói **vẽ như thế nào**.

## 0. Ngôn ngữ chung cho cả bộ

**Phong cách:** tranh 2D hội họa sang trọng — sơn dầu / gouache dày, **nét cọ nhìn thấy được**, hạt vải canvas rất nhẹ. Không 3D, không vector phẳng, không linh vật, không chữ trong tranh. Tham chiếu tinh thần: tranh phố cổ Hà Nội của Bùi Xuân Phái, ánh sáng nội thất của Hammershøi / Vermeer, không khí đêm của Hopper, minh hoạ sách thiếu nhi cổ.

**Ánh sáng:** luôn có **một nguồn sáng chủ đạo** (đèn bàn, cửa sổ, đèn sân khấu) tạo vùng sáng rõ và vùng tối sâu (chiaroscuro nhẹ). Không đều sáng toàn tranh.

**Bảng màu thống nhất** (mọi tranh lấy 3–4 màu từ đây, độ bão hoà vừa phải, hơi "cũ"):

| Tên | Hex gợi ý | Dùng cho |
|---|---|---|
| Nâu cacao | `#3B2418` | bóng tối, gỗ, da |
| Vàng đồng | `#C9923A` | ánh đèn, viền, điểm nhấn |
| Đỏ rượu | `#7A1F2B` | màn nhung, bìa da, đấu giá |
| Xanh thông | `#2F4A3A` | thư viện, cây, nền tĩnh |
| Xanh đêm | `#1E2A4A` | đêm, sân khấu, chiều sâu |
| Kem giấy | `#EFE3CC` | vùng sáng, trang sách |
| Hồng đất | `#C8786A` | điểm ấm nhỏ (tối đa 5% tranh) |

**Cấu trúc 3 lớp trong mọi tranh:** tiền cảnh (rất tối hoặc mờ, chiếm ~15% — tạo chiều sâu), trung cảnh (chủ thể, sắc nét nhất), hậu cảnh (mờ nhẹ, sáng hơn hoặc nhiều khói/bụi sáng).

**Người:** chỉ dùng **bóng người (silhouette) nhìn từ xa hoặc từ sau lưng**, không vẽ mặt (tránh vấn đề hình ảnh cá nhân, và dễ dùng lại).

**Không có:** chữ, logo, số, giá tiền, bìa sách có tên thật (bìa sách vẽ mặt gáy trơn hoặc hoạ tiết), watermark.

**Kỹ thuật bắt buộc:**
- Vùng chữ (ghi ở từng tranh) phải **yên tĩnh**: ít chi tiết, độ tương phản thấp, tông cùng nhóm để chữ đè lên đọc được.
- Mép tranh có **vignette tối nhẹ** (thẻ bo góc, mép sáng sẽ trông như hụt nền).
- Kiểm tra tranh thu nhỏ còn **~600 px rộng**: hình lớn vẫn đọc được, chi tiết nhỏ hơn ~12 px coi như không có.
- Xuất sRGB, WebP chất lượng ~80, dưới 400 KB (khối lớn dưới 600 KB).

## Nhóm A — băng chuyền (2400 × 1600, 3:2)

Quy tắc chung: **chủ thể nửa phải**, **góc dưới trái yên tĩnh** (chỗ khung chữ ~57% ngang × 35% dọc), mọi thứ quan trọng nằm trong khung giữa 60% × 70%.

**1. `live.webp` — Đấu giá trực tiếp**
Cảnh: một phòng đấu giá cổ điển nhìn từ phía khán giả. Trung cảnh bên phải: bục gỗ có chiếc búa gỗ nằm nghiêng và một chiếc bảng số cầm tay không có số. Hậu cảnh: màn nhung đỏ rượu khép nửa, bóng vài người ngồi hàng ghế xa. Ánh sáng: một chùm đèn nóng rọi từ trên xuống bục (vàng đồng), xung quanh chìm trong xanh đêm. Không khí: căng thẳng, trang trọng. Màu chủ đạo: đỏ rượu, xanh đêm, vàng đồng. Vùng chữ (trái dưới): ghế gỗ tối, mờ.

**2. `picks.webp` — Được săn nhiều nhất**
Cảnh: bàn đọc sách buổi chiều, chồng sách cao nghiêng, một cuốn mở úp, tách trà bốc khói. Cửa sổ lớn bên phải cho ánh nắng chiều chéo, bụi sáng bay trong tia nắng. Chủ thể: chồng sách ngay dưới tia nắng. Màu: cam ấm, nâu cacao, kem giấy; một mảng xanh thông ở rèm. Không khí: ấm, "ai cũng muốn cuốn này". Vùng chữ: góc bàn gỗ tối bên trái.

**3. `consign.webp` — Ký gửi đấu giá**
Cảnh: kho sách cổ về đêm. Thùng gỗ xếp chồng, một thùng mở nắp lộ ra những cuốn sách bọc giấy dó, sợi dây thừng, tấm thẻ treo trống (chưa có chữ). Đèn bàn kim loại xanh đậm chiếu xuống thùng. Hậu cảnh: kệ sắt cao mờ dần vào tối. Màu: xanh thông, nâu cacao, một vệt vàng đồng từ đèn. Không khí: tin cậy, kho báu được cất giữ. Vùng chữ: sàn kho tối bên trái.

**4. `new.webp` — Mới lên kệ**
Cảnh: thư viện ngập nắng buổi sáng. Hai tầng kệ gỗ cao, một chiếc thang trượt tựa kệ, một xe đẩy sách đầy sách mới còn nguyên bìa. Nắng tràn từ cửa sổ vòm phía phải, bụi sáng. Màu: xanh lá, vàng nhạt, kem giấy — **tranh sáng nhất bộ**, nhưng góc trái dưới vẫn tối hơn một bậc (bóng kệ). Không khí: tươi, bắt đầu một ngày.

**5. `shop.webp` — Mở shop**
Cảnh: một con phố nhỏ lúc chạng vạng, cửa hiệu sách nhỏ có mái hiên sọc, bảng treo trống, giá sách bày ngoài cửa, đèn dầu treo sáng. Vài bóng người đi xa. Sau lưng là dãy phố mờ xanh đêm, trời tím nhạt. Chủ thể: cửa hiệu ở nửa phải. Màu: xanh đêm, vàng đồng (đèn), một mảng đỏ rượu ở mái hiên. Không khí: ấm cúng, nhỏ nhắn, của một người.

**6. `rare.webp` — Sách hiếm & cổ**
Cảnh: bàn gỗ tối với một cuốn sách bìa da cũ mở ra, trang giấy ố vàng có hoạ tiết viền, bên cạnh là dấu sáp đỏ, kính lúp đồng, bản đồ cổ cuộn nhẹ. Một ngọn nến hoặc đèn dầu là nguồn sáng duy nhất. Tiền cảnh: mép bàn rất tối. Màu: nâu cacao, vàng đồng, đỏ rượu, kem giấy ố. Không khí: bí ẩn, quý giá. Vùng chữ: khoảng tối bên trái bàn.

## Nhóm B — khối trang chủ (tranh nền thuần)

Quy tắc chung: **không cần chủ thể**, thiên về không khí; **một nửa tranh sáng, một nửa tối** để chữ đè lên đọc được; tránh chi tiết nhỏ ở vùng chữ.

**7. `auction-live.webp` (2000 × 1500) — Thẻ phiên đang LIVE.** Cùng không khí với #1 nhưng **không có bục/búa** (thẻ đã có bìa sách và giá đè lên): sân khấu đêm, màn nhung đỏ rượu hai bên, chùm đèn rọi từ trên xuống giữa tranh, bụi sáng. Giữa tranh sáng vàng đồng, hai mép tối. Chữ trắng nên tranh tối vừa phải.

**8. `auction-upcoming.webp` (1600 × 900) — Phiên sắp diễn ra.** Phòng đấu giá **trước giờ mở màn**: màn khép gần kín, chỉ một khe sáng vàng ở giữa, đèn mờ, xanh đêm chiếm chủ đạo. Cảm giác chờ đợi. Rất tối, chữ trắng.

**9. `auction-ended.webp` (1600 × 500, dạng dải thấp) — Phiên đã kết thúc.** Cùng phòng đó **sau buổi**: ghế trống, ánh chiều vàng nhạt xiên qua cửa sổ, bụi lơ lửng, tông dịu và nhạt hơn. Dải ngang nên bố cục trải ngang, không có điểm nhấn.

**10. `auctions-empty.webp` (1600 × 900) — Chưa có phiên nào.** Một cửa sổ cao, một cột nắng rơi xuống chiếc ghế gỗ trống giữa phòng rộng. Rất nhiều khoảng trống, màu xám xanh và kem. Cảm giác yên tĩnh chứ không buồn.

**11. `cat-vn.webp` (1600 × 1200) — Văn học Việt Nam.** Ngõ phố cổ hoặc mái ngói rêu, một bóng người đội nón đi xa, đèn dầu trước hiên, lũy tre sau lưng. Màu đất: nâu, vàng, xanh rêu. Gợi nhớ tranh Bùi Xuân Phái nhưng màu ấm hơn.

**12. `cat-foreign.webp` — Văn học nước ngoài.** Bến cảng cổ: con tàu buồm nhìn xa, mặt biển xanh đêm, một chiếc rương và la bàn trên bến gỗ, bản đồ cổ cuộn. Màu: xanh đêm, vàng đồng, kem. Cảm giác "xa xôi".

**13. `cat-textbook.webp` — Giáo trình đại học.** Giảng đường gỗ buổi sáng: dãy bàn học gỗ bậc thang, bảng phấn xanh đậm ở xa còn dấu phấn mờ, cửa sổ lớn rọi nắng xiên. Màu: xanh thông, nâu, kem. Cảm giác nghiêm túc nhưng sáng.

**14. `cat-skills.webp` — Kỹ năng sống.** Bình minh trên một con đường đất dẫn lên đồi, vài bậc đá, một chiếc ba lô đặt bên đường. Trời cam hồng, sương mỏng. Màu: cam, hồng đất, xanh thông xa. Cảm giác "bắt đầu hành trình".

**15. `cat-kids.webp` — Thiếu nhi.** Khu vườn cổ tích: đồi cỏ mềm, cây to có tán tròn, chiếc xích đu, bướm, đom đóm; nét cọ mềm, màu tươi hơn bộ chung nhưng vẫn trong bảng màu. Không có trẻ em (chỉ chiếc xích đu rỗng, quả bóng).

**16. `cat-rare.webp` — Sách hiếm & cổ.** Góc phòng cổ: kệ da cao, quả địa cầu cổ, đèn bàn xanh (kiểu đèn thư viện), giấy ố. Tối, vàng đồng và xanh thông. Gần #6 nhưng **rộng hơn, ít chi tiết một vật** vì chỉ làm nền.

**17. `chart.webp` (2400 × 1000) — Bảng xếp hạng tuần (chữ đen).** Sảnh triển lãm sáng: sàn đá, những khung tranh vàng mờ ở xa, ánh vàng ấm từ trên. **Nửa trên sáng gần kem** (vì chữ đen đè lên), nửa dưới có chút vàng đồng và bóng. Không nhiều chi tiết ở giữa, nơi danh sách xếp hạng nằm.

**18. `rare-spotlight.webp` (2000 × 1400) — Khối Sách hiếm (chữ trắng).** Căn phòng gần như tối hoàn toàn, **một cột sáng** rọi từ trên xuống bên trái, bụi sáng, bóng kệ cổ mờ phía sau. Tối và nhiều khoảng yên tĩnh cho chữ trắng.

**19. `editions.webp` (2400 × 1000) — Cùng một cuốn, nhiều ấn bản (chữ đen).** Mặt bàn gỗ nhìn từ trên xuống, ánh sáng tự nhiên, hoạ tiết bìa/trang sách trải nhẹ thành dải ngang (không đọc được chữ). Nền sáng, tông kem và vàng nhạt, một vệt xanh thông.

**20. `price-low.webp` (1600 × 800) — Dưới 50.000 ₫.** Tông nhẹ nhất: kem giấy, vàng nhạt, xanh lá non; một chồng sách mỏng và cành lá. Chữ trắng nên cần đủ tối ở vùng chữ: dùng vignette nhẹ.

**21. `price-mid.webp` — 50.000–100.000 ₫.** Tông trung: xanh thông và nâu, ánh đèn bàn vừa phải, vài cuốn sách xếp gọn.

**22. `price-high.webp` — Trên 100.000 ₫.** Tông sang nhất: nâu cacao, vàng đồng, đỏ rượu; mặt da và gỗ bóng, ánh vàng.
*(Ba tranh #20–#22 nên là **một bộ**: cùng góc nhìn / cùng bàn, khác ánh sáng và độ sang. Người xem thấy mức giá tăng dần như độ "đậm" tăng dần.)*

**23. `shops.webp` (2400 × 900) — Shop nổi bật (chữ đen).** Dãy phố có nhiều cửa hiệu sách nối nhau, mái hiên đủ màu (đỏ rượu, xanh thông, vàng), nhìn **ban ngày, nắng nhẹ** (sáng, khác #5 chạng vạng). Phần nửa trên là trời và mái nhà kem sáng cho chữ đen.

## Nhóm C — vẽ sau (chưa gắn code)

**`auth.webp` (2400 × 1600)** — Hiên một cửa hiệu sách vào buổi tối: cửa gỗ hé mở, ánh vàng tràn ra, bậc thềm, vài chiếc lá rơi. Cảm giác "mời bước vào". Cửa ở nửa phải; nửa trái tối cho form đăng nhập.
**`upcoming.webp`** — Cùng không khí #8 nhưng bố cục như banner băng chuyền (chủ thể nửa phải: chiếc búa gỗ nằm trên bục dưới ánh đèn mờ).
**`season-tet.webp`** — Cành mai/đào nở bên cửa sổ, bàn trà, sách xếp, phong bao đỏ; đỏ rượu và vàng, ánh sáng sớm. **`season-school.webp`** — Sân trường lá bàng đỏ, hành lang giảng đường, chồng giáo trình; nắng thu.
**`header-auctions`, `header-wallet`, `header-seller`** (dạng dải 2400 × 600–700) — Cắt từ cùng thế giới của #1, #10, #5: dải ngang, không điểm nhấn, tông dịu để tiêu đề trang đè lên.
**`consign-new.webp`** — Bàn thẩm định: kính lúp, găng tay trắng, cuộn băng dán giấy, sách đang được bọc.
**`empty-*` và `error-*` (1200 × 800)** — Mỗi tranh một vật: giỏ mây rỗng (giỏ hàng), hộp thư trống (đơn mua), kính lúp trên bàn (không có kết quả), chuông nhỏ (thông báo), cuốn sách rách gáy (404), ổ cắm lỏng dây (lỗi mạng). Nhiều khoảng trống, nền kem.
**`landing-1…9` (2400 × 1500)** — Chín cảnh của một **hành trình trong một ngày ở chợ sách**: sáng sớm trước cửa → vào hiệu → kệ → phiên đấu giá → quầy ký gửi → phố đêm. Liền mạch về ánh sáng (từ sáng sớm đến đêm) để cuộn trang như đi hết một ngày.

## Quy trình đề xuất

1. Vẽ **một tranh mẫu** (khuyên: #2 hoặc #6), gửi để chốt phong cách.
2. Làm cả **bộ A** trước, cùng bảng màu.
3. Làm khối B theo nhóm: đấu giá (#7–#10), danh mục (#11–#16), còn lại (#17–#23).
4. Đặt file vào `assets/banners/`, báo mình để kiểm tra trên cả desktop và điện thoại.
