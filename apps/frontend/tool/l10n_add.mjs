// Thêm / cập nhật chuỗi cho cả app_vi.arb và app_en.arb trong một lần.
//   node tool/l10n_add.mjs path/to/strings.json
// strings.json: { "key": ["Tiếng Việt", "English"], "key2": ["Xin chào {name}", "Hello {name}", {"name": "String"}] }
// Phần tử thứ 3 (tuỳ chọn) khai báo placeholder: tên -> kiểu (String, int, num, DateTime).
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const src = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const files = { vi: 'lib/app/l10n/arb/app_vi.arb', en: 'lib/app/l10n/arb/app_en.arb' };

for (const [lang, rel] of Object.entries(files)) {
  const file = path.join(root, rel);
  const arb = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [key, [vi, en, ph]] of Object.entries(src)) {
    arb[key] = lang === 'vi' ? vi : en;
    if (lang === 'vi' && ph) {
      arb[`@${key}`] = { placeholders: Object.fromEntries(Object.entries(ph).map(([n, t]) => [n, { type: t }])) };
    }
  }
  fs.writeFileSync(file, JSON.stringify(arb, null, 2) + '\n');
}
console.log(`l10n: ${Object.keys(src).length} key(s) merged`);
