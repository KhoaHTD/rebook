// Sinh dữ liệu mẫu sách từ file Excel.
//
//   node tools/books/gen.mjs            (chạy trong apps/backend)
//
// Đọc  tools/books/books.xlsx  (không cần thư viện ngoài),
// ghi  src/main/resources/db/migration/V19__category_tree.sql   (cây thể loại, mọi môi trường)
//      src/main/resources/db/seed/V19_1__seed_books_from_sheet.sql  (xoá dữ liệu nghiệp vụ cũ + nạp sách, chỉ profile dev)
//      tools/books/REPORT.md  (bảng ISBN cũ → mới, sửa lỗi chính tả, thể loại, giá để duyệt).
// Thêm / sửa sách: sửa Excel (hoặc bảng sửa lỗi bên dưới) rồi chạy lại. Kết quả luôn giống nhau (không dùng số ngẫu nhiên).
//
// Ảnh bìa KHÔNG nằm trong dữ liệu này: cuốn nào có ảnh thì ảnh được upload (POST /files → Cloudinary) và ghi URL vào
// book_images như mọi sách khác; xem tools/books/README.md.

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inflateRawSync } from 'node:zlib';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const OUT_MIGRATION = join(root, 'src/main/resources/db/migration/V19__category_tree.sql');
const OUT_SEED = join(root, 'src/main/resources/db/seed/V19_1__seed_books_from_sheet.sql');
const OUT_REPORT = join(here, 'REPORT.md');

// ───────────────────────── cấu hình ─────────────────────────

/** Cây thể loại hai cấp: [tên cha, [tên con...]]. Thứ tự ở đây là thứ tự hiển thị. */
const TREE = [
  ['Văn học', ['Tiểu thuyết Việt Nam', 'Tiểu thuyết nước ngoài', 'Truyện ngắn', 'Tiểu thuyết lịch sử',
    'Văn học thử nghiệm – Siêu thực', 'Thơ', 'Trinh thám – Kinh dị', 'Ngôn tình – Lãng mạn']],
  ['Lịch sử – Chính trị', ['Lịch sử Việt Nam', 'Lịch sử thế giới', 'Chính trị']],
  ['Triết học – Tôn giáo', ['Triết học phương Tây', 'Văn hóa học', 'Phật giáo – Tâm linh']],
  ['Giáo trình', ['Công nghệ thông tin', 'Kinh tế – Quản trị', 'Khoa học – Kỹ thuật', 'Y – Dược', 'Luật – Hành chính', 'Ngoại ngữ']],
  ['Khoa học – Công nghệ', ['Truyền thông – Xã hội học', 'Khoa học thông tin', 'Khoa học tự nhiên', 'Tiểu sử khoa học']],
  ['Kinh tế – Kinh doanh', ['Kinh tế học', 'Quản trị – Khởi nghiệp', 'Marketing – Bán hàng']],
  ['Kỹ năng sống', ['Gia đình – Nuôi dạy con', 'Phát triển bản thân']],
  ['Tiểu sử – Hồi ký', ['Tiểu sử – Hồi ký văn học', 'Chân dung nhân vật']],
  ['Nghệ thuật', ['Nhiếp ảnh', 'Âm nhạc', 'Hội họa – Thiết kế']],
  ['Thiếu nhi', ['Truyện thiếu nhi', 'Sách tô màu – Kỹ năng cho bé']],
  ['Tham khảo', ['Từ điển – Bách khoa', 'Sách tra cứu']],
  ['Truyện tranh – Manga', []],
  ['Sức khỏe – Đời sống', []],
  ['Sách hiếm – Sách cổ', []],
];

/** Sửa lỗi rõ ràng trong sheet, theo STT: { stt: { title?, author?, publisher? } }. Chỉ sửa chính tả, không đổi nội dung. */
const CORRECTIONS = {
  10: { title: 'Mặt Trận Miền Tây Không Có Gì Lạ' },
  12: { title: 'Lược Khảo Lịch Sử Thượng Hải' },
  47: { title: 'Jakob von Gunten' },
  53: { title: 'The Rise of the Network Society' },
};

/** Ép thể loại cho từng STT khi quy tắc chung xếp chưa đúng. */
const CATEGORY_OVERRIDES = {
  10: 'Tiểu thuyết nước ngoài',
  26: 'Marketing – Bán hàng',
};

/** Shop theo ngôn ngữ: Tiếng Việt → shop 2 (Hà Nội, chủ user 4), còn lại → shop 1 (Sài Gòn, chủ user 3). */
const SHOPS = {
  vi: { shopId: 2, ownerId: 4 },
  other: { shopId: 1, ownerId: 3 },
};

/** Khoảng giá (đồng) theo ngôn ngữ; sách xuất bản trước 1950 cộng 50%. */
const PRICE_RANGE = { vi: [30000, 150000], other: [80000, 400000] };
const OLD_BOOK_BEFORE = 1950;

const CONDITIONS = { 'Mới': 'NEW', 'Như mới': 'LIKE_NEW', 'Tốt': 'VERY_GOOD', 'Khá': 'GOOD' };
const GRADE_VALUE = { NEW: 1.0, LIKE_NEW: 0.85, VERY_GOOD: 0.7, GOOD: 0.55 };

/** Số dư ví mẫu của ba người mua sau khi xoá dữ liệu cũ (nạp một lần, sổ cái khớp). */
const BUYER_WALLETS = [
  { userId: 5, amount: 5000000 },
  { userId: 6, amount: 5000000 },
  { userId: 7, amount: 3000000 },
];

// ───────────────────────── đọc xlsx ─────────────────────────

function readZip(buf) {
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('Không phải file xlsx (thiếu EOCD)');
  const count = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16);
  const files = {};
  for (let i = 0; i < count; i++) {
    if (buf.readUInt32LE(p) !== 0x02014b50) throw new Error('Thư mục trung tâm zip hỏng');
    const method = buf.readUInt16LE(p + 10);
    const compSize = buf.readUInt32LE(p + 20);
    const nameLen = buf.readUInt16LE(p + 28);
    const extraLen = buf.readUInt16LE(p + 30);
    const commentLen = buf.readUInt16LE(p + 32);
    const local = buf.readUInt32LE(p + 42);
    const name = buf.toString('utf8', p + 46, p + 46 + nameLen);
    const dataStart = local + 30 + buf.readUInt16LE(local + 26) + buf.readUInt16LE(local + 28);
    const raw = buf.subarray(dataStart, dataStart + compSize);
    files[name] = method === 0 ? raw : inflateRawSync(raw);
    p += 46 + nameLen + extraLen + commentLen;
  }
  return files;
}

const decodeXml = (s) => s
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d))
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');

function colIndex(ref) {
  let n = 0;
  for (const ch of ref.replace(/\d+/g, '')) n = n * 26 + ch.charCodeAt(0) - 64;
  return n - 1;
}

function readSheet(xlsxPath) {
  const files = readZip(readFileSync(xlsxPath));
  const sheet = files['xl/worksheets/sheet1.xml']?.toString('utf8');
  if (!sheet) throw new Error('Không thấy sheet1');
  const shared = files['xl/sharedStrings.xml']
    ? [...files['xl/sharedStrings.xml'].toString('utf8').matchAll(/<si>([\s\S]*?)<\/si>/g)]
        .map((m) => decodeXml([...m[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map((t) => t[1]).join('')))
    : [];
  return [...sheet.matchAll(/<row [^>]*>([\s\S]*?)<\/row>/g)].map((row) => {
    const cells = [];
    for (const c of row[1].matchAll(/<c ([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)) {
      const ref = /r="([A-Z]+\d+)"/.exec(c[1])?.[1];
      const type = /t="([a-zA-Z]+)"/.exec(c[1])?.[1];
      const inner = c[2] ?? '';
      let v = '';
      if (type === 'inlineStr') v = decodeXml([...inner.matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map((t) => t[1]).join(''));
      else if (type === 's') v = shared[+/<v>(\d+)<\/v>/.exec(inner)?.[1]] ?? '';
      else v = decodeXml(/<v>([\s\S]*?)<\/v>/.exec(inner)?.[1] ?? '');
      const idx = ref ? colIndex(ref) : cells.length;
      cells[idx] = v.trim();
    }
    return Array.from(cells, (x) => x ?? '');
  });
}

// ───────────────────────── tiện ích ─────────────────────────

const slugify = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/gi, 'd').toLowerCase()
  .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
const sql = (s) => `'${String(s).replace(/'/g, "''")}'`;
const hash = (s) => { let h = 2166136261; for (const ch of s) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); } return (h >>> 0); };

function isbn13Check(first12) {
  let t = 0;
  for (let i = 0; i < 12; i++) t += +first12[i] * (i % 2 ? 3 : 1);
  return String((10 - (t % 10)) % 10);
}

// ───────────────────────── thể loại ─────────────────────────

const parentOf = new Map();
for (const [p, kids] of TREE) for (const k of kids) parentOf.set(k, p);
const knownCategories = new Set([...TREE.map((t) => t[0]), ...parentOf.keys()]);

/** Quy tắc xếp thể loại từ giá trị trong sheet; tiểu thuyết tách theo ngôn ngữ. */
function categoryOf(row, isVi) {
  const stt = +row.stt;
  if (CATEGORY_OVERRIDES[stt]) return CATEGORY_OVERRIDES[stt];
  const g = row.genre.toLowerCase();
  const has = (...k) => k.some((x) => g.includes(x));
  if (has('truyện ngắn')) return 'Truyện ngắn';
  if (has('tiểu thuyết lịch sử')) return 'Tiểu thuyết lịch sử';
  if (has('siêu thực', 'thử nghiệm', 'hư cấu tài liệu', 'phi lý', 'khiêu khích', 'tượng trưng', 'giả tưởng')) return 'Văn học thử nghiệm – Siêu thực';
  if (has('từ điển sinh vật')) return 'Từ điển – Bách khoa';
  if (has('tiểu sử văn học')) return 'Tiểu sử – Hồi ký văn học';
  if (has('tiểu sử khoa học')) return 'Tiểu sử khoa học';
  if (has('tiểu thuyết')) return isVi ? 'Tiểu thuyết Việt Nam' : 'Tiểu thuyết nước ngoài';
  if (has('lịch sử', 'sử liệu')) return isVi ? 'Lịch sử Việt Nam' : 'Lịch sử thế giới';
  if (has('chính trị')) return 'Chính trị';
  if (has('khảo cứu văn hóa', 'văn hóa học')) return 'Văn hóa học';
  if (has('phật giáo', 'tâm linh', 'huyền bí')) return 'Phật giáo – Tâm linh';
  if (has('triết học')) return 'Triết học phương Tây';
  if (has('nhiếp ảnh')) return 'Nhiếp ảnh';
  if (has('giáo trình công nghệ', 'giáo trình cntt', 'khoa học máy tính')) return 'Công nghệ thông tin';
  if (has('giáo trình kinh tế', 'giáo trình quản trị')) return 'Kinh tế – Quản trị';
  if (has('kinh tế học')) return 'Kinh tế học';
  if (has('kỹ năng gia đình')) return 'Gia đình – Nuôi dạy con';
  if (has('truyền thông', 'xã hội học')) return 'Truyền thông – Xã hội học';
  if (has('khoa học thông tin')) return 'Khoa học thông tin';
  if (has('khoa học tự nhiên')) return 'Khoa học tự nhiên';
  throw new Error(`Chưa có quy tắc cho thể loại "${row.genre}" (STT ${row.stt})`);
}

// ───────────────────────── đọc & chuẩn hoá sách ─────────────────────────

const sheet = readSheet(join(here, 'books.xlsx'));
const header = sheet[0];
const col = (name) => {
  const i = header.findIndex((h) => h.startsWith(name));
  if (i < 0) throw new Error(`Thiếu cột "${name}"`);
  return i;
};
const C = {
  stt: col('STT'), title: col('Tên sách'), author: col('Tác giả'), genre: col('Thể loại'), cond: col('Tình trạng'),
  publisher: col('Nhà xuất bản'), year: col('Năm xuất bản'), isbn: col('ISBN'), lang: col('Ngôn ngữ'),
  pages: col('Số trang'), weight: col('Khối lượng'), desc: col('Mô tả'),
};

const books = sheet.slice(1).filter((r) => r[C.title]).map((r) => {
  const stt = +r[C.stt];
  const fix = CORRECTIONS[stt] ?? {};
  const isVi = r[C.lang] === 'Tiếng Việt';
  const row = { stt: r[C.stt], genre: r[C.genre] };
  const oldIsbn = r[C.isbn].replace(/[\s-]/g, '');
  const first12 = oldIsbn.slice(0, 12);
  const newIsbn = first12 + isbn13Check(first12);
  const grade = CONDITIONS[r[C.cond]];
  if (!grade) throw new Error(`Tình trạng lạ: ${r[C.cond]} (STT ${stt})`);
  const category = categoryOf(row, isVi);
  if (!knownCategories.has(category)) throw new Error(`Thể loại ${category} không có trong cây`);
  const year = +r[C.year];
  const pages = +r[C.pages];
  const [lo, hi] = isVi ? PRICE_RANGE.vi : PRICE_RANGE.other;
  const t = 0.4 * GRADE_VALUE[grade] + 0.35 * Math.min(pages / 700, 1) + 0.25 * ((hash(newIsbn) % 1000) / 1000);
  let price = lo + (hi - lo) * Math.min(t, 1);
  if (year < OLD_BOOK_BEFORE) price *= 1.5;
  price = Math.min(Math.max(Math.round(price / 1000) * 1000, 1000), 100000000);
  return {
    stt, title: fix.title ?? r[C.title], origTitle: r[C.title], author: fix.author ?? r[C.author], category,
    genre: r[C.genre], grade, gradeLabel: r[C.cond], publisher: fix.publisher ?? r[C.publisher], year, oldIsbn, isbn: newIsbn,
    isbnChanged: oldIsbn !== newIsbn, language: r[C.lang], isVi, pages, weight: +r[C.weight], description: r[C.desc],
    price, stock: 3 + (hash(newIsbn + 's') % 3), shop: isVi ? SHOPS.vi : SHOPS.other,
    daysAgo: 1 + ((stt * 7) % 30),
  };
});

const dupIsbn = books.map((b) => b.isbn).filter((x, i, a) => a.indexOf(x) !== i);
if (dupIsbn.length) throw new Error('ISBN trùng sau khi sửa: ' + dupIsbn.join(', '));

// ───────────────────────── V19: cây thể loại ─────────────────────────

const allSlugs = [];
const parentRows = [];
const childRows = [];
TREE.forEach(([p, kids], pi) => {
  parentRows.push(`    (${sql(p)}, ${sql(slugify(p))}, ${pi + 1})`);
  allSlugs.push(slugify(p));
  kids.forEach((k, ki) => {
    childRows.push(`    (${sql(k)}, ${sql(slugify(k))}, ${sql(slugify(p))}, ${ki + 1})`);
    allSlugs.push(slugify(k));
  });
});
if (new Set(allSlugs).size !== allSlugs.length) throw new Error('Slug thể loại trùng');
const slugList = allSlugs.map(sql).join(', ');

const deleteOld = `DELETE FROM categories c
 WHERE c.slug NOT IN (${slugList})
   AND NOT EXISTS (SELECT 1 FROM books b WHERE b.category_id = c.id)
   AND NOT EXISTS (SELECT 1 FROM categories ch WHERE ch.parent_id = c.id);`;

const migration = `-- Cây thể loại sách hai cấp (sinh từ tools/books/gen.mjs, đừng sửa tay).
-- Thể loại đã có giữ id (slug trùng thì chỉ cập nhật tên / cha / thứ tự). Thể loại cũ không còn trong cây và không có
-- sách nào dùng thì bị xoá; cái còn sách dùng được giữ lại cho tới khi sách đó bị xoá.

-- 1. Nhóm cha.
INSERT INTO categories (name, slug, sort_order) VALUES
${parentRows.join(',\n')}
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, parent_id = NULL, sort_order = EXCLUDED.sort_order;

-- 2. Thể loại con.
INSERT INTO categories (name, slug, parent_id, sort_order)
SELECT v.name, v.slug, p.id, v.sort_order
  FROM (VALUES
${childRows.join(',\n')}
       ) AS v(name, slug, parent_slug, sort_order)
  JOIN categories p ON p.slug = v.parent_slug
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, sort_order = EXCLUDED.sort_order;

-- 3. Dọn thể loại cũ không còn dùng (hai lượt: con trước, cha sau).
${deleteOld}
${deleteOld}
`;

// ───────────────────────── V19_1: nạp sách ─────────────────────────

const bookRows = books.map((b, i) => `    (${i + 1}, ${b.shop.ownerId}, ${sql(b.title)}, ${sql(b.author)}, ${sql(b.publisher)}, ${b.year}, ${sql(b.isbn)}, ${sql(b.language)}, ${b.pages},
        (SELECT id FROM categories WHERE slug = ${sql(slugify(b.category))}), ${sql(b.grade)}, ${sql(b.description)}, ${b.weight})`);
const listingRows = books.map((b, i) => `    (${i + 1}, ${i + 1}, ${b.shop.shopId}, ${b.price}, ${b.stock}, 0, 'ACTIVE', now() - interval '${b.daysAgo} days')`);

const walletRows = BUYER_WALLETS.map((w, i) => `    (${sql('PMDEMO00000' + (i + 1))}, ${w.userId}, 'TOP_UP', 'ZALOPAY', ${w.amount}, 'SUCCESS', ${sql('SEED-1400000' + (i + 1))}, now() - interval '${15 - i} days', now() - interval '${15 - i} days')`);
const ledgerRows = BUYER_WALLETS.map((w) => `    ((SELECT id FROM wallets WHERE user_id = ${w.userId}), 'TOP_UP', ${w.amount}, 0, ${w.amount}, 0, 'PAYMENT', (SELECT id FROM payments WHERE user_id = ${w.userId} AND purpose = 'TOP_UP'), 'Nạp tiền vào ví', now() - interval '14 days')`);

const seed = `-- Dữ liệu mẫu sách (sinh từ tools/books/gen.mjs và tools/books/books.xlsx, đừng sửa tay). Chỉ chạy với profile dev.
-- Xoá mọi dữ liệu nghiệp vụ cũ (sách, tin đăng, ký gửi, lô, phiên đấu giá, đơn, thanh toán, sổ cái ví, thông báo...),
-- giữ tài khoản, shop, địa chỉ, cấu hình; nạp ${books.length} sách thành tin đăng bán giá cố định (không có ảnh trong database).

TRUNCATE TABLE
    books, listings, consignments, inspections, warehouse_items, warehouse_incidents,
    auction_sessions, lots, auction_registrations, bids, proxy_bids, lot_watchers, session_watchers,
    orders, order_items, order_status_history, return_requests, reviews,
    payments, wallet_transactions, withdraw_requests, withdraw_transfers, account_debts,
    cart_items, listing_favorites, notifications, audit_events, admin_activity_logs, otp_codes, refresh_tokens
    RESTART IDENTITY CASCADE;

-- Thể loại cũ chỉ còn vì có sách dùng (V19 không xoá được): giờ xoá nốt.
${deleteOld}
${deleteOld}

-- Ví: về 0 rồi nạp lại cho ba người mua, sổ cái khớp số dư.
UPDATE wallets SET available_balance = 0, held_balance = 0;

INSERT INTO payments (code, user_id, purpose, method, amount, status, gateway_txn_id, paid_at, created_at) VALUES
${walletRows.join(',\n')};

INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, ref_id, note, created_at) VALUES
${ledgerRows.join(',\n')};

UPDATE wallets w SET available_balance = t.amount
  FROM (VALUES ${BUYER_WALLETS.map((w) => `(${w.userId}, ${w.amount})`).join(', ')}) AS t(user_id, amount)
 WHERE w.user_id = t.user_id;

-- Hai shop mẫu bán theo ngôn ngữ.
UPDATE shops SET description = 'Sách tiếng Anh: văn học thế giới, triết học và khoa học, tuyển chọn kỹ.' WHERE id = 1;
UPDATE shops SET description = 'Sách cũ phố Đinh Lễ: văn học Việt Nam, sử học, giáo trình và tâm linh.' WHERE id = 2;
UPDATE shops SET rating_avg = 0, rating_count = 0;

INSERT INTO books (id, owner_id, title, author, publisher, publish_year, isbn, language, pages, category_id,
                   condition_grade, description, weight_gram) VALUES
${bookRows.join(',\n')};

INSERT INTO listings (id, book_id, shop_id, price, stock, sold_count, status, created_at) VALUES
${listingRows.join(',\n')};

SELECT setval(pg_get_serial_sequence('books', 'id'),    (SELECT max(id) FROM books));
SELECT setval(pg_get_serial_sequence('listings', 'id'), (SELECT max(id) FROM listings));
`;

// ───────────────────────── báo cáo để duyệt ─────────────────────────

const report = `# Dữ liệu sách mẫu — báo cáo để duyệt

Sinh bởi \`tools/books/gen.mjs\` từ \`tools/books/books.xlsx\` (${books.length} sách). Chạy lại script sau khi sửa Excel.

## Sửa lỗi chính tả (theo bảng CORRECTIONS trong gen.mjs)

| STT | Trong sheet | Sau khi sửa |
|---|---|---|
${books.filter((b) => b.title !== b.origTitle).map((b) => `| ${b.stt} | ${b.origTitle} | ${b.title} |`).join('\n')}

## Nghi sai nhưng giữ nguyên (bạn quyết)

- STT 5 "Dế Hèn" (Nguyễn Huy Thiệp): không thấy tác phẩm tên này; "Dế Mèn Phiêu Lưu Ký" là của Tô Hoài.
- STT 12 "Lược Khảo Lịch Sử Thượng Hải" (Trần Trọng Kim): tên và tác giả có vẻ không khớp.
- STT 29 "Nền Kinh Tế Chia Sẻ" (Swami Iyer) và STT 28 tác giả "Professor John Vu - Nguyên Phong": giữ như sheet.

## ISBN: cũ → mới (đặt tên file ảnh theo cột ISBN-13 mới, không gạch)

${books.filter((b) => b.isbnChanged).length}/${books.length} ISBN bị sai chữ số kiểm tra nên chữ số cuối đã được tính lại.

| STT | Tên sách | ISBN cũ | ISBN-13 mới (tên file ảnh) | Đổi? |
|---|---|---|---|---|
${books.map((b) => `| ${b.stt} | ${b.title} | ${b.oldIsbn} | ${b.isbn} | ${b.isbnChanged ? 'có' : ''} |`).join('\n')}

## Thể loại, shop, giá, tồn kho

| STT | Tên sách | Thể loại sheet | Thể loại mới | Shop | Tình trạng | Giá | Tồn |
|---|---|---|---|---|---|---|---|
${books.map((b) => `| ${b.stt} | ${b.title} | ${b.genre} | ${parentOf.get(b.category)} › ${b.category} | ${b.shop.shopId === 2 ? 'Hà Nội Xưa' : 'Cũ Sài Gòn'} | ${b.gradeLabel} | ${b.price.toLocaleString('vi-VN')} | ${b.stock} |`).join('\n')}
`;

writeFileSync(OUT_MIGRATION, migration);
writeFileSync(OUT_SEED, seed);
writeFileSync(OUT_REPORT, report);
const byCat = {};
books.forEach((b) => { byCat[b.category] = (byCat[b.category] ?? 0) + 1; });
console.log(`Đã ghi ${books.length} sách, ${allSlugs.length} thể loại.`);
console.log('ISBN sửa:', books.filter((b) => b.isbnChanged).length);
console.log('Giá thấp nhất / cao nhất:', Math.min(...books.map((b) => b.price)), Math.max(...books.map((b) => b.price)));
console.log(byCat);
