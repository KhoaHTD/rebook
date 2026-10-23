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

1. Mở một cuộc trò chuyện mới với AI tạo ảnh (hỗ trợ ảnh tham chiếu: ChatGPT/DALL·E, Midjourney `--sref`, Gemini, Firefly...).
2. **Gắn một ảnh tham chiếu duy nhất** (ảnh giỏ hàng xanh cobalt – cam san hô của bạn) và dán **PROMPT CHUNG** bên dưới. Ở bước này đừng yêu cầu AI tạo ảnh; chỉ để nó đọc và hiểu bối cảnh + phong cách.
3. Sau đó dán **từng mục** ở phần 3 (mỗi mục là một ảnh, tự đủ ý), lần lượt, trong **cùng cuộc trò chuyện** để AI giữ cùng phong cách. Nếu AI cho tạo nhiều ảnh một lượt thì dán cả nhóm.
4. Ảnh nào lệch phong cách (khác nền, khác ánh sáng, có chữ) thì bảo AI tạo lại riêng ảnh đó và nhắc "giống ảnh tham chiếu, đúng quy tắc trong prompt chung".

### PROMPT CHUNG (dán nguyên văn, tiếng Anh vì AI ảnh hiểu tốt hơn)

```
CONTEXT - please read carefully before generating anything.

I am designing the visuals of a mobile + web marketplace app for second-hand books and book auctions ("ReBook"). I need a SERIES of about 15 photographs that will be used as banner and card backgrounds inside the app. The app itself is clean, white and minimal; the photos are the only artistic, premium element, so they must look like they come from the same high-end editorial photo shoot.

I have attached ONE reference image. It is a style reference ONLY.
- COPY from it: the photographic rendering, the lighting, the soft diagonal window-light shadows, the greige seamless backdrop, the satin/matte material finish, the cobalt-blue + coral-orange color accents, the camera angle and distance, the calm minimal mood.
- DO NOT COPY from it: the subject (the basket). Each image below has its own subject.

HOW THE PHOTOS WILL BE USED (this is why the rules below matter):
- Each photo is placed as a full-bleed background inside a rounded rectangle (banner or card) and is automatically CROPPED to different shapes: wide on desktop, nearly square on phones. So the hero objects must sit well inside the frame, never touching the edges, and the background around them must continue smoothly in all directions (a seamless backdrop that can be cropped anywhere).
- The app then draws its OWN text, buttons and book covers on top of the photo. So specific regions of each image must be left EMPTY (only the clean backdrop, no objects, no strong shadows). Each image description below says which region to keep empty. This is mandatory.
- Any text baked into the photo would collide with the app's text, so the photos must contain NO text at all.

THE STYLE (identical in every image of the series):
1. Medium: premium studio still-life PHOTOGRAPH, hyper-realistic, as if shot on a 100 mm macro-style lens at f/8, sharp on the hero objects, soft natural falloff in the background. Not an illustration, not a 3D cartoon, not a vector, not a painting.
2. Camera: slightly elevated three-quarter view (about 20-30 degrees above the table), the same distance and perspective in every image. Objects are physical and tactile with believable weight, contact shadows and tiny imperfections.
3. Light: a single soft window light coming from the UPPER LEFT, casting long, soft, diagonal shadow stripes (like venetian-blind or window-frame shadows) across the backdrop and the floor, plus gentle bounce light so shadows are never black. Never harsh, never flashy. Same direction and softness in every image.
4. Backdrop: a seamless warm greige / light taupe paper-like wall and floor with no visible horizon line and no texture other than subtle paper grain, color about #D8D0C6 (slightly lighter toward the upper right, slightly darker toward the lower left).
5. Palette: the backdrop greige, plus cobalt blue (about #1F3FBF) and coral orange (about #F0643C) as the ONLY saturated accents, plus natural supporting tones: cream (#F3EBDD), kraft brown, warm natural wood, brass / antique gold, soft off-white. No other bright or neon colors. Keep the color count small and restrained. Blue and coral should appear in every image in small, deliberate amounts.
6. Materials: matte cloth book bindings, satin lacquer, brushed brass, raw wood, kraft paper, ceramic. Surfaces look premium and clean.
7. Composition: ONE hero group of objects per image, calm and sculptural, placed off-center in the position described, with generous negative space around it. Minimal and uncluttered; no extra props beyond those listed.
8. Mood: calm, refined, editorial, quietly luxurious, a little warm and nostalgic (it is a book marketplace). Not busy, not playful, not childish (even for the kids theme, stay refined).

HARD RULES (never break them):
- NO text, letters, numbers, logos, watermarks or readable symbols anywhere. Book spines, covers, tags, signs, tickets, paddles, envelopes and wax seals must be blank or carry only abstract non-letter marks.
- NO people, NO hands, NO fingers, NO faces, NO animals, NO silhouettes of people.
- NO cartoon, vector, flat-illustration, painterly, glossy-CGI or AI "dreamy glow" look. No lens flare, no bokeh balls, no fog, no particles, no sparkles.
- NO busy backgrounds, shelves full of clutter, patterned wallpaper, windows or room interiors. The backdrop stays an empty seamless greige surface.
- NO strong vignette and no dark corners. Keep the edges of the image clean and even so the photo can be cropped.
- Keep the SAME style, light direction, backdrop color and camera in every image I ask for. If an image must be regenerated, match the reference again.

OUTPUT FORMAT: for every subject I send, produce ONE image at the exact aspect ratio I state, ultra-high resolution (at least 2400 px on the long side), no borders, no frames, no captions.

Reply "ready" and wait for the first subject.
```

---

## 3. CÁC ẢNH CẦN TẠO (dán từng mục sau khi AI trả lời "ready")

Mỗi mục tự đủ ý: có tỉ lệ khung, vật thể chi tiết, cách xếp, vùng phải để trống và lý do. Dán nguyên mục, không cần sửa.

### Nhóm 1 — Băng chuyền đầu trang chủ (khung 3:2)

> Cả 6 ảnh nhóm này dùng chung quy tắc xếp: **vật thể nằm giữa-phải**, cách mép phải và mép trên ít nhất 12% khung. **Góc dưới-trái (khoảng 45% chiều rộng × 40% chiều cao) phải để trống hoàn toàn**, vì app vẽ một thẻ chữ trắng ở đó khi người dùng rê chuột. Phần còn lại của nền để thoáng và liền mạch.

**1. `live` — Đấu giá trực tiếp**
```
SUBJECT 1 of the series - filename "live". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose in the app: the banner for a LIVE book auction happening right now. It must feel like the dramatic, high-value moment of an auction, but stay calm and premium.

Hero objects: a solid wooden auction gavel (warm walnut, matte, rounded hammer head with a brass band) resting at a slight diagonal on a round wooden sound block; beside it, standing upright and leaning slightly, a hand-held bidding paddle: a round cobalt-blue lacquered disc with a coral-orange rim and a short natural-wood handle. The paddle face is completely blank (no number, no text). No other props.

Placement: the group sits center-right of the frame, occupying about 40% of the frame width and 55% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% of the width by 40% of the height) COMPLETELY EMPTY: only the smooth greige backdrop and the soft diagonal window-light stripes.

Light and mood: the same window light from the upper left; long soft shadow of the gavel and paddle falling to the lower right. Slightly more contrast and depth than the others to suggest tension, but never dark. No text anywhere.
```

**2. `picks` — Được săn nhiều nhất**
```
SUBJECT 2 of the series - filename "picks". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose: the banner for "the most hunted books this week" (popular, sought-after books).

Hero objects: a tall, slightly staggered stack of five hardcover books lying flat, bound in cloth: cobalt blue, coral orange, cream, kraft tan and deep forest green. The spines face the camera and are completely blank (no title text, no emblem), with tiny natural imperfections such as slightly worn corners. A coral-orange silk ribbon bookmark hangs out of the top book and drapes down the stack. The books are not perfectly aligned; each is shifted a few centimeters for a natural look.

Placement: the stack sits center-right, about 30% of the frame width and 65% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% width x 40% height) COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, long soft diagonal shadow falling to the right and down. Warm, inviting, abundant but tidy. No text anywhere.
```

**3. `consign` — Ký gửi đấu giá**
```
SUBJECT 3 of the series - filename "consign". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose: the banner for "consign your valuable books to us for auction" (trust, safe keeping, appraisal).

Hero objects: a rustic open wooden crate (light pine, simple slats, with its lid leaning against the crate) holding four or five books standing and lying inside, with some crumpled kraft packing paper around them. A kraft paper hang-tag tied with a coral-orange string is draped over the front edge of the crate; the tag is completely blank. One book inside has a cobalt-blue cloth cover so the accent color appears. No other props.

Placement: the crate sits center-right, about 40% of the frame width and 50% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left, soft diagonal shadows across the floor and the crate. Trustworthy, careful, a quiet sense of "kept safe". No text anywhere.
```

**4. `new` — Mới lên kệ**
```
SUBJECT 4 of the series - filename "new". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose: the banner for "new arrivals on the shelf" (fresh, bright, hopeful).

Hero objects: a minimal low wooden bookshelf (two shelves, simple light oak) holding about eight books in cobalt blue, coral orange, cream and kraft with blank spines, some standing and some leaning; a light wooden rolling library ladder with a few steps leans against the shelf. The scene is small and sculptural, like a miniature set, not a full library.

Placement: the shelf and ladder sit center-right, about 42% of the frame width and 70% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left, long soft diagonal shadows of the ladder rungs falling across the backdrop. Slightly brighter and airier than the other images, still the same grade. No text anywhere.
```

**5. `shop` — Mở shop**
```
SUBJECT 5 of the series - filename "shop". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose: the banner inviting people to open their own small bookshop on the app (small business, friendly, handmade).

Hero objects: a cream canvas tote bag with coral-orange cotton handles, standing upright and holding four books (cobalt blue, kraft, cream, coral, blank spines) sticking out of the top; next to it a small blank wooden hanging sign (a plain rectangular wooden plank on a short string, no text) leaning against the bag; two more books stacked in front. Everything is simple and handmade-looking.

Placement: the group sits center-right, about 38% of the frame width and 60% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left, soft diagonal shadows. Friendly, small-scale, optimistic. No text anywhere.
```

**6. `rare` — Sách hiếm & cổ**
```
SUBJECT 6 of the series - filename "rare". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose: the banner for rare and antique books (precious, old, collectible). It is also reused as the background of a dark "rare book" block, so it can be a touch warmer and moodier than the others while staying in the same family.

Hero objects: an antique leather-bound book (aged cognac-brown leather, gilded page edges, blind-embossed ornamental border with no letters on the cover) lying slightly angled, a red wax seal (no emblem, just an abstract round impression) on a faded ribbon closing it; beside the book a brass magnifying glass with a wooden handle, and a small antique brass key lying on the surface. A faint cobalt-blue silk ribbon peeks out of the book to keep the accent color.

Placement: the group sits center-right, about 42% of the frame width and 55% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left but slightly warmer (golden), soft long diagonal shadows, a little deeper contrast. Precious, quiet, museum-like. No text anywhere.
```

### Nhóm 2 — Khối đấu giá (khung 3:2)

**7. `upcoming` — Phiên sắp diễn ra**
```
SUBJECT 7 of the series - filename "upcoming". Aspect ratio 3:2 (landscape), at least 2400 x 1600 px.

Purpose: the card for an auction session that has not started yet (anticipation, countdown).

Hero objects: a brass hourglass with warm-white sand, mid-flow, standing on the surface; leaning against its base a blank cream paper ticket with a coral-orange perforated edge (no text, no numbers); one small cobalt-blue round stamp mark on the ticket as an abstract dot (no letters). Nothing else.

Placement: center-right, about 30% of the frame width and 60% of its height, with at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, soft long shadows, calm and expectant. No text anywhere.
```

### Nhóm 3 — Ô danh mục (khung 4:3)

> Quy tắc chung cho 6 ảnh nhóm này: ảnh bị cắt thành nhiều ô có kích thước khác nhau (khoảng 2:1, vuông, 1.5:1), nên **vật thể nằm chính giữa, chiếm khoảng 45% chiều rộng và 55% chiều cao**. **Góc trên-trái (khoảng 35% × 30%) và góc dưới-phải (khoảng 35% × 30%) phải để trống**: tên danh mục viết ở góc trên-trái, quạt bìa sách thật do app vẽ đè ở góc dưới-phải.

**8. `cat-vn` — Văn học Việt Nam**
```
SUBJECT 8 of the series - filename "cat-vn". Aspect ratio 4:3 (landscape), at least 1600 x 1200 px.

Purpose: the tile for the category "Vietnamese literature" (rural, nostalgic, 1930s-40s Vietnam).

Hero objects: a vintage clear-glass kerosene oil lamp (unlit or with a tiny warm flame) beside a Vietnamese conical palm-leaf hat (non la) tilted on its side, and an open book with blank pages lying in front. The hat and lamp are natural and slightly weathered; the book has a cream cover with a small cobalt-blue cloth spine.

Placement: centered group, about 45% of the frame width and 55% of its height. KEEP THE TOP-LEFT CORNER (35% x 30%) AND THE BOTTOM-RIGHT CORNER (35% x 30%) COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, soft diagonal shadows, nostalgic and warm. No text anywhere.
```

**9. `cat-foreign` — Văn học nước ngoài**
```
SUBJECT 9 of the series - filename "cat-foreign". Aspect ratio 4:3, at least 1600 x 1200 px.

Purpose: the tile for "foreign literature" (travel, faraway places, translation).

Hero objects: a small antique tabletop globe on a brass stand (the continents are only a soft muted cream, cobalt-blue and coral tint with NO labels or letters), a cream airmail-style envelope with a blank stamp-shaped rectangle (no text) leaning against it, and a folded paper airplane in coral-orange paper resting on the surface.

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, calm, curious, elegant. No text anywhere.
```

**10. `cat-textbook` — Giáo trình đại học**
```
SUBJECT 10 of the series - filename "cat-textbook". Aspect ratio 4:3, at least 1600 x 1200 px.

Purpose: the tile for "university textbooks" (study, knowledge, discipline).

Hero objects: a stack of four thick textbooks (cobalt blue, cream, dark green, coral cloth covers, blank spines) lying flat; a sharpened wooden pencil with a coral-orange body resting across the top; a metal drawing compass (brass) lying on the surface in front. No paper with writing.

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, crisp, orderly, focused. No text anywhere.
```

**11. `cat-skills` — Kỹ năng sống**
```
SUBJECT 11 of the series - filename "cat-skills". Aspect ratio 4:3, at least 1600 x 1200 px.

Purpose: the tile for "life skills / self-development" (growth, habits, time).

Hero objects: a small green seedling sprouting from soil in a matte cream ceramic cup; next to it an open notebook with completely blank cream pages and a coral-orange elastic band; behind them a small round coral-orange alarm clock with a blank face (hands only, no numerals).

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, fresh and gentle, a feeling of growth. No text anywhere.
```

**12. `cat-kids` — Thiếu nhi**
```
SUBJECT 12 of the series - filename "cat-kids". Aspect ratio 4:3, at least 1600 x 1200 px.

Purpose: the tile for "children's books" (playful but still refined, never childish or cartoonish).

Hero objects: a small tower of natural wooden building blocks (blank sides, some painted cobalt blue and coral-orange), a paper boat folded from cream paper, and a hardcover picture book with a blank cream cover lying in front of them.

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, soft and cheerful but the same premium photographic style. No text anywhere.
```

**13. `cat-rare` — Sách hiếm & cổ (ô danh mục)**
```
SUBJECT 13 of the series - filename "cat-rare". Aspect ratio 4:3, at least 1600 x 1200 px.

Purpose: the tile for "rare and antique books" (old, explorer's feel). It must not duplicate image 6, so use different objects.

Hero objects: a rolled antique map tied with a thin string (aged cream paper with only faint abstract coastline-like lines, NO labels or text), a brass pocket compass lying open beside it, and an old worn leather book standing slightly behind them. One small cobalt-blue accent (the string or a ribbon).

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, slightly warm, adventurous and old. No text anywhere.
```

### Nhóm 4 — Đăng nhập (khung dọc 4:5)

**14. `auth` — Đăng nhập / Đăng ký**
```
SUBJECT 14 of the series - filename "auth". Aspect ratio 4:5 (PORTRAIT), at least 1600 x 2000 px.

Purpose: the left-side image of the login and sign-up screens (welcome, entering, the key to the book world). On desktop it is a tall panel; on phones it is a strip at the top.

Hero objects: an open book standing slightly upright on a wooden surface (cream pages, blank, soft page curl), a small antique brass key laid across the open pages, and a cobalt-blue ribbon bookmark trailing from the spine. Coral-orange appears as a small accent on the book cloth edge.

Placement: the group sits in the LOWER HALF of the portrait frame, centered, about 55% of the frame width. KEEP THE UPPER THIRD OF THE FRAME COMPLETELY EMPTY backdrop (a title will sit there) and keep the sides clean.

Light and mood: window light from the upper left, soft diagonal shadow stripes falling across the book and the backdrop, welcoming and quiet. No text anywhere.
```

### Tuỳ chọn (khung 3:2)

**15. `season-tet` — Tết**
```
SUBJECT 15 of the series - filename "season-tet". Aspect ratio 3:2, at least 2400 x 1600 px.

Purpose: a seasonal banner for Vietnamese Lunar New Year.

Hero objects: a blooming peach-blossom branch (soft pink flowers) in a simple cream ceramic vase, a blank red lucky-money envelope (no text, no ornament, plain red paper with a gold edge), and a small stack of three books (coral, cream, cobalt blue, blank spines).

Placement: center-right, about 40% of the width and 65% of the height, at least 12% margin to the right and top. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, festive but restrained, same premium photographic style and greige backdrop. No text anywhere.
```

**16. `season-school` — Khai giảng**
```
SUBJECT 16 of the series - filename "season-school". Aspect ratio 3:2, at least 2400 x 1600 px.

Purpose: a seasonal banner for back-to-school / textbook season.

Hero objects: a stack of four textbooks (cobalt blue, cream, coral, green, blank spines), a cream canvas backpack leaning against them, and a pen lying on top.

Placement: center-right, about 42% of the width and 65% of the height, at least 12% margin to the right and top. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, fresh and ordered. No text anywhere.
```

---

## 4. Kiểm tra bộ ảnh sau khi AI làm xong

Mở cả bộ cạnh nhau và kiểm tra:
- **Cùng hướng sáng** (từ trên-trái), cùng màu nền greige, cùng độ cao máy ảnh. Ảnh nào lệch thì tạo lại riêng ảnh đó.
- **Không có chữ, số, người, tay** trong bất kỳ ảnh nào.
- **Vùng trống đúng chỗ** (góc dưới-trái ở nhóm 1–2; góc trên-trái và dưới-phải ở nhóm 3; phần trên ở `auth`).
- Màu nhấn chỉ có **xanh cobalt + cam san hô** (ngoài nền và vật liệu tự nhiên).
- Vật thể **không chạm mép ảnh** và nền liền mạch, để app cắt thoải mái.

Sau đó xuất WebP, đặt vào `assets/banners/` đúng tên, báo mình để gắn.
