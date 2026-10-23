# Ảnh cần làm (danh sách rút gọn) + prompt làm hàng loạt

Nguyên tắc: **chỉ làm ảnh ở chỗ ảnh mang lại giá trị** (băng chuyền, danh mục, đấu giá, đăng nhập). Chỗ nào chữ và bìa sách đã đẹp (giá, bảng xếp hạng, giỏ hàng, lỗi, trạng thái rỗng) thì **không** cần ảnh.

Tên file = tên trong `assets/banners/`, định dạng WebP (xuất từ PNG/JPG của AI rồi nén, dưới 400 KB mỗi ảnh).

## 1. Danh sách ảnh cần làm: 14 ảnh (+ 2 ảnh tuỳ chọn)

### Nhóm 1 — Băng chuyền đầu trang chủ (6 ảnh, 3:2, xuất 2400 × 1600)

Hiển thị: thẻ rộng ~600 × 343 px trên desktop, ~300 × 300 px trên điện thoại; ảnh phủ kín thẻ, **cắt tự động** theo khung. Người dùng thấy ảnh trước; rê chuột vào mới hiện thẻ chữ ở **góc dưới trái**. Vì vậy: vật thể chính nằm ở **giữa-phải**, góc dưới trái để trống (chỉ nền).

| File | Chỗ dùng | Vật thể trong ảnh |
|---|---|---|
| `live.webp` | Slide "Đấu giá trực tiếp" (hiện khi có phiên LIVE) **và** thẻ phiên LIVE lớn ở khối Đấu giá | Búa đấu giá gỗ trên đế gỗ tròn, cạnh một bảng số cầm tay (không có số) |
| `picks.webp` | Slide "Những cuốn được săn nhiều nhất" | Chồng 5 cuốn sách bìa cứng xếp cao, có một dải ruy băng đánh dấu trang |
| `consign.webp` | Slide "Ký gửi đấu giá" | Thùng gỗ mở nắp, có vài cuốn sách bên trong, một thẻ giấy kraft buộc dây (thẻ trống) |
| `new.webp` | Slide "Mới lên kệ" | Thang thư viện bằng gỗ dựa vào kệ tối giản có vài cuốn sách |
| `shop.webp` | Slide "Mở shop" | Túi vải tote đựng sách, một biển nhỏ treo (biển trống) và vài cuốn sách xếp cạnh |
| `rare.webp` | Slide "Sách hiếm & cổ" **và** khối Sách hiếm (nền tối) | Cuốn sách cổ bọc da có dấu sáp, kính lúp đồng cạnh bên, chiếc chìa khóa đồng |

### Nhóm 2 — Khối đấu giá trên trang chủ (1 ảnh, 3:2, xuất 2400 × 1600)

| File | Chỗ dùng | Vật thể |
|---|---|---|
| `upcoming.webp` | Thẻ "Phiên sắp diễn ra" ở khối Đấu giá (và có thể làm slide băng chuyền sau này) | Đồng hồ cát hoặc đồng hồ bỏ túi bằng đồng, một vé giấy (trống) tựa bên cạnh |

### Nhóm 3 — Ô danh mục trên trang chủ (6 ảnh, 4:3, xuất 1600 × 1200)

Hiển thị: mỗi danh mục là một ô bo góc, kích thước từ ~280 × 150 đến ~560 × 280 px; **tên danh mục nằm góc trên trái**, quạt bìa sách thật nằm **góc dưới phải** đè lên ảnh. Vì vậy vật thể đặt ở **giữa**, **hai góc trên-trái và dưới-phải để thoáng** (chỉ nền).

| File | Danh mục | Vật thể |
|---|---|---|
| `cat-vn.webp` | Văn học Việt Nam | Đèn dầu thủy tinh cổ, nón lá, một cuốn sách mở |
| `cat-foreign.webp` | Văn học nước ngoài | Quả địa cầu cổ, phong bì có tem, máy bay giấy |
| `cat-textbook.webp` | Giáo trình đại học | Chồng giáo trình dày, cây bút chì, một cái compa |
| `cat-skills.webp` | Kỹ năng sống | Chậu cây nhỏ đang nảy mầm, cuốn sổ tay mở, một chiếc đồng hồ báo thức |
| `cat-kids.webp` | Thiếu nhi | Khối gỗ xếp hình, thuyền giấy, sách tranh bìa cứng |
| `cat-rare.webp` | Sách hiếm & cổ | Bản đồ cổ cuộn lại, la bàn/sextant đồng, cuốn sách da cũ |

### Nhóm 4 — Đăng nhập (1 ảnh dọc, 4:5, xuất 1600 × 2000) — chưa gắn code, vẽ sẵn

| File | Chỗ dùng | Vật thể |
|---|---|---|
| `auth.webp` | Cột ảnh bên trái của màn Đăng nhập / Đăng ký (desktop); điện thoại hiện dải trên | Cuốn sách mở ra, chiếc chìa khóa đồng đặt ngang trang, ánh sáng hắt từ cửa sổ |

### Tuỳ chọn (làm sau nếu cần, 3:2, 2400 × 1600)

| File | Chỗ dùng | Vật thể |
|---|---|---|
| `season-tet.webp` | Banner dịp Tết thay tạm cho slide thường | Cành đào/mai, bao lì xì (trống), chồng sách |
| `season-school.webp` | Banner khai giảng | Chồng giáo trình, balo vải, cái bút |

**Tổng: 14 ảnh bắt buộc** (6 + 1 + 6 + 1 chưa gắn) và 2 ảnh tuỳ chọn.

### Đã bỏ khỏi danh sách (không cần ảnh)

- Giỏ hàng trống, đơn mua trống, không có kết quả, không có thông báo, 2 trang lỗi: giữ dạng biểu tượng + chữ + nút đen.
- 3 thẻ giá, khối Bảng xếp hạng, khối "Cùng một cuốn, nhiều ấn bản", khối Shop nổi bật, dòng phiên đã kết thúc, khối "chưa có phiên": nền trắng/bìa sách đủ đẹp.
- Đầu trang Đấu giá / Ví / Kênh người bán, màn Ký gửi, 9 cảnh trang giới thiệu: không ảnh.
- `auction-live` dùng lại `live.webp`; `rare-spotlight` dùng lại `rare.webp` (đổi tên khe trong code khi bạn báo).

---

## 2. Cách làm hàng loạt bằng một AI

1. Chọn **một ảnh tham chiếu** (ảnh giỏ hàng xanh cobalt – cam san hô bạn đã có là hợp nhất) và gắn vào AI.
2. Dán **PROMPT CHUNG** bên dưới.
3. Dán tiếp **DANH SÁCH VẬT THỂ** (mục 3). AI sinh lần lượt từng ảnh theo cùng một phong cách.
4. Nếu AI chỉ cho một ảnh mỗi lần, dùng lại prompt chung và đổi dòng vật thể ở cuối.

### PROMPT CHUNG (dán nguyên văn, tiếng Anh vì AI ảnh hiểu tốt hơn)

```
You are producing a SERIES of premium still-life product photographs for a used-book marketplace app. I attached ONE reference image. Use it ONLY as the STYLE reference: copy its rendering style, lighting, color grading, material quality, camera distance and background treatment. Do NOT copy its subject (the basket).

STYLE (must be identical in every image of the series):
- Premium studio still life, photographed (not illustrated, not 3D-cartoon), shot at a slight high angle, objects look physical and tactile, matte and satin finishes, subtle realistic shadows.
- Seamless warm greige / light taupe backdrop and floor (about #D8D0C6), soft diagonal window-light with gentle shadow stripes falling across the backdrop, soft bounce light, no harsh highlights.
- Restrained palette: backdrop greige + cobalt blue (about #1F3FBF) + coral orange (about #F0643C) as the only saturated accents, plus natural cream, kraft brown and warm wood tones. No other bright colors.
- Calm, minimal, high-end editorial mood. One hero object group per image, slightly off-center, generous empty space around it.
- Same camera, same light direction (from upper left), same color grade, same level of detail in every image.

STRICT RULES:
- NO text, NO letters, NO numbers, NO logos, NO watermarks anywhere (signs, tags, book spines and covers stay blank or abstract).
- NO people, NO hands, NO faces, NO animals.
- NO cartoon / vector / illustration look. No busy background, no clutter, no extra props beyond those listed.
- Keep the composition area described per image free of objects (it is reserved for UI text).

OUTPUT: one image per subject below, in the exact aspect ratio stated, ultra-high resolution, sharp focus on the hero objects, soft natural falloff in the background. Generate them one by one, keeping the style identical across the whole series.
```

---

## 3. DANH SÁCH VẬT THỂ (dán sau prompt chung; mỗi mục = một ảnh)

Mỗi mục ghi: tỉ lệ khung, vật thể, **vùng phải để trống** (chữ của app đè lên).

**Nhóm 1, khung 3:2 (2400 × 1600). Vật thể ở giữa-phải; để trống góc dưới-trái (khoảng 40% rộng × 35% cao) và mép ngoài.**

1. `live` — Aspect 3:2. A wooden auction gavel resting on a round wooden sound block, with a hand-held auction paddle (blank face, cobalt blue with a coral rim) leaning beside it. Hero group in the center-right; leave the lower-left corner empty.
2. `picks` — Aspect 3:2. A tall stack of five hardcover books in cobalt blue, coral, cream, kraft and dark green cloth bindings, blank spines, a coral ribbon bookmark hanging out of the top book. Hero group center-right; lower-left corner empty.
3. `consign` — Aspect 3:2. An open wooden crate with a few books resting inside, a kraft paper tag tied with coral string hanging over the edge (tag blank), a little packing paper. Hero group center-right; lower-left corner empty.
4. `new` — Aspect 3:2. A wooden rolling library ladder leaning against a minimal low bookshelf holding a few books in cobalt blue, coral and cream, spines blank. Hero group center-right; lower-left corner empty.
5. `shop` — Aspect 3:2. A canvas tote bag in cream with a coral handle holding a few books, a small blank hanging wooden sign tag, and two books stacked beside it. Hero group center-right; lower-left corner empty.
6. `rare` — Aspect 3:2. An antique leather-bound book with a red wax seal (no emblem), a brass magnifying glass and a small brass key lying beside it. Slightly warmer and moodier light than the others, same style. Hero group center-right; lower-left corner empty.

**Nhóm 2, khung 3:2 (2400 × 1600). Giống nhóm 1.**

7. `upcoming` — Aspect 3:2. A brass hourglass standing next to a blank paper ticket leaning on it, soft cobalt blue accent. Hero group center-right; lower-left corner empty.

**Nhóm 3, khung 4:3 (1600 × 1200). Vật thể ở GIỮA; để trống góc trên-trái và góc dưới-phải.**

8. `cat-vn` — Aspect 4:3. A vintage glass oil lamp, a Vietnamese conical leaf hat (nón lá) and an open book. Centered group; top-left and bottom-right corners empty.
9. `cat-foreign` — Aspect 4:3. An antique tabletop globe, an envelope with a blank stamp, and a folded paper airplane. Centered group; top-left and bottom-right corners empty.
10. `cat-textbook` — Aspect 4:3. A stack of thick textbooks, a sharpened pencil and a metal drawing compass. Centered group; top-left and bottom-right corners empty.
11. `cat-skills` — Aspect 4:3. A small sprouting plant in a ceramic cup, an open notebook with blank pages, and a small alarm clock. Centered group; top-left and bottom-right corners empty.
12. `cat-kids` — Aspect 4:3. Wooden building blocks (blank sides), a paper boat and a hardcover picture book with a blank cover. Centered group; top-left and bottom-right corners empty.
13. `cat-rare` — Aspect 4:3. A rolled antique map tied with string, a brass compass, and an old leather book. Centered group; top-left and bottom-right corners empty.

**Nhóm 4, khung dọc 4:5 (1600 × 2000).**

14. `auth` — Aspect 4:5 (portrait). An open book standing on a wooden surface with a brass key laid across the pages, soft light from a window falling diagonally. Hero group in the lower half; upper third calm.

**Tuỳ chọn (3:2):**

15. `season-tet` — Aspect 3:2. A blooming peach-blossom branch in a ceramic vase, a blank red envelope, a small stack of books. Lower-left corner empty.
16. `season-school` — Aspect 3:2. A stack of textbooks, a canvas backpack, a pen. Lower-left corner empty.

---

## 4. Sau khi có ảnh

- Xuất WebP, đặt vào `assets/banners/` đúng tên ở mục 1, rồi báo mình: mình sẽ gắn nốt `auth`, đổi khe `auction-live` → `live`, `rare-spotlight` → `rare`, và gắn lại các khe cho khớp danh sách rút gọn này.
- Nếu ảnh nào bị AI vẽ chữ hoặc người thì tạo lại ảnh đó (chữ trong ảnh sẽ chồng lên chữ của app).
- Kiểm tra cả 14 ảnh có **cùng hướng sáng, cùng màu nền** không: đây là thứ giữ cho băng chuyền nhìn như một bộ.
