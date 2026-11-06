// Upload ảnh bìa lên Cloudinary, ghi URL vào tools/books/covers.json (khoá → URL).
//
//   node tools/books/upload-covers.mjs               upload cuốn nào chưa có trong covers.json
//   node tools/books/upload-covers.mjs --only 9780735211292   chỉ một cuốn (khoá = ISBN-13 hoặc rare-NN)
//   node tools/books/upload-covers.mjs --force       upload lại tất cả (ghi đè cùng public_id)
//   node tools/books/upload-covers.mjs --only rare-01 --file anh-da-thu-nho.jpg   dùng ảnh khác (vd. ảnh gốc quá 10 MB đã thu nhỏ)
//
// Nguồn ảnh:
//   - books.xlsx (70 sách thường): ảnh nhúng ở sheet "Ảnh bìa", khoá = ISBN-13.
//   - rare.xlsx (24 sách hiếm, không ISBN): ảnh nhúng, khoá = rare-NN (NN = STT, hai chữ số). Nếu ảnh nhúng hỏng hoặc quá
//     10 MB (giới hạn upload của Cloudinary) thì thử lần lượt các link trong sheet: "Link ảnh bìa gốc", rồi "Nguồn ảnh và
//     ấn bản", rồi "Nguồn đối chiếu số trang"; cột nào tải về không phải ảnh (vd. trang web) thì bỏ qua sang cột kế.
//
// Cần CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name> (biến môi trường hoặc apps/backend/.env.local).
// Ảnh nằm ở thư mục rebook/covers/<khoá> trên Cloudinary; URL trả về được lưu vào book_images khi chạy gen.mjs.

import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { bookRows, coverImages, coverImagesByStt, readZip } from './xlsx.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const COVERS = join(here, 'covers.json');
const args = process.argv.slice(2);
const only = args.includes('--only') ? args[args.indexOf('--only') + 1] : null;
const force = args.includes('--force');
// --file <đường dẫn>: dùng ảnh này thay cho ảnh nhúng / link (cho ảnh quá lớn đã thu nhỏ tay); đi kèm --only.
const fileOverride = args.includes('--file') ? readFileSync(args[args.indexOf('--file') + 1]) : null;
const MAX_BYTES = 10 * 1024 * 1024 - 20000; // Cloudinary: tối đa 10 MiB một ảnh
const MIN_BYTES = 2000;
const LINK_COLUMNS = ['Link ảnh bìa gốc', 'Nguồn ảnh và ấn bản', 'Nguồn đối chiếu số trang'];

function cloudinaryUrl() {
  if (process.env.CLOUDINARY_URL) return process.env.CLOUDINARY_URL;
  const env = join(here, '..', '..', '.env.local');
  if (existsSync(env)) {
    const m = /^CLOUDINARY_URL=(.+)$/m.exec(readFileSync(env, 'utf8'));
    if (m) return m[1].trim();
  }
  throw new Error('Thiếu CLOUDINARY_URL (biến môi trường hoặc apps/backend/.env.local)');
}

const m = /^cloudinary:\/\/([^:]+):([^@]+)@(.+)$/.exec(cloudinaryUrl());
if (!m || m[0].includes('<')) throw new Error('CLOUDINARY_URL chưa hợp lệ');
const [, apiKey, apiSecret, cloud] = m;

/** Đuôi ảnh theo "chữ ký" đầu file; null nếu không phải JPEG / PNG / WebP. */
function imageExt(b) {
  if (b.length > 3 && b[0] === 0xff && b[1] === 0xd8) return 'jpg';
  if (b.length > 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'png';
  if (b.length > 12 && b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP') return 'webp';
  return null;
}

const usable = (bytes) => bytes && bytes.length >= MIN_BYTES && bytes.length <= MAX_BYTES && imageExt(bytes);

/** URL trong ô dạng "HYPERLINK is not implemented. linkLocation=<url>, friendlyName=<url>" hoặc URL trần. */
function linkOf(cell) {
  const x = /linkLocation=(\S+?),\s*friendlyName/.exec(cell ?? '');
  return x ? x[1] : /^https?:\/\//.test(cell ?? '') ? cell : null;
}

/** Wikimedia: ảnh gốc có thể rất lớn, xin bản thu nhỏ 1200 px cùng thư mục. */
function wikimediaThumb(url) {
  const w = /^(https:\/\/upload\.wikimedia\.org\/wikipedia\/commons)\/([0-9a-f]\/[0-9a-f]{2})\/([^/?]+)$/.exec(url);
  return w ? `${w[1]}/thumb/${w[2]}/${w[3]}/1200px-${w[3]}` : null;
}

async function download(url) {
  const tries = [wikimediaThumb(url), url].filter(Boolean);
  for (const u of tries) {
    try {
      const res = await fetch(u, { redirect: 'follow', headers: { 'User-Agent': 'rebook-course-project/1.0', Accept: 'image/*' } });
      if (!res.ok) continue;
      const bytes = Buffer.from(await res.arrayBuffer());
      if (usable(bytes)) return bytes;
    } catch {
      // thử đường khác
    }
  }
  return null;
}

// ── gom việc cần làm
const tasks = [];
for (const [isbn, img] of coverImages(readZip(join(here, 'books.xlsx')))) {
  tasks.push({ key: isbn, embedded: img.bytes, links: [] });
}
if (existsSync(join(here, 'rare.xlsx'))) {
  const files = readZip(join(here, 'rare.xlsx'));
  const imgs = coverImagesByStt(files);
  for (const { stt, row } of bookRows(files)) {
    tasks.push({
      key: 'rare-' + String(stt).padStart(2, '0'),
      embedded: imgs.get(String(stt))?.bytes ?? null,
      links: LINK_COLUMNS.map((c) => linkOf(row[c])).filter(Boolean),
    });
  }
}

const done = existsSync(COVERS) ? JSON.parse(readFileSync(COVERS, 'utf8')) : {};
const todo = tasks.filter((t) => (only ? t.key === only : force || !done[t.key]));
console.log(`Có ${tasks.length} ảnh cần có, cần upload ${todo.length}.`);

for (const t of todo) {
  let bytes = fileOverride && usable(fileOverride) ? fileOverride : usable(t.embedded) ? t.embedded : null;
  let source = fileOverride ? 'tệp chỉ định' : 'ảnh nhúng';
  if (!bytes) {
    for (const [i, link] of t.links.entries()) {
      bytes = await download(link);
      if (bytes) {
        source = `link ${i + 1}`;
        break;
      }
    }
  }
  if (!bytes) {
    console.error(`${t.key}: không có ảnh dùng được (ảnh nhúng hỏng / quá 10 MB và các link đều lỗi)`);
    process.exitCode = 1;
    continue;
  }
  const ext = imageExt(bytes);
  const timestamp = String(Math.floor(Date.now() / 1000));
  const params = { folder: 'rebook/covers', overwrite: 'true', public_id: t.key, timestamp };
  const toSign = Object.keys(params).sort().map((k) => `${k}=${params[k]}`).join('&') + apiSecret;
  const form = new FormData();
  form.append('file', new Blob([bytes], { type: ext === 'png' ? 'image/png' : ext === 'webp' ? 'image/webp' : 'image/jpeg' }), `${t.key}.${ext}`);
  form.append('api_key', apiKey);
  form.append('signature', createHash('sha1').update(toSign).digest('hex'));
  for (const [k, v] of Object.entries(params)) form.append(k, v);
  const res = await fetch(`https://api.cloudinary.com/v1_1/${cloud}/image/upload`, { method: 'POST', body: form });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.secure_url) {
    console.error(`${t.key}: lỗi ${res.status} ${body?.error?.message ?? ''}`);
    process.exitCode = 1;
    continue;
  }
  done[t.key] = body.secure_url;
  writeFileSync(COVERS, JSON.stringify(Object.fromEntries(Object.entries(done).sort()), null, 1) + '\n');
  console.log(`${t.key} (${source}, ${Math.round(bytes.length / 1000)} KB): ${body.secure_url}`);
}
