// Thêm / cập nhật chuỗi cho cả app_vi.arb và app_en.arb trong một lần.
//   node tool/l10n_add.mjs path/to/strings.json [--zone adm|stf]
// strings.json: { "key": ["Tiếng Việt", "English"], "key2": ["Xin chào {name}", "Hello {name}", {"name": "String"}] }
// Phần tử thứ 3 (tuỳ chọn) khai báo placeholder: tên -> kiểu (String, int, num, DateTime).
//
// --zone adm | stf  (dành cho người làm Admin / Staff):
//   - bắt buộc mọi key mới có tiền tố "adm" / "stf" (vd. admUserFilter, stfInspectPass);
//   - từ chối ghi đè key đã tồn tại (chỉ được THÊM key mới);
//   - chèn key vào ngay sau key cuối cùng cùng tiền tố, để hai người sửa file arb ở hai chỗ khác nhau
//     và git merge không xung đột.
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const args = process.argv.slice(2);
const zoneIdx = args.indexOf('--zone');
const zone = zoneIdx >= 0 ? args[zoneIdx + 1] : null;
const srcPath = args.find((a, i) => !a.startsWith("--") && (zoneIdx < 0 || i !== zoneIdx + 1));
if (!srcPath) {
  console.error('Dùng: node tool/l10n_add.mjs <strings.json> [--zone adm|stf]');
  process.exit(64);
}
if (zone && !['adm', 'stf'].includes(zone)) {
  console.error('--zone chỉ nhận adm hoặc stf');
  process.exit(64);
}
const src = JSON.parse(fs.readFileSync(srcPath, 'utf8'));
const files = { vi: 'lib/app/l10n/arb/app_vi.arb', en: 'lib/app/l10n/arb/app_en.arb' };

if (zone) {
  const bad = Object.keys(src).filter((k) => !k.startsWith(zone));
  if (bad.length) {
    console.error(`Key phải bắt đầu bằng "${zone}": ${bad.join(', ')}`);
    process.exit(1);
  }
}

/** Chèn [entries] ngay sau key cuối cùng có tiền tố [prefix] (và khối @key của nó); không có thì thêm cuối file. */
function insertAfterZone(arb, entries, prefix) {
  const keys = Object.keys(arb);
  let last = -1;
  keys.forEach((k, i) => {
    if (k.replace(/^@/, '').startsWith(prefix)) last = i;
  });
  if (last < 0) return { ...arb, ...entries };
  const out = {};
  keys.forEach((k, i) => {
    out[k] = arb[k];
    if (i === last) Object.assign(out, entries);
  });
  return out;
}

for (const [lang, rel] of Object.entries(files)) {
  const file = path.join(root, rel);
  let arb = JSON.parse(fs.readFileSync(file, 'utf8'));
  const entries = {};
  for (const [key, [vi, en, ph]] of Object.entries(src)) {
    if (zone && key in arb) {
      console.error(`Key "${key}" đã tồn tại: không được ghi đè (chọn tên khác).`);
      process.exit(1);
    }
    entries[key] = lang === 'vi' ? vi : en;
    if (lang === 'vi' && ph) {
      entries[`@${key}`] = { placeholders: Object.fromEntries(Object.entries(ph).map(([n, t]) => [n, { type: t }])) };
    }
  }
  arb = zone ? insertAfterZone(arb, entries, zone) : { ...arb, ...entries };
  fs.writeFileSync(file, JSON.stringify(arb, null, 2) + '\n');
}
console.log(`l10n: ${Object.keys(src).length} key(s) merged${zone ? ` (zone ${zone})` : ''}`);
