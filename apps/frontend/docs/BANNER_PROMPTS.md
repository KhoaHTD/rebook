# Ảnh cần làm (danh sách rút gọn) + prompt làm hàng loạt

Nguyên tắc: **chỉ làm ảnh ở chỗ ảnh mang lại giá trị** (băng chuyền, danh mục, đấu giá, đăng nhập). Chỗ nào chữ và bìa sách đã đẹp (giá, bảng xếp hạng, giỏ hàng, lỗi, trạng thái rỗng) thì **không** cần ảnh.

**Hai khung hình khác nhau:** thẻ banner trên **máy tính** là khung ngang (~600 × 343 px, tỉ lệ ~16:9), còn trên **điện thoại** là khung gần vuông (~313 × 300 px, tỉ lệ ~1:1). Một ảnh cắt chung sẽ mất vật thể hoặc nhìn thừa nền, nên các ảnh bị ảnh hưởng nhiều nhất (băng chuyền, phiên sắp diễn ra, đăng nhập) được làm **hai bản**: bản máy tính và bản điện thoại (đuôi `-m`). Ô danh mục chỉ làm **một bản** (vật thể ở giữa nên cắt kiểu nào cũng ổn).

Tên file = tên trong `assets/banners/`, định dạng WebP (xuất từ PNG/JPG của AI rồi nén, dưới 400 KB mỗi ảnh). App tự chọn: điện thoại dùng `<tên>-m.webp`; thiếu thì rơi về bản máy tính.

## 1. Danh sách ảnh cần làm: 14 cảnh = 22 file (+ 2 cảnh tuỳ chọn)

### Nhóm 1 — Băng chuyền đầu trang chủ (6 cảnh × 2 bản = 12 file)

Thẻ phủ kín, ảnh cắt tự động theo khung. Người dùng thấy ảnh trước; rê chuột (máy tính) mới hiện thẻ chữ ở **góc dưới trái**. Vì vậy:
- **Bản máy tính** (`<tên>.webp`, 16:9, 2400 × 1350): vật thể giữa-phải, **góc dưới-trái để trống** (45% rộng × 40% cao).
- **Bản điện thoại** (`<tên>-m.webp`, 1:1, 1800 × 1800): vật thể **giữa, nằm ở phần trên** (60% rộng), **30% phía dưới để trống** (chỗ cho thẻ chữ nếu sau này hiện).

| Cảnh | File máy tính / điện thoại | Chỗ dùng | Vật thể |
|---|---|---|---|
| Đấu giá trực tiếp | `live.webp` / `live-m.webp` | Slide "Đấu giá trực tiếp" và thẻ LIVE lớn ở khối Đấu giá | Búa đấu giá gỗ trên đế gỗ tròn, bảng số cầm tay trống |
| Được săn nhiều nhất | `picks.webp` / `picks-m.webp` | Slide "Những cuốn được săn nhiều nhất" | Chồng 5 cuốn sách bìa cứng, ruy băng đánh dấu trang |
| Ký gửi | `consign.webp` / `consign-m.webp` | Slide "Ký gửi đấu giá" | Thùng gỗ mở nắp có sách, thẻ kraft buộc dây (thẻ trống) |
| Mới lên kệ | `new.webp` / `new-m.webp` | Slide "Mới lên kệ" | Thang thư viện gỗ dựa kệ tối giản có sách |
| Mở shop | `shop.webp` / `shop-m.webp` | Slide "Mở shop" | Túi vải tote đựng sách, biển gỗ nhỏ trống |
| Sách hiếm & cổ | `rare.webp` / `rare-m.webp` | Slide "Sách hiếm & cổ" và khối Sách hiếm | Sách da cổ có dấu sáp, kính lúp đồng, chìa khóa đồng |

### Nhóm 2 — Khối đấu giá (1 cảnh × 2 bản = 2 file)

| Cảnh | File | Chỗ dùng | Vật thể |
|---|---|---|---|
| Phiên sắp diễn ra | `upcoming.webp` (16:9) / `upcoming-m.webp` (1:1) | Thẻ "Phiên sắp diễn ra"; sau này làm slide băng chuyền | Đồng hồ cát đồng, vé giấy trống |

Quy tắc xếp giống nhóm 1.

### Nhóm 3 — Ô danh mục (6 cảnh × 1 bản = 6 file, 4:3, 1600 × 1200)

Mỗi danh mục là một ô bo góc, kích thước từ ~280 × 150 (điện thoại) đến ~560 × 280 px (máy tính); app cắt chung một ảnh cho cả hai nên **vật thể nằm chính giữa**. **Tên danh mục ở góc trên-trái**, **quạt bìa sách thật ở góc dưới-phải**: hai góc đó để trống.

| File | Danh mục | Vật thể |
|---|---|---|
| `cat-vn.webp` | Văn học Việt Nam | Đèn dầu thủy tinh cổ, nón lá, sách mở |
| `cat-foreign.webp` | Văn học nước ngoài | Quả địa cầu cổ, phong bì có tem, máy bay giấy |
| `cat-textbook.webp` | Giáo trình đại học | Chồng giáo trình, bút chì, compa |
| `cat-skills.webp` | Kỹ năng sống | Chậu cây nảy mầm, sổ tay mở, đồng hồ báo thức |
| `cat-kids.webp` | Thiếu nhi | Khối gỗ xếp hình, thuyền giấy, sách tranh |
| `cat-rare.webp` | Sách hiếm & cổ | Bản đồ cổ cuộn, la bàn đồng, sách da cũ |

### Nhóm 4 — Đăng nhập (1 cảnh × 2 bản = 2 file, chưa gắn code, vẽ sẵn)

| File | Chỗ dùng | Khung | Vật thể |
|---|---|---|---|
| `auth.webp` | Cột ảnh bên trái màn Đăng nhập / Đăng ký (máy tính) | Dọc 4:5, 1600 × 2000 | Sách mở, chìa khóa đồng đặt ngang trang, ruy băng xanh |
| `auth-m.webp` | Dải ảnh phía trên màn Đăng nhập (điện thoại) | Ngang 2:1, 1800 × 900 | Cùng vật thể, bố cục ngang |

### Tuỳ chọn (làm sau nếu cần; mỗi cảnh 2 bản như nhóm 1)

| Cảnh | File | Chỗ dùng | Vật thể |
|---|---|---|---|
| Tết | `season-tet.webp` / `season-tet-m.webp` | Banner dịp Tết thay slide thường | Cành đào, bao lì xì trống, chồng sách |
| Khai giảng | `season-school.webp` / `season-school-m.webp` | Banner khai giảng | Chồng giáo trình, balo vải, cây bút |

**Tổng: 22 file bắt buộc** (12 + 2 + 6 + 2) và 4 file tuỳ chọn.

### Đã bỏ khỏi danh sách (không cần ảnh)

- Giỏ hàng trống, đơn mua trống, không có kết quả, không có thông báo, 2 trang lỗi: giữ dạng biểu tượng + chữ + nút đen.
- 3 thẻ giá, khối Bảng xếp hạng, khối "Cùng một cuốn, nhiều ấn bản", khối Shop nổi bật, dòng phiên đã kết thúc, khối "chưa có phiên": nền trắng/bìa sách đủ đẹp.
- Đầu trang Đấu giá / Ví / Kênh người bán, màn Ký gửi, 9 cảnh trang giới thiệu: không ảnh.
- `auction-live` dùng lại `live.webp`; `rare-spotlight` dùng lại `rare.webp` (đổi tên khe trong code khi bạn báo).

---

## 2. Cách làm hàng loạt bằng một AI

1. Mở một cuộc trò chuyện mới với AI tạo ảnh (hỗ trợ ảnh tham chiếu: ChatGPT/DALL·E, Midjourney `--sref`, Gemini, Firefly...).
2. **Gắn một ảnh tham chiếu duy nhất** (ảnh giỏ hàng xanh cobalt – cam san hô của bạn) và dán **PROMPT CHUNG** bên dưới. Ở bước này đừng yêu cầu AI tạo ảnh; chỉ để nó đọc và hiểu bối cảnh + phong cách.
3. Sau đó dán **từng mục** ở phần 3 (mỗi mục là một cảnh). Mục băng chuyền, phiên sắp diễn ra và đăng nhập **yêu cầu AI tạo hai ảnh cùng một cảnh** (bản máy tính và bản điện thoại, cùng vật thể, cùng ánh sáng, chỉ bố cục lại). Dán lần lượt, trong **cùng một cuộc trò chuyện** để AI giữ cùng phong cách.
4. Nếu AI chỉ trả một ảnh mỗi lượt, bảo nó "now generate the (B) MOBILE version of the same scene".
5. Ảnh nào lệch phong cách (khác nền, khác ánh sáng, có chữ) thì bảo AI tạo lại riêng ảnh đó và nhắc "giống ảnh tham chiếu, đúng quy tắc trong prompt chung".

### PROMPT CHUNG (dán nguyên văn, tiếng Anh vì AI ảnh hiểu tốt hơn)

```
CONTEXT - please read carefully before generating anything.

I am designing the visuals of a mobile + web marketplace app for second-hand books and book auctions ("ReBook"). I need a SERIES of photographs that will be used as banner and card backgrounds inside the app. The app itself is clean, white and minimal; the photos are the only artistic, premium element, so they must look like they come from the same high-end editorial photo shoot.

I have attached ONE reference image. It is a style reference ONLY.
- COPY from it: the photographic rendering, the lighting, the soft diagonal window-light shadows, the greige seamless backdrop, the satin/matte material finish, the cobalt-blue + coral-orange color accents, the camera angle and distance, the calm minimal mood.
- DO NOT COPY from it: the subject (the basket). Each subject below has its own objects.

TWO FORMATS PER SCENE: the app has a desktop/web layout and a phone layout, and their banner frames have different shapes. For most scenes I will ask for TWO images of the SAME scene: (A) a DESKTOP version (wide frame) and (B) a MOBILE version (square frame, or a wide strip for one scene). Both versions must show the SAME objects, the SAME props, the SAME light and the SAME colors; only the framing and arrangement change so the scene works in each frame. Do not invent different props for the mobile version.

HOW THE PHOTOS WILL BE USED (this is why the rules below matter):
- Each photo is placed as a full-bleed background inside a rounded rectangle (banner or card) and may be cropped slightly. So the hero objects must sit well inside the frame, never touching the edges, and the background around them must continue smoothly in all directions (a seamless backdrop that can be cropped anywhere).
- The app then draws its OWN text, buttons and book covers on top of the photo. So specific regions of each image must be left EMPTY (only the clean backdrop, no objects, no strong shadows). Each image description below says which region to keep empty. This is mandatory.
- Any text baked into the photo would collide with the app's text, so the photos must contain NO text at all.

THE STYLE (identical in every image of the series):
1. Medium: premium studio still-life PHOTOGRAPH, hyper-realistic, as if shot on a 100 mm macro-style lens at f/8, sharp on the hero objects, soft natural falloff in the background. Not an illustration, not a 3D cartoon, not a vector, not a painting.
2. Camera: slightly elevated three-quarter view (about 20-30 degrees above the table), the same distance and perspective in every image. Objects are physical and tactile with believable weight, contact shadows and tiny imperfections.
3. Light: a single soft window light coming from the UPPER LEFT, casting long, soft, diagonal shadow stripes (like venetian-blind or window-frame shadows) across the backdrop and the floor, plus gentle bounce light so shadows are never black. Never harsh, never flashy. Same direction and softness in every image.
4. Backdrop: a seamless warm greige / light taupe paper-like wall and floor with no visible horizon line and no texture other than subtle paper grain, color about #D8D0C6 (slightly lighter toward the upper right, slightly darker toward the lower left).
5. Palette: the backdrop greige, plus cobalt blue (about #1F3FBF) and coral orange (about #F0643C) as the ONLY saturated accents, plus natural supporting tones: cream (#F3EBDD), kraft brown, warm natural wood, brass / antique gold, soft off-white. No other bright or neon colors. Keep the color count small and restrained. Blue and coral should appear in every image in small, deliberate amounts.
6. Materials: matte cloth book bindings, satin lacquer, brushed brass, raw wood, kraft paper, ceramic. Surfaces look premium and clean.
7. Composition: ONE hero group of objects per image, calm and sculptural, placed as described, with generous negative space around it. Minimal and uncluttered; no extra props beyond those listed.
8. Mood: calm, refined, editorial, quietly luxurious, a little warm and nostalgic (it is a book marketplace). Not busy, not playful, not childish (even for the kids theme, stay refined).

HARD RULES (never break them):
- NO text, letters, numbers, logos, watermarks or readable symbols anywhere. Book spines, covers, tags, signs, tickets, paddles, envelopes and wax seals must be blank or carry only abstract non-letter marks.
- NO people, NO hands, NO fingers, NO faces, NO animals, NO silhouettes of people.
- NO cartoon, vector, flat-illustration, painterly, glossy-CGI or AI "dreamy glow" look. No lens flare, no bokeh balls, no fog, no particles, no sparkles.
- NO busy backgrounds, shelves full of clutter, patterned wallpaper, windows or room interiors. The backdrop stays an empty seamless greige surface.
- NO strong vignette and no dark corners. Keep the edges of the image clean and even so the photo can be cropped.
- Keep the SAME style, light direction, backdrop color and camera in every image I ask for. If an image must be regenerated, match the reference again.

OUTPUT FORMAT: for every subject I send, produce the images requested (usually two: A desktop and B mobile), each at the exact aspect ratio I state, ultra-high resolution, no borders, no frames, no captions.

Reply "ready" and wait for the first subject.
```

---

## 3. CÁC CẢNH CẦN TẠO (dán từng mục sau khi AI trả lời "ready")

Mỗi mục tự đủ ý. Với mục có hai bản, đoạn **FORMAT** cuối mục quy định riêng khung và vùng trống cho bản máy tính (A) và bản điện thoại (B).

Hai đoạn FORMAT dùng chung cho nhóm 1–2 (đã chép sẵn vào từng mục):
- **(A) DESKTOP**: 16:9 ngang, 2400 × 1350 px. Cụm vật thể giữa-phải, chiếm ~40% rộng × ~60% cao, cách mép phải và mép trên ≥ 12%. **Góc dưới-trái (45% rộng × 40% cao) để trống**.
- **(B) MOBILE**: 1:1 vuông, 1800 × 1800 px. Cụm vật thể **ở giữa theo chiều ngang**, nằm trong **70% phía trên** khung, rộng ~60% khung, cách mép ≥ 10%. **30% phía dưới khung để trống**.

### Nhóm 1 — Băng chuyền đầu trang chủ

**1. `live` — Đấu giá trực tiếp**
```
SUBJECT 1 of the series - scene "live" (create TWO images: A desktop and B mobile).

Purpose in the app: the banner for a LIVE book auction happening right now. It must feel like the dramatic, high-value moment of an auction, but stay calm and premium.

Hero objects (same in A and B): a solid wooden auction gavel (warm walnut, matte, rounded hammer head with a brass band) resting at a slight diagonal on a round wooden sound block; beside it, standing upright and leaning slightly, a hand-held bidding paddle: a round cobalt-blue lacquered disc with a coral-orange rim and a short natural-wood handle. The paddle face is completely blank (no number, no text). No other props.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Hero group center-right, about 40% of the width and 60% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (about 45% of the width by 40% of the height) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same objects recomposed: hero group centered horizontally, inside the upper 70% of the frame, about 60% of the frame width, at least 10% margin from the edges. KEEP THE BOTTOM 30% OF THE FRAME COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left; long soft shadow falling to the lower right. Slightly more contrast than the others to suggest tension, but never dark. No text anywhere.
```

**2. `picks` — Được săn nhiều nhất**
```
SUBJECT 2 of the series - scene "picks" (create TWO images: A desktop and B mobile).

Purpose: the banner for "the most hunted books this week" (popular, sought-after).

Hero objects (same in A and B): a tall, slightly staggered stack of five hardcover books lying flat, bound in cloth: cobalt blue, coral orange, cream, kraft tan and deep forest green. Spines face the camera and are completely blank (no title text, no emblem), with tiny natural imperfections such as slightly worn corners. A coral-orange silk ribbon bookmark hangs out of the top book and drapes down the stack. Books are not perfectly aligned; each is shifted a few centimeters.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Stack center-right, about 30% of the width and 70% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (45% width x 40% height) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same stack recomposed: centered horizontally, inside the upper 70% of the frame, about 40% of the frame width and 65% of its height, at least 10% margin from the edges. KEEP THE BOTTOM 30% OF THE FRAME COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, long soft diagonal shadow. Warm, inviting, abundant but tidy. No text anywhere.
```

**3. `consign` — Ký gửi đấu giá**
```
SUBJECT 3 of the series - scene "consign" (create TWO images: A desktop and B mobile).

Purpose: the banner for "consign your valuable books to us for auction" (trust, safe keeping, appraisal).

Hero objects (same in A and B): a rustic open wooden crate (light pine, simple slats, lid leaning against the crate) holding four or five books standing and lying inside, with some crumpled kraft packing paper around them. A kraft paper hang-tag tied with a coral-orange string is draped over the front edge of the crate; the tag is completely blank. One book inside has a cobalt-blue cloth cover. No other props.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Crate center-right, about 40% of the width and 55% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same crate recomposed: centered horizontally, inside the upper 70% of the frame, about 60% of the frame width, at least 10% margin from the edges. KEEP THE BOTTOM 30% COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left, soft diagonal shadows across the floor and the crate. Trustworthy, careful, "kept safe". No text anywhere.
```

**4. `new` — Mới lên kệ**
```
SUBJECT 4 of the series - scene "new" (create TWO images: A desktop and B mobile).

Purpose: the banner for "new arrivals on the shelf" (fresh, bright, hopeful).

Hero objects (same in A and B): a minimal low wooden bookshelf (two shelves, simple light oak) holding about eight books in cobalt blue, coral orange, cream and kraft with blank spines, some standing and some leaning; a light wooden rolling library ladder with a few steps leans against the shelf. The scene is small and sculptural, like a miniature set, not a full library.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Shelf and ladder center-right, about 42% of the width and 70% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same shelf and ladder recomposed: centered horizontally, inside the upper 70% of the frame, about 60% of the frame width, at least 10% margin from the edges. KEEP THE BOTTOM 30% COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left, long soft diagonal shadows of the ladder rungs across the backdrop. Slightly brighter and airier than the others, same grade. No text anywhere.
```

**5. `shop` — Mở shop**
```
SUBJECT 5 of the series - scene "shop" (create TWO images: A desktop and B mobile).

Purpose: the banner inviting people to open their own small bookshop on the app (small business, friendly, handmade).

Hero objects (same in A and B): a cream canvas tote bag with coral-orange cotton handles, standing upright and holding four books (cobalt blue, kraft, cream, coral, blank spines) sticking out of the top; next to it a small blank wooden hanging sign (a plain rectangular wooden plank on a short string, no text) leaning against the bag; two more books stacked in front. Simple and handmade-looking.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Group center-right, about 38% of the width and 65% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same group recomposed: centered horizontally, inside the upper 70% of the frame, about 55% of the frame width, at least 10% margin from the edges. KEEP THE BOTTOM 30% COMPLETELY EMPTY backdrop.

Light and mood: window light from the upper left, soft diagonal shadows. Friendly, small-scale, optimistic. No text anywhere.
```

**6. `rare` — Sách hiếm & cổ**
```
SUBJECT 6 of the series - scene "rare" (create TWO images: A desktop and B mobile).

Purpose: the banner for rare and antique books (precious, old, collectible). It is also reused as the background of a dark "rare book" block, so it can be a touch warmer and moodier than the others while staying in the same family.

Hero objects (same in A and B): an antique leather-bound book (aged cognac-brown leather, gilded page edges, blind-embossed ornamental border with no letters on the cover) lying slightly angled, a red wax seal (no emblem, an abstract round impression) on a faded ribbon closing it; beside the book a brass magnifying glass with a wooden handle, and a small antique brass key on the surface. A faint cobalt-blue silk ribbon peeks out of the book to keep the accent color.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Group center-right, about 42% of the width and 60% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same group recomposed: centered horizontally, inside the upper 70% of the frame, about 60% of the frame width, at least 10% margin from the edges. KEEP THE BOTTOM 30% COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left but slightly warmer (golden), soft long diagonal shadows, a little deeper contrast. Precious, quiet, museum-like. No text anywhere.
```

### Nhóm 2 — Khối đấu giá

**7. `upcoming` — Phiên sắp diễn ra**
```
SUBJECT 7 of the series - scene "upcoming" (create TWO images: A desktop and B mobile).

Purpose: the card for an auction session that has not started yet (anticipation, countdown).

Hero objects (same in A and B): a brass hourglass with warm-white sand, mid-flow, standing on the surface; leaning against its base a blank cream paper ticket with a coral-orange perforated edge (no text, no numbers); one small cobalt-blue round stamp mark on the ticket as an abstract dot (no letters). Nothing else.

FORMAT A - DESKTOP: 16:9 landscape, 2400 x 1350 px. Group center-right, about 30% of the width and 65% of the height, at least 12% margin to the right and top edges. KEEP THE LOWER-LEFT CORNER (45% x 40%) COMPLETELY EMPTY backdrop.
FORMAT B - MOBILE: 1:1 square, 1800 x 1800 px. Same group recomposed: centered horizontally, inside the upper 70% of the frame, about 45% of the frame width, at least 10% margin from the edges. KEEP THE BOTTOM 30% COMPLETELY EMPTY backdrop.

Light and mood: same window light from the upper left, soft long shadows, calm and expectant. No text anywhere.
```

### Nhóm 3 — Ô danh mục (một bản, khung 4:3, 1600 × 1200)

> Ảnh được cắt thành nhiều ô kích cỡ khác nhau (khoảng 2:1, vuông, 1.5:1) trên cả máy tính lẫn điện thoại, nên vật thể **chính giữa**, ~45% rộng × ~55% cao, **góc trên-trái (35% × 30%) và góc dưới-phải (35% × 30%) để trống**.

**8. `cat-vn` — Văn học Việt Nam**
```
SUBJECT 8 of the series - scene "cat-vn". ONE image only. Aspect ratio 4:3 (landscape), 1600 x 1200 px.

Purpose: the tile for the category "Vietnamese literature" (rural, nostalgic, 1930s-40s Vietnam).

Hero objects: a vintage clear-glass kerosene oil lamp (unlit or with a tiny warm flame) beside a Vietnamese conical palm-leaf hat (non la) tilted on its side, and an open book with blank pages lying in front. Natural and slightly weathered; the book has a cream cover with a small cobalt-blue cloth spine.

Placement: centered group, about 45% of the frame width and 55% of its height. KEEP THE TOP-LEFT CORNER (35% x 30%) AND THE BOTTOM-RIGHT CORNER (35% x 30%) COMPLETELY EMPTY backdrop. The image will be cropped to several shapes, so keep the group centered.

Light and mood: same window light from the upper left, soft diagonal shadows, nostalgic and warm. No text anywhere.
```

**9. `cat-foreign` — Văn học nước ngoài**
```
SUBJECT 9 of the series - scene "cat-foreign". ONE image only. Aspect ratio 4:3, 1600 x 1200 px.

Purpose: the tile for "foreign literature" (travel, faraway places, translation).

Hero objects: a small antique tabletop globe on a brass stand (continents only as a soft muted cream, cobalt-blue and coral tint with NO labels or letters), a cream airmail-style envelope with a blank stamp-shaped rectangle (no text) leaning against it, and a folded paper airplane in coral-orange paper resting on the surface.

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop. Keep the group centered (the image is cropped to several shapes).

Light and mood: same window light from the upper left, calm, curious, elegant. No text anywhere.
```

**10. `cat-textbook` — Giáo trình đại học**
```
SUBJECT 10 of the series - scene "cat-textbook". ONE image only. Aspect ratio 4:3, 1600 x 1200 px.

Purpose: the tile for "university textbooks" (study, knowledge, discipline).

Hero objects: a stack of four thick textbooks (cobalt blue, cream, dark green, coral cloth covers, blank spines) lying flat; a sharpened wooden pencil with a coral-orange body across the top; a brass metal drawing compass lying on the surface in front. No paper with writing.

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop. Keep the group centered.

Light and mood: same window light from the upper left, crisp, orderly, focused. No text anywhere.
```

**11. `cat-skills` — Kỹ năng sống**
```
SUBJECT 11 of the series - scene "cat-skills". ONE image only. Aspect ratio 4:3, 1600 x 1200 px.

Purpose: the tile for "life skills / self-development" (growth, habits, time).

Hero objects: a small green seedling sprouting from soil in a matte cream ceramic cup; next to it an open notebook with completely blank cream pages and a coral-orange elastic band; behind them a small round coral-orange alarm clock with a blank face (hands only, no numerals).

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop. Keep the group centered.

Light and mood: same window light from the upper left, fresh and gentle, a feeling of growth. No text anywhere.
```

**12. `cat-kids` — Thiếu nhi**
```
SUBJECT 12 of the series - scene "cat-kids". ONE image only. Aspect ratio 4:3, 1600 x 1200 px.

Purpose: the tile for "children's books" (playful but still refined, never childish or cartoonish).

Hero objects: a small tower of natural wooden building blocks (blank sides, some painted cobalt blue and coral-orange), a paper boat folded from cream paper, and a hardcover picture book with a blank cream cover lying in front of them.

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop. Keep the group centered.

Light and mood: same window light from the upper left, soft and cheerful but the same premium photographic style. No text anywhere.
```

**13. `cat-rare` — Sách hiếm & cổ (ô danh mục)**
```
SUBJECT 13 of the series - scene "cat-rare". ONE image only. Aspect ratio 4:3, 1600 x 1200 px.

Purpose: the tile for "rare and antique books" (old, explorer's feel). It must not duplicate scene 6, so use different objects.

Hero objects: a rolled antique map tied with a thin string (aged cream paper with only faint abstract coastline-like lines, NO labels or text), a brass pocket compass lying open beside it, and an old worn leather book standing slightly behind them. One small cobalt-blue accent (the string or a ribbon).

Placement: centered group, about 45% of the width and 55% of the height. KEEP THE TOP-LEFT (35% x 30%) AND BOTTOM-RIGHT (35% x 30%) CORNERS COMPLETELY EMPTY backdrop. Keep the group centered.

Light and mood: same window light from the upper left, slightly warm, adventurous and old. No text anywhere.
```

### Nhóm 4 — Đăng nhập

**14. `auth` — Đăng nhập / Đăng ký**
```
SUBJECT 14 of the series - scene "auth" (create TWO images: A desktop panel and B mobile strip).

Purpose: the image on the login and sign-up screens (welcome, entering, the key to the book world). On desktop it is a tall side panel; on phones it is a wide strip at the top of the screen.

Hero objects (same in A and B): an open book standing slightly upright on a wooden surface (cream pages, blank, soft page curl), a small antique brass key laid across the open pages, and a cobalt-blue ribbon bookmark trailing from the spine. Coral-orange appears as a small accent on the book cloth edge.

FORMAT A - DESKTOP PANEL: 4:5 PORTRAIT, 1600 x 2000 px. Group in the LOWER HALF, centered, about 55% of the frame width. KEEP THE UPPER THIRD OF THE FRAME COMPLETELY EMPTY backdrop (a title will sit there) and keep the sides clean.
FORMAT B - MOBILE STRIP: 2:1 LANDSCAPE, 1800 x 900 px. Same objects recomposed: group centered, about 40% of the frame width and 70% of its height, at least 10% margin from the edges. Keep the left and right thirds empty backdrop.

Light and mood: window light from the upper left, soft diagonal shadow stripes falling across the book and the backdrop, welcoming and quiet. No text anywhere.
```

### Tuỳ chọn (hai bản như nhóm 1)

**15. `season-tet` — Tết**
```
SUBJECT 15 of the series - scene "season-tet" (create TWO images: A desktop 16:9 2400 x 1350 and B mobile 1:1 1800 x 1800, same objects, same rules for empty areas as scene 1: desktop keeps the lower-left 45% x 40% empty, mobile keeps the bottom 30% empty).

Purpose: a seasonal banner for Vietnamese Lunar New Year.

Hero objects: a blooming peach-blossom branch (soft pink flowers) in a simple cream ceramic vase, a blank red lucky-money envelope (no text, no ornament, plain red paper with a gold edge), and a small stack of three books (coral, cream, cobalt blue, blank spines).

Light and mood: same window light from the upper left, festive but restrained, same premium photographic style and greige backdrop. No text anywhere.
```

**16. `season-school` — Khai giảng**
```
SUBJECT 16 of the series - scene "season-school" (create TWO images: A desktop 16:9 2400 x 1350 and B mobile 1:1 1800 x 1800, same objects, same rules for empty areas as scene 1: desktop keeps the lower-left 45% x 40% empty, mobile keeps the bottom 30% empty).

Purpose: a seasonal banner for back-to-school / textbook season.

Hero objects: a stack of four textbooks (cobalt blue, cream, coral, green, blank spines), a cream canvas backpack leaning against them, and a pen lying on top.

Light and mood: same window light from the upper left, fresh and ordered. No text anywhere.
```

---

## 4. Kiểm tra bộ ảnh sau khi AI làm xong

Mở cả bộ cạnh nhau và kiểm tra:
- **Cùng hướng sáng** (từ trên-trái), cùng màu nền greige, cùng độ cao máy ảnh. Ảnh nào lệch thì tạo lại riêng ảnh đó.
- **Bản máy tính và bản điện thoại cùng một cảnh**: cùng vật thể, cùng màu, chỉ khác bố cục.
- **Không có chữ, số, người, tay** trong bất kỳ ảnh nào.
- **Vùng trống đúng chỗ**: bản máy tính trống góc dưới-trái; bản điện thoại trống 30% phía dưới; ô danh mục trống góc trên-trái và dưới-phải; `auth` trống phần trên.
- Màu nhấn chỉ có **xanh cobalt + cam san hô** (ngoài nền và vật liệu tự nhiên).
- Vật thể **không chạm mép ảnh** và nền liền mạch.

Sau đó xuất WebP, đặt vào `assets/banners/` đúng tên (bản điện thoại có đuôi `-m`), báo mình để gắn.
