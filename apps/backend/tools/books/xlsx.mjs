// Đọc file xlsx không cần thư viện: bảng tính ("Danh mục sách") và ảnh nhúng ("Ảnh bìa").

import { readFileSync } from 'node:fs';
import { inflateRawSync } from 'node:zlib';

export function readZip(path) {
  const buf = readFileSync(path);
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('Không phải file xlsx');
  const count = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16);
  const files = {};
  for (let i = 0; i < count; i++) {
    const method = buf.readUInt16LE(p + 10);
    const compSize = buf.readUInt32LE(p + 20);
    const nameLen = buf.readUInt16LE(p + 28);
    const extraLen = buf.readUInt16LE(p + 30);
    const commentLen = buf.readUInt16LE(p + 32);
    const local = buf.readUInt32LE(p + 42);
    const name = buf.toString('utf8', p + 46, p + 46 + nameLen);
    const start = local + 30 + buf.readUInt16LE(local + 26) + buf.readUInt16LE(local + 28);
    const raw = buf.subarray(start, start + compSize);
    files[name] = method === 0 ? raw : inflateRawSync(raw);
    p += 46 + nameLen + extraLen + commentLen;
  }
  return files;
}

const decode = (s) => s
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d))
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');

const colIndex = (ref) => {
  let n = 0;
  for (const ch of ref.replace(/\d+/g, '')) n = n * 26 + ch.charCodeAt(0) - 64;
  return n - 1;
};

/** Các dòng của một sheet: [{ r: số dòng Excel, cells: [...] }]. Chịu được tiền tố namespace (x:row) hoặc không. */
export function sheetRows(files, sheetPath) {
  const xml = files[sheetPath]?.toString('utf8');
  if (!xml) throw new Error('Thiếu ' + sheetPath);
  const shared = files['xl/sharedStrings.xml']
    ? [...files['xl/sharedStrings.xml'].toString('utf8').matchAll(/<(?:\w+:)?si>([\s\S]*?)<\/(?:\w+:)?si>/g)]
        .map((m) => decode([...m[1].matchAll(/<(?:\w+:)?t[^>]*>([\s\S]*?)<\/(?:\w+:)?t>/g)].map((t) => t[1]).join('')))
    : [];
  return [...xml.matchAll(/<(?:\w+:)?row\b[^>]*?\br="(\d+)"[^>]*>([\s\S]*?)<\/(?:\w+:)?row>/g)].map((row) => {
    const cells = [];
    for (const c of row[2].matchAll(/<(?:\w+:)?c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/(?:\w+:)?c>)/g)) {
      const ref = /\br="([A-Z]+\d+)"/.exec(c[1])?.[1];
      if (!ref) continue;
      const type = /\bt="([a-zA-Z]+)"/.exec(c[1])?.[1];
      const inner = c[2] ?? '';
      let v;
      if (type === 's') v = shared[+/<(?:\w+:)?v>(\d+)</.exec(inner)?.[1]] ?? '';
      else if (type === 'inlineStr') v = decode([...inner.matchAll(/<(?:\w+:)?t[^>]*>([\s\S]*?)<\/(?:\w+:)?t>/g)].map((t) => t[1]).join(''));
      else v = decode(/<(?:\w+:)?v>([\s\S]*?)<\/(?:\w+:)?v>/.exec(inner)?.[1] ?? '');
      cells[colIndex(ref)] = v.trim();
    }
    return { r: +row[1], cells: Array.from(cells, (x) => x ?? '') };
  });
}

/**
 * Ảnh nhúng ở sheet "Ảnh bìa": ảnh nằm ở dòng nào thì thuộc sách ở dòng đó (cột C là ISBN-13).
 * Trả về Map isbn(13 số) → { bytes, ext }.
 */
export function coverImages(files) {
  const rels = files['xl/drawings/_rels/drawing1.xml.rels']?.toString('utf8');
  const drawing = files['xl/drawings/drawing1.xml']?.toString('utf8');
  if (!rels || !drawing) return new Map();
  const target = new Map();
  for (const m of rels.matchAll(/<Relationship\b([^>]*)>/g)) {
    const id = /\bId="([^"]+)"/.exec(m[1])?.[1];
    const t = /\bTarget="([^"]+)"/.exec(m[1])?.[1];
    if (id && t) target.set(id, t.replace(/^\/+/, '').replace(/^\.\.\//, 'xl/'));
  }
  const rows = sheetRows(files, 'xl/worksheets/sheet2.xml');
  const isbnByRow = new Map(rows.map((r) => [r.r, (r.cells[2] ?? '').replace(/\D/g, '')]));
  const out = new Map();
  for (const a of drawing.matchAll(/<(?:\w+:)?(?:oneCellAnchor|twoCellAnchor)>([\s\S]*?)<\/(?:\w+:)?(?:oneCellAnchor|twoCellAnchor)>/g)) {
    const row0 = +/<(?:\w+:)?row>(\d+)</.exec(a[1])?.[1];
    const embed = /r:embed="([^"]+)"/.exec(a[1])?.[1];
    const path = target.get(embed);
    const isbn = isbnByRow.get(row0 + 1);
    if (!path || !isbn || !files[path]) throw new Error(`Ảnh ở dòng ${row0 + 1} không ghép được (embed ${embed})`);
    out.set(isbn, { bytes: files[path], ext: path.split('.').pop().toLowerCase() });
  }
  return out;
}

/** Sách ở sheet "Danh mục sách" (hàng tiêu đề là hàng có "STT"). Trả về [{ stt, row: {tên cột: giá trị} }]. */
export function bookRows(files) {
  const rows = sheetRows(files, 'xl/worksheets/sheet1.xml');
  const head = rows.find((r) => r.cells[0] === 'STT');
  if (!head) throw new Error('Không thấy hàng tiêu đề "STT"');
  return rows.filter((r) => r.r > head.r && /^\d+$/.test(r.cells[0] ?? '')).map((r) => {
    const row = {};
    head.cells.forEach((h, i) => { row[h] = r.cells[i] ?? ''; });
    return { stt: +r.cells[0], row };
  });
}
