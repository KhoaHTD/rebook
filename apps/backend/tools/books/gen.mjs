// Sinh dữ liệu mẫu sách từ file Excel.
//
//   node tools/books/gen.mjs            (chạy trong apps/backend)
//
// Đọc  tools/books/books.xlsx  và  tools/books/covers.json  (ISBN → URL ảnh bìa trên Cloudinary, do upload-covers.mjs ghi),
// ghi  src/main/resources/db/migration/V20__category_tree.sql   (cây thể loại, mọi môi trường)
//      src/main/resources/db/seed/V21_1__seed_books_from_sheet.sql  (xoá dữ liệu nghiệp vụ cũ + nạp sách, chỉ profile dev)
//      tools/books/REPORT.md  (thể loại, shop, giá, tồn kho từng sách để duyệt).
// Thêm / sửa sách: sửa Excel (hoặc các bảng cấu hình bên dưới) rồi chạy lại. Kết quả luôn giống nhau (không dùng số ngẫu nhiên).
// Seed chạy sau V21 (cột favorite_count) nên đặt tên V21_1.
// Thêm sách mới có ảnh: chạy upload-covers.mjs trước để covers.json có URL của ISBN đó.

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { bookRows, readZip } from './xlsx.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const OUT_MIGRATION = join(root, 'src/main/resources/db/migration/V20__category_tree.sql');
const OUT_SEED = join(root, 'src/main/resources/db/seed/V21_1__seed_books_from_sheet.sql');
const OUT_REPORT = join(here, 'REPORT.md');

// ───────────────────────── cấu hình ─────────────────────────

/** Cây thể loại hai cấp: [tên cha, [tên con...]]. Thứ tự ở đây là thứ tự hiển thị. */
const TREE = [
  ['Văn học', ['Tiểu thuyết Việt Nam', 'Tiểu thuyết nước ngoài', 'Văn học kinh điển', 'Văn học đương đại', 'Trinh thám – Kinh dị',
    'Kỳ ảo – Giả tưởng', 'Ngôn tình – Lãng mạn', 'Tiểu thuyết lịch sử', 'Truyện ngắn', 'Thơ']],
  ['Lịch sử – Chính trị', ['Lịch sử Việt Nam', 'Lịch sử thế giới', 'Chính trị']],
  ['Tiểu sử – Hồi ký', ['Hồi ký – Tự truyện', 'Chân dung nhân vật']],
  ['Kỹ năng sống', ['Phát triển bản thân', 'Tâm lý học', 'Gia đình – Nuôi dạy con']],
  ['Ẩm thực – Nấu ăn', ['Nấu ăn gia đình', 'Ẩm thực quốc tế', 'Ăn chay – Dinh dưỡng']],
  ['Hài hước – Tiểu luận', ['Hài hước', 'Tiểu luận – Tuyển tập']],
  ['Kinh tế – Kinh doanh', ['Kinh tế học', 'Quản trị – Khởi nghiệp', 'Marketing – Bán hàng']],
  ['Khoa học – Công nghệ', ['Khoa học tự nhiên', 'Khoa học thông tin', 'Truyền thông – Xã hội học']],
  ['Triết học – Tôn giáo', ['Triết học phương Tây', 'Văn hóa học', 'Tôn giáo – Tâm linh']],
  ['Giáo trình', ['Công nghệ thông tin', 'Kinh tế – Quản trị', 'Khoa học – Kỹ thuật', 'Y – Dược', 'Luật – Hành chính', 'Ngoại ngữ']],
  ['Sở thích – Giải trí', ['Trò chơi – Giải đố', 'Thú cưng – Thiên nhiên']],
  ['Nghệ thuật', ['Nhiếp ảnh', 'Âm nhạc', 'Hội họa – Thiết kế']],
  ['Thiếu nhi', ['Truyện thiếu nhi', 'Sách tô màu – Kỹ năng cho bé']],
  ['Tham khảo', ['Từ điển – Bách khoa', 'Sách tra cứu']],
  ['Truyện tranh – Manga', []],
  ['Sức khỏe – Đời sống', []],
  ['Sách hiếm – Sách cổ', []],
];

/** Thể loại của từng sách theo STT trong sheet (sheet ghi nhiều nhãn gạch chéo, ở đây chọn một thể loại con chính). */
const CATEGORY_BY_STT = {
  1: 'Phát triển bản thân', 2: 'Trinh thám – Kinh dị', 3: 'Ngôn tình – Lãng mạn', 4: 'Kỳ ảo – Giả tưởng',
  5: 'Kỳ ảo – Giả tưởng', 6: 'Văn học đương đại', 7: 'Ngôn tình – Lãng mạn', 8: 'Văn học đương đại',
  9: 'Văn học đương đại', 10: 'Tiểu thuyết lịch sử', 11: 'Văn học đương đại', 12: 'Trinh thám – Kinh dị',
  13: 'Văn học đương đại', 14: 'Kỳ ảo – Giả tưởng', 15: 'Ngôn tình – Lãng mạn', 16: 'Trinh thám – Kinh dị',
  17: 'Trinh thám – Kinh dị', 18: 'Kỳ ảo – Giả tưởng', 19: 'Trinh thám – Kinh dị', 20: 'Trinh thám – Kinh dị',
  21: 'Nấu ăn gia đình', 22: 'Ẩm thực quốc tế', 23: 'Ăn chay – Dinh dưỡng', 24: 'Tâm lý học',
  25: 'Lịch sử thế giới', 26: 'Ẩm thực quốc tế', 27: 'Tôn giáo – Tâm linh', 28: 'Khoa học tự nhiên',
  29: 'Trò chơi – Giải đố', 30: 'Hồi ký – Tự truyện', 31: 'Lịch sử thế giới', 32: 'Kinh tế học',
  33: 'Hồi ký – Tự truyện', 34: 'Lịch sử thế giới', 35: 'Chân dung nhân vật', 36: 'Nấu ăn gia đình',
  37: 'Thú cưng – Thiên nhiên', 38: 'Lịch sử thế giới', 39: 'Ăn chay – Dinh dưỡng', 40: 'Tiểu luận – Tuyển tập',
  41: 'Trinh thám – Kinh dị', 42: 'Văn học kinh điển', 43: 'Hồi ký – Tự truyện', 44: 'Hồi ký – Tự truyện',
  45: 'Chân dung nhân vật', 46: 'Chân dung nhân vật', 47: 'Hồi ký – Tự truyện', 48: 'Văn học kinh điển',
  49: 'Văn học kinh điển', 50: 'Văn học kinh điển', 51: 'Văn học kinh điển', 52: 'Văn học kinh điển',
  53: 'Văn học kinh điển', 54: 'Trinh thám – Kinh dị', 55: 'Văn học kinh điển', 56: 'Văn học đương đại',
  57: 'Văn học kinh điển', 58: 'Tiểu thuyết lịch sử', 59: 'Hài hước', 60: 'Hài hước',
  61: 'Hài hước', 62: 'Chính trị', 63: 'Khoa học tự nhiên', 64: 'Hài hước',
  65: 'Tiểu luận – Tuyển tập', 66: 'Khoa học tự nhiên', 67: 'Hài hước', 68: 'Hồi ký – Tự truyện',
  69: 'Phát triển bản thân', 70: 'Hài hước',
};

/** Tác giả để trống trong sheet (tuyển tập). */
const DEFAULT_AUTHOR = 'Nhiều tác giả';

/** Shop theo thể loại cha: tiểu thuyết (Văn học) → shop 1 (Sài Gòn, chủ user 3), còn lại → shop 2 (Hà Nội, chủ user 4). */
const FICTION_PARENT = 'Văn học';
const SHOPS = { fiction: { shopId: 1, ownerId: 3 }, nonfiction: { shopId: 2, ownerId: 4 } };
const SHOP_DESCRIPTIONS = {
  1: 'Tiểu thuyết tiếng Anh: văn học đương đại và kinh điển, kỳ ảo, trinh thám, lãng mạn. Tuyển chọn kỹ, giao nhanh.',
  2: 'Sách tiếng Anh phi hư cấu: hồi ký, lịch sử, ẩm thực, phát triển bản thân, khoa học và hài hước.',
};

/** Khoảng giá (đồng): tình trạng tốt, nhiều trang, bìa cứng thì đắt hơn. Làm tròn 1.000. */
const PRICE_RANGE = [120000, 450000];

/** Tình trạng trong sheet → mức của backend. */
const CONDITIONS = {
  'Mới, chưa sử dụng': 'NEW',
  'Như mới, bìa và trang sạch': 'LIKE_NEW',
  'Đã đọc, còn tốt': 'VERY_GOOD',
  'Đã đọc, gáy hơi nhăn': 'GOOD',
  'Đã qua sử dụng, góc bìa hơi mòn': 'GOOD',
};
const GRADE_VALUE = { NEW: 1.0, LIKE_NEW: 0.85, VERY_GOOD: 0.7, GOOD: 0.55, ACCEPTABLE: 0.4 };

/** Lượt yêu thích mẫu: khoảng 36% sách được 1 – 3 người mua thích, chọn theo ISBN nên không đổi giữa các lần chạy. */
const FAVORITE_SHARE_PERCENT = 36;
const FAVORITE_USERS = [5, 6, 7];

/** Số dư ví mẫu của ba người mua sau khi xoá dữ liệu cũ (nạp một lần, sổ cái khớp). */
const BUYER_WALLETS = [
  { userId: 5, amount: 5000000 },
  { userId: 6, amount: 5000000 },
  { userId: 7, amount: 3000000 },
];

// ───────────────────────── tiện ích ─────────────────────────

const slugify = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/gi, 'd').toLowerCase()
  .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
const sql = (s) => `'${String(s).replace(/'/g, "''")}'`;
const hash = (s) => { let h = 2166136261; for (const ch of s) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); } return (h >>> 0); };

function isbn13Valid(s) {
  if (!/^\d{13}$/.test(s)) return false;
  let t = 0;
  for (let i = 0; i < 12; i++) t += +s[i] * (i % 2 ? 3 : 1);
  return (10 - (t % 10)) % 10 === +s[12];
}

// ───────────────────────── thể loại ─────────────────────────

const parentOf = new Map();
for (const [p, kids] of TREE) for (const k of kids) parentOf.set(k, p);
const knownCategories = new Set([...TREE.map((t) => t[0]), ...parentOf.keys()]);

// ───────────────────────── đọc & chuẩn hoá sách ─────────────────────────

const covers = existsSync(join(here, 'covers.json')) ? JSON.parse(readFileSync(join(here, 'covers.json'), 'utf8')) : {};
const books = bookRows(readZip(join(here, 'books.xlsx'))).map(({ stt, row }) => {
  const isbn = row['ISBN-13'].replace(/\D/g, '');
  if (!isbn13Valid(isbn)) throw new Error(`ISBN sai chữ số kiểm tra (STT ${stt}): ${row['ISBN-13']}`);
  const grade = CONDITIONS[row['Tình trạng sách (giả lập)']];
  if (!grade) throw new Error(`Tình trạng lạ (STT ${stt}): ${row['Tình trạng sách (giả lập)']}`);
  const category = CATEGORY_BY_STT[stt];
  if (!category || !knownCategories.has(category)) throw new Error(`Thể loại của STT ${stt} không có trong cây: ${category}`);
  const pages = +row['Số trang'];
  const weight = +row['Khối lượng giả lập (g)'];
  const year = +row['Năm xuất bản'];
  if (!(weight > 0) || !(pages > 0) || !(year >= 1500 && year <= 2100)) throw new Error(`Số liệu lạ ở STT ${stt}`);
  const hardcover = row['Loại bìa'] === 'Bìa cứng';
  const t = 0.35 * GRADE_VALUE[grade] + 0.30 * Math.min(pages / 600, 1) + 0.15 * (hardcover ? 1 : 0.4) + 0.20 * ((hash(isbn) % 1000) / 1000);
  const fiction = parentOf.get(category) === FICTION_PARENT;
  return {
    stt, title: row['Tên sách'], author: row['Tác giả / Người biên soạn'] || DEFAULT_AUTHOR, authorBlank: !row['Tác giả / Người biên soạn'],
    category, genre: row['Thể loại'], grade, gradeLabel: row['Tình trạng sách (giả lập)'], publisher: row['Nhà xuất bản / Imprint'],
    year, isbn, language: row['Ngôn ngữ'], pages, weight, description: row['Mô tả tiếng Việt'], cover: covers[isbn] ?? null, hardcover,
    score: t, price: 0, stock: 3 + (hash(isbn + 's') % 3), shop: fiction ? SHOPS.fiction : SHOPS.nonfiction, daysAgo: 1 + ((stt * 7) % 30),
  };
});

// Điểm giá thô dồn về giữa; kéo giãn về 0..1 theo cả bộ để giá trải đều trong khoảng PRICE_RANGE.
const scores = books.map((b) => b.score);
const [minScore, maxScore] = [Math.min(...scores), Math.max(...scores)];
for (const b of books) {
  const k = maxScore > minScore ? (b.score - minScore) / (maxScore - minScore) : 0.5;
  b.price = Math.min(Math.max(Math.round((PRICE_RANGE[0] + (PRICE_RANGE[1] - PRICE_RANGE[0]) * k) / 1000) * 1000, 1000), 100000000);
}

const dupIsbn = books.map((b) => b.isbn).filter((x, i, a) => a.indexOf(x) !== i);
if (dupIsbn.length) throw new Error('ISBN trùng: ' + dupIsbn.join(', '));
const noCover = books.filter((b) => !b.cover);
if (noCover.length) console.warn(`Cảnh báo: ${noCover.length} sách chưa có ảnh trong covers.json (chạy upload-covers.mjs).`);

// ───────────────────────── sách hiếm (để đấu giá) ─────────────────────────
// Đọc rare.xlsx: ấn bản đầu / sưu tầm trước thời ISBN, không có tin đăng bán giá cố định; chỉ là bản ghi sách (kèm ảnh bìa)
// để script demo sau này đưa vào ký gửi và lô đấu giá. Ảnh ở covers.json với khoá rare-NN.

const RARE_CATEGORY = 'Sách hiếm – Sách cổ';
const RARE_OWNERS = [3, 4]; // người ký gửi: xen kẽ seller1 / seller2
/** Chưa kiểm định thật, nên mọi cuốn lấy cùng một mức; Staff sẽ đánh giá lại khi kiểm định. */
const RARE_GRADE = 'GOOD';
/** Sheet ghi "chưa xác minh": ước tính tương đối cho sách bìa cứng thời xưa (bìa + giấy dày). Làm tròn 10 g. */
const estimateRareWeight = (pages) => Math.round((160 + pages * 1.1) / 10) * 10;
const pad2 = (n) => String(n).padStart(2, '0');
const rareFile = join(here, 'rare.xlsx');
const rare = existsSync(rareFile) ? bookRows(readZip(rareFile)).map(({ stt, row }) => {
  const pages = +row['Số trang chính'];
  const year = +row['Năm xuất bản'];
  if (!(pages > 0) || !(year >= 1500 && year <= 2100)) throw new Error(`Số liệu lạ ở sách hiếm STT ${stt}`);
  if (!knownCategories.has(RARE_CATEGORY)) throw new Error('Thiếu thể loại ' + RARE_CATEGORY);
  return {
    stt, title: row['Tên sách'], author: row['Tác giả / Minh họa / Dịch giả'], publisher: row['Nhà xuất bản'], year, pages,
    language: row['Ngôn ngữ'], genre: row['Thể loại'], edition: row['Ấn bản được chọn'], weight: estimateRareWeight(pages),
    description: `${row['Mô tả tiếng Việt']}\n\nẤn bản: ${row['Ấn bản được chọn']}. ${row['Đặc điểm sưu tầm / Độ hiếm']}`,
    owner: RARE_OWNERS[(stt - 1) % RARE_OWNERS.length], cover: covers['rare-' + pad2(stt)] ?? null,
  };
}) : [];
const noRareCover = rare.filter((b) => !b.cover);
if (noRareCover.length) console.warn(`Cảnh báo: ${noRareCover.length} sách hiếm chưa có ảnh (chạy upload-covers.mjs).`);

// ───────────────────────── V20: cây thể loại ─────────────────────────

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

// ───────────────────────── V21_1: nạp sách ─────────────────────────

const bookRowsSql = books.map((b, i) => `    (${i + 1}, ${b.shop.ownerId}, ${sql(b.title)}, ${sql(b.author)}, ${sql(b.publisher)}, ${b.year}, ${sql(b.isbn)}, ${sql(b.language)}, ${b.pages},
        (SELECT id FROM categories WHERE slug = ${sql(slugify(b.category))}), ${sql(b.grade)}, ${sql(b.description)}, ${b.weight})`);
const imageRows = books.map((b, i) => (b.cover ? `    (${i + 1}, ${sql(b.cover)}, 0, 'SELLER')` : null)).filter(Boolean);
const favoriteRows = [];
books.forEach((b, i) => {
  const h = hash(b.isbn + 'f');
  if (h % 100 >= FAVORITE_SHARE_PERCENT) return;
  const count = 1 + ((h >>> 8) % 3);
  const start = (h >>> 4) % FAVORITE_USERS.length;
  for (let k = 0; k < count; k++) {
    favoriteRows.push(`    (${FAVORITE_USERS[(start + k) % FAVORITE_USERS.length]}, ${i + 1}, now() - interval '${1 + ((h >>> 12) + k) % 10} days')`);
  }
});
const listingRows = books.map((b, i) => `    (${i + 1}, ${i + 1}, ${b.shop.shopId}, ${b.price}, ${b.stock}, 0, 'ACTIVE', now() - interval '${b.daysAgo} days')`);

// Sách hiếm: id nối tiếp sách bán thường, không có ISBN, không có tin đăng.
const rareBookRows = rare.map((b, i) => `    (${books.length + i + 1}, ${b.owner}, ${sql(b.title)}, ${sql(b.author)}, ${sql(b.publisher)}, ${b.year}, NULL, ${sql(b.language)}, ${b.pages},
        (SELECT id FROM categories WHERE slug = ${sql(slugify(RARE_CATEGORY))}), ${sql(RARE_GRADE)}, ${sql(b.description)}, ${b.weight})`);
const rareImageRows = rare.map((b, i) => (b.cover ? `    (${books.length + i + 1}, ${sql(b.cover)}, 0, 'SELLER')` : null)).filter(Boolean);

const walletRows = BUYER_WALLETS.map((w, i) => `    (${sql('PMDEMO00000' + (i + 1))}, ${w.userId}, 'TOP_UP', 'ZALOPAY', ${w.amount}, 'SUCCESS', ${sql('SEED-1400000' + (i + 1))}, now() - interval '${15 - i} days', now() - interval '${15 - i} days')`);
const ledgerRows = BUYER_WALLETS.map((w) => `    ((SELECT id FROM wallets WHERE user_id = ${w.userId}), 'TOP_UP', ${w.amount}, 0, ${w.amount}, 0, 'PAYMENT', (SELECT id FROM payments WHERE user_id = ${w.userId} AND purpose = 'TOP_UP'), 'Nạp tiền vào ví', now() - interval '14 days')`);

const seed = `-- Dữ liệu mẫu sách (sinh từ tools/books/gen.mjs, books.xlsx và covers.json, đừng sửa tay). Chỉ chạy với profile dev.
-- Xoá mọi dữ liệu nghiệp vụ cũ (sách, tin đăng, ký gửi, lô, phiên đấu giá, đơn, thanh toán, sổ cái ví, thông báo...),
-- giữ tài khoản, shop, địa chỉ, cấu hình; nạp ${books.length} sách thành tin đăng bán giá cố định, mỗi sách một ảnh bìa trên Cloudinary.

TRUNCATE TABLE
    books, book_images, listings, consignments, inspections, warehouse_items, warehouse_incidents,
    auction_sessions, lots, auction_registrations, bids, proxy_bids, lot_watchers, session_watchers,
    orders, order_items, order_status_history, return_requests, reviews,
    payments, wallet_transactions, withdraw_requests, withdraw_transfers, account_debts,
    cart_items, listing_favorites, notifications, audit_events, admin_activity_logs, otp_codes, refresh_tokens
    RESTART IDENTITY CASCADE;

-- Thể loại cũ chỉ còn vì có sách dùng (V20 không xoá được): giờ xoá nốt.
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

-- Hai shop mẫu: tiểu thuyết / phi hư cấu.
UPDATE shops SET description = ${sql(SHOP_DESCRIPTIONS[1])} WHERE id = 1;
UPDATE shops SET description = ${sql(SHOP_DESCRIPTIONS[2])} WHERE id = 2;
UPDATE shops SET rating_avg = 0, rating_count = 0;

INSERT INTO books (id, owner_id, title, author, publisher, publish_year, isbn, language, pages, category_id,
                   condition_grade, description, weight_gram) VALUES
${bookRowsSql.join(',\n')};

INSERT INTO book_images (book_id, url, sort_order, source) VALUES
${imageRows.join(',\n')};

INSERT INTO listings (id, book_id, shop_id, price, stock, sold_count, status, created_at) VALUES
${listingRows.join(',\n')};
${rare.length ? `
-- ${rare.length} sách hiếm để đấu giá (ấn bản đầu / sưu tầm, không ISBN, chưa có tin đăng bán thường): chỉ là bản ghi sách
-- kèm ảnh bìa; ký gửi, kiểm định, lô và phiên đấu giá do script demo tạo.
INSERT INTO books (id, owner_id, title, author, publisher, publish_year, isbn, language, pages, category_id,
                   condition_grade, description, weight_gram) VALUES
${rareBookRows.join(',\n')};

INSERT INTO book_images (book_id, url, sort_order, source) VALUES
${rareImageRows.join(',\n')};
` : ''}
-- Lượt yêu thích mẫu (để thứ tự "phổ biến" có dữ liệu thật); favorite_count khớp bảng listing_favorites.
INSERT INTO listing_favorites (user_id, listing_id, created_at) VALUES
${favoriteRows.join(',\n')};

UPDATE listings l SET favorite_count = (SELECT count(*) FROM listing_favorites f WHERE f.listing_id = l.id);

SELECT setval(pg_get_serial_sequence('books', 'id'),    (SELECT max(id) FROM books));
SELECT setval(pg_get_serial_sequence('listings', 'id'), (SELECT max(id) FROM listings));
`;

// ───────────────────────── báo cáo để duyệt ─────────────────────────

const shopName = (b) => (b.shop.shopId === 1 ? 'Cũ Sài Gòn' : 'Hà Nội Xưa');
const report = `# Dữ liệu sách mẫu — báo cáo để duyệt

Sinh bởi \`tools/books/gen.mjs\` từ \`tools/books/books.xlsx\` (${books.length} sách, ảnh bìa trong \`covers.json\`). Chạy lại script sau khi sửa Excel.

## Quy tắc đã dùng (sửa ở đầu gen.mjs)

- **Tình trạng** (giả lập trong sheet): Mới, chưa sử dụng → \`NEW\`; Như mới → \`LIKE_NEW\`; Đã đọc, còn tốt → \`VERY_GOOD\`; Đã đọc, gáy hơi nhăn và Đã qua sử dụng, góc bìa hơi mòn → \`GOOD\`.
- **Khối lượng**: lấy cột "Khối lượng giả lập" của sheet (290 – 1.530 g).
- **Shop**: tiểu thuyết (nhóm "Văn học") → Nhà Sách Cũ Sài Gòn; còn lại → Tiệm Sách Hà Nội Xưa.
- **Giá**: ${PRICE_RANGE[0].toLocaleString('vi-VN')} – ${PRICE_RANGE[1].toLocaleString('vi-VN')} đồng theo tình trạng, số trang, bìa cứng; làm tròn 1.000. **Tồn kho**: 3 – 5 cuốn.
- **Tác giả để trống** (${books.filter((b) => b.authorBlank).map((b) => `STT ${b.stt}`).join(', ') || 'không có'}) → "${DEFAULT_AUTHOR}".
- **Ảnh**: mỗi sách một ảnh bìa, URL Cloudinary lưu ở \`book_images\` (ISBN-13 là tên ảnh \`rebook/covers/<isbn>\`).

## Từng sách

| STT | Tên sách | ISBN-13 | Thể loại sheet | Thể loại mới | Shop | Tình trạng | Khối lượng | Giá | Tồn | Ảnh |
|---|---|---|---|---|---|---|---|---|---|---|
${books.map((b) => `| ${b.stt} | ${b.title} | ${b.isbn} | ${b.genre} | ${parentOf.get(b.category)} › ${b.category} | ${shopName(b)} | ${b.gradeLabel} | ${b.weight} g | ${b.price.toLocaleString('vi-VN')} | ${b.stock} | ${b.cover ? 'có' : 'CHƯA'} |`).join('\n')}
`;

const rareReport = rare.length ? `

## Sách hiếm để đấu giá (${rare.length} cuốn, từ rare.xlsx)

Chưa có tin đăng bán thường; chỉ là bản ghi sách + ảnh bìa trong thể loại "${RARE_CATEGORY}". Không có ISBN (ấn bản trước hệ thống ISBN).
Tình trạng ghi \`${RARE_GRADE}\` cho tất cả vì chưa kiểm định thật. **Khối lượng là ước tính** (160 g + 1,1 g/trang), sheet ghi "chưa xác minh".
Người ký gửi xen kẽ seller1 / seller2.

| STT | Tên sách | Tác giả | Nhà xuất bản | Năm | Trang | Ấn bản | Khối lượng ước tính | Ký gửi | Ảnh |
|---|---|---|---|---|---|---|---|---|---|
${rare.map((b) => `| ${b.stt} | ${b.title} | ${b.author} | ${b.publisher} | ${b.year} | ${b.pages} | ${b.edition} | ${b.weight} g | seller${b.owner === 3 ? 1 : 2} | ${b.cover ? 'có' : 'CHƯA'} |`).join('\n')}
` : '';

writeFileSync(OUT_MIGRATION, migration);
writeFileSync(OUT_SEED, seed);
writeFileSync(OUT_REPORT, report + rareReport);
const byCat = {};
books.forEach((b) => { byCat[b.category] = (byCat[b.category] ?? 0) + 1; });
console.log(`Sách hiếm: ${rare.length}, ảnh: ${rareImageRows.length}`);
console.log(`Đã ghi ${books.length} sách, ${allSlugs.length} thể loại, ${imageRows.length} ảnh.`);
console.log('Giá thấp nhất / cao nhất:', Math.min(...books.map((b) => b.price)), Math.max(...books.map((b) => b.price)));
console.log('Sách có yêu thích:', new Set(favoriteRows.map((r) => r.split(', ')[1])).size, ' lượt:', favoriteRows.length);
console.log('Shop 1 / 2:', books.filter((b) => b.shop.shopId === 1).length, '/', books.filter((b) => b.shop.shopId === 2).length);
console.log(byCat);
