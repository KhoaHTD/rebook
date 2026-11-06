// Upload ảnh bìa nhúng trong books.xlsx lên Cloudinary, ghi URL vào tools/books/covers.json (ISBN-13 → URL).
//
//   node tools/books/upload-covers.mjs               upload cuốn nào chưa có trong covers.json
//   node tools/books/upload-covers.mjs --only 9780735211292   chỉ một cuốn (để thử)
//   node tools/books/upload-covers.mjs --force       upload lại tất cả (ghi đè cùng public_id)
//
// Cần CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name> (biến môi trường hoặc apps/backend/.env.local).
// Ảnh nằm ở thư mục rebook/covers/<isbn13> trên Cloudinary; URL trả về được lưu vào book_images khi chạy gen.mjs.

import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { coverImages, readZip } from './xlsx.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const COVERS = join(here, 'covers.json');
const args = process.argv.slice(2);
const only = args.includes('--only') ? args[args.indexOf('--only') + 1] : null;
const force = args.includes('--force');

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

const images = coverImages(readZip(join(here, 'books.xlsx')));
const done = existsSync(COVERS) ? JSON.parse(readFileSync(COVERS, 'utf8')) : {};
const todo = [...images].filter(([isbn]) => (only ? isbn === only : force || !done[isbn]));
console.log(`Có ${images.size} ảnh trong Excel, cần upload ${todo.length}.`);

for (const [isbn, { bytes, ext }] of todo) {
  const timestamp = String(Math.floor(Date.now() / 1000));
  const params = { folder: 'rebook/covers', overwrite: 'true', public_id: isbn, timestamp };
  const toSign = Object.keys(params).sort().map((k) => `${k}=${params[k]}`).join('&') + apiSecret;
  const form = new FormData();
  form.append('file', new Blob([bytes], { type: ext === 'png' ? 'image/png' : 'image/jpeg' }), `${isbn}.${ext}`);
  form.append('api_key', apiKey);
  form.append('signature', createHash('sha1').update(toSign).digest('hex'));
  for (const [k, v] of Object.entries(params)) form.append(k, v);
  const res = await fetch(`https://api.cloudinary.com/v1_1/${cloud}/image/upload`, { method: 'POST', body: form });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.secure_url) {
    console.error(`${isbn}: lỗi ${res.status} ${body?.error?.message ?? ''}`);
    process.exitCode = 1;
    break;
  }
  done[isbn] = body.secure_url;
  writeFileSync(COVERS, JSON.stringify(Object.fromEntries(Object.entries(done).sort()), null, 1) + '\n');
  console.log(`${isbn}: ${body.secure_url}`);
}
