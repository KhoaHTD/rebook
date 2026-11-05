import { call, login, rec, results } from './lib.mjs';
import { writeFileSync } from 'node:fs';
const T = {}; for (const u of ['buyer1','buyer3','seller1','seller2','admin','staff']) T[u] = await login(u + '@rebook.vn');
const sh = (x) => JSON.stringify(x).slice(0, 300);
const img = (n) => 'https://picsum.photos/seed/c' + n + '/600/800';
const book = (title) => ({ title, author: 'Tác giả QA', publisher: 'NXB QA', publishYear: 1950, isbn: '9780000000019', language: 'Tiếng Việt', pages: 200, categoryId: 10, conditionGrade: 'GOOD', description: 'Sách cổ test', weightGram: 300, imageUrls: [img(1), img(2), img(3)] });

// 5.2 phân quyền Staff
for (const p of ['/admin/users', '/admin/configs', '/admin/dashboard', '/admin/withdrawals', '/admin/activity-logs']) { const r = await call('GET', p, undefined, T.staff); rec('5.2' + p, 'Staff gọi ' + p, r.status === 403, '403', r.status); }
for (const p of ['/admin/users', '/staff/consignments', '/staff/warehouse']) { const r = await call('GET', p, undefined, T.buyer1); rec('5.2u' + p, 'người dùng thường gọi ' + p, r.status === 403, '403', r.status); }

// 4.1 / 4.2 ký gửi
let r = await call('POST', '/consignments', { book: book('QA Ky Gui 250'), expectedPrice: 250000, provenance: 'Gia truyền' }, T.seller1);
rec('4.1', 'ký gửi giá mong muốn 250.000đ bị chặn (tối thiểu 300.000đ)', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/consignments', { book: book('QA Ky Gui 400'), expectedPrice: 400000, provenance: 'Sách của ông nội' }, T.seller1);
rec('4.2', 'ký gửi ≥ 300.000đ', r.status < 300, '2xx', r.status + sh(r.data));
const C = r.data;
const cl = (await call('GET', '/staff/consignments?size=50', undefined, T.staff)).data.items;
console.log('consignments', cl.map(c => c.code + ':' + c.status).join(' '));
const byCode = (code) => cl.find(c => c.code === code);
// 5.4 từ chối bắt buộc lý do
r = await call('POST', '/staff/consignments/' + C.id + '/review', { approve: false, note: '' }, T.staff);
rec('5.4a', 'sơ duyệt Không đạt bắt buộc nhập lý do', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/staff/consignments/' + C.id + '/review', { approve: false, note: 'Ảnh mờ' }, T.staff);
const cNow = (await call('GET', '/consignments/' + C.id, undefined, T.seller1)).data;
rec('5.4b', 'người gửi thấy lý do bị từ chối', r.status < 300 && cNow.reviewNote === 'Ảnh mờ', 'reviewNote', { st: r.status, note: cNow.reviewNote });
// 5.3 sơ duyệt Đạt KGDEMO000006
const k6 = byCode('KGDEMO000006');
r = await call('POST', '/staff/consignments/' + k6.id + '/review', { approve: true, note: 'ok' }, T.staff);
rec('5.3', 'sơ duyệt Đạt KGDEMO000006', r.status < 300, '2xx', r.status + sh(r.data));
// 4.3 đặt lịch hẹn
const day = (h, plus = 1) => { const d = new Date(Date.now() + plus * 86400000); d.setHours(h, 0, 0, 0); return d.toISOString(); };
r = await call('POST', '/consignments/' + k6.id + '/appointment', { appointmentAt: day(19) }, T.seller2);
rec('4.3a', 'đặt lịch hẹn ngoài 8:00–17:00 bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/consignments/' + k6.id + '/appointment', { appointmentAt: day(10, 9) }, T.seller2);
rec('4.3b', 'đặt lịch hẹn sau 7 ngày bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/consignments/' + k6.id + '/appointment', { appointmentAt: day(10, 2) }, T.seller2);
rec('4.3c', 'đặt lịch hẹn hợp lệ nhận mã', r.status < 300, '2xx', r.status + sh(r.data));
// 5.6 / 5.5 lịch hẹn
r = await call('GET', '/staff/appointments/NOPE12345', undefined, T.staff);
rec('5.6', 'nhập mã lịch hẹn sai báo không tìm thấy', r.status === 404, '404', r.status + sh(r.data));
r = await call('GET', '/staff/appointments/APDEMO0007', undefined, T.staff);
console.log('APDEMO0007', r.status, sh(r.data));
rec('5.5a', 'tra mã lịch hẹn APDEMO0007', r.status === 200, '200', r.status + sh(r.data));
const apCons = r.data.consignmentId ?? r.data.consignment?.id ?? r.data.id;
r = await call('POST', '/staff/consignments/' + apCons + '/check-in', { shelfCode: 'A-09-01', photoUrls: [img(5)] }, T.staff);
rec('5.5b', 'nhận sách + gán mã kệ → biên nhận / mã kho', r.status < 300, '2xx', r.status + sh(r.data));
// 5.7 / 5.8 kiểm định
const ins = (over) => ({ result: 'PASS', checklist: { fullPages: true, rightEdition: true, mold: false }, conditionGrade: 'GOOD', conditionReport: 'Tốt', photoUrls: [img(6), img(7), img(8)], estimateLow: 500000, estimateHigh: 900000, proposedStart: 300000, proposedReserve: 500000, ...over });
r = await call('POST', '/staff/consignments/' + apCons + '/inspection', ins({ estimateLow: 900000, estimateHigh: 500000 }), T.staff);
rec('5.8a', 'ước giá thấp > ước giá cao bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/staff/consignments/' + apCons + '/inspection', ins({ proposedStart: 600000, proposedReserve: 400000 }), T.staff);
rec('5.8b', 'giá sàn < giá khởi điểm bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/staff/consignments/' + apCons + '/inspection', ins({}), T.staff);
rec('5.7', 'kiểm định hợp lệ', r.status < 300, '2xx', r.status + sh(r.data));
// 4.4-4.5 quyết định
const k5 = byCode('KGDEMO000005');
const kd = (await call('GET', '/consignments/' + k5.id, undefined, T.seller1)).data;
console.log('KG5 view', sh(kd));
r = await call('POST', '/consignments/' + k5.id + '/decision', { decision: 'ACCEPT', agreeTerms: false }, T.seller1);
rec('4.5a', 'đồng ý nhưng không tick điều khoản bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/consignments/' + k5.id + '/decision', { decision: 'ACCEPT', agreeTerms: true }, T.seller1);
const ready = (await call('GET', '/admin/lots/ready', undefined, T.admin)).data;
rec('4.5b', 'đồng ý → lô sẵn sàng cho Admin xếp phiên', r.status < 300 && ready.items.length >= 1, 'có lô READY', { st: r.status, ready: ready.items.map(l => l.title) });
// 5.9 kho
const wh = (await call('GET', '/staff/warehouse', undefined, T.staff)).data;
rec('5.9a', 'kho có sách', (wh.items?.length ?? 0) >= 5, '>=5', wh.items?.length);
const w1 = wh.items[0]; r = await call('PUT', '/staff/warehouse/' + w1.id, { shelfCode: 'QA-01-01' }, T.staff);
const w2 = (await call('GET', '/staff/warehouse', undefined, T.staff)).data.items.find(x => x.id === w1.id);
rec('5.9b', 'đổi mã kệ', r.status < 300 && w2.shelfCode === 'QA-01-01', 'QA-01-01', { st: r.status, shelf: w2?.shelfCode });
await call('PUT', '/staff/warehouse/' + w1.id, { shelfCode: w1.shelfCode }, T.staff);

// ---- admin ----
const dash = await call('GET', '/admin/dashboard', undefined, T.admin);
rec('6.1', 'tổng quan', dash.status === 200, '200', sh(dash.data));
// 6.4 khoá / mở khoá
const users = (await call('GET', '/admin/users?q=buyer3', undefined, T.admin)).data.items; const b3 = users[0];
r = await call('POST', '/admin/users/' + b3.id + '/lock', { reason: 'QA khoá' }, T.admin);
const lg = await call('POST', '/auth/login', { email: 'buyer3@rebook.vn', password: 'Rebook@123' });
rec('6.4a', 'khoá buyer3 → không đăng nhập được', r.status < 300 && lg.status >= 400, '4xx', { lock: r.status, login: lg.status, body: lg.data });
const oldToken = await call('GET', '/me', undefined, T.buyer3);
rec('6.4b', 'token cũ của người bị khoá vẫn dùng được?', oldToken.status >= 400, '401/403 sau khi khoá', oldToken.status);
await call('POST', '/admin/users/' + b3.id + '/unlock', undefined, T.admin);
const lg2 = await call('POST', '/auth/login', { email: 'buyer3@rebook.vn', password: 'Rebook@123' });
rec('6.4c', 'mở khoá → đăng nhập lại được', lg2.status === 200, '200', lg2.status);
// 6.5 danh mục
r = await call('POST', '/admin/categories', { name: 'QA Con', slug: 'qa-con', parentId: 1, sortOrder: 9 }, T.admin);
rec('6.5a', 'thêm danh mục con', r.status < 300, '2xx', r.status + sh(r.data));
const cc = r.data;
r = await call('PUT', '/admin/categories/' + cc.id, { name: 'QA Con Sua', slug: 'qa-con', parentId: 1, sortOrder: 9 }, T.admin);
rec('6.5b', 'sửa tên danh mục', r.status < 300, '2xx', r.status + sh(r.data));
r = await call('DELETE', '/admin/categories/1', undefined, T.admin);
rec('6.5c', 'xoá danh mục còn con bị chặn, báo rõ lý do', r.status === 409 && /con|còn/i.test(r.data?.message ?? ''), '409 + lý do "còn danh mục con"', r.status + sh(r.data));
r = await call('DELETE', '/admin/categories/' + cc.id, undefined, T.admin);
rec('6.5d', 'xoá danh mục trống', r.status < 300, '2xx', r.status);
// 6.12 cấu hình
const key = 'fee.fixed_price_percent';
for (const bad of ['-5', 'abc', '150', '']) { r = await call('PUT', '/admin/configs/' + key, { value: bad }, T.admin); rec('6.12-' + JSON.stringify(bad), 'cấu hình phí = ' + JSON.stringify(bad) + ' bị chặn', r.status === 400, '400', r.status + sh(r.data)); }
r = await call('PUT', '/admin/configs/' + key, { value: '7' }, T.admin);
rec('6.12ok', 'đổi phí sàn 7%', r.status < 300, '2xx', r.status);
await call('PUT', '/admin/configs/' + key, { value: '5' }, T.admin);
// 6.6 phiên: giờ bắt đầu ở quá khứ
const iso = (m) => new Date(Date.now() + m * 60000).toISOString();
r = await call('POST', '/admin/sessions', { title: 'QA Phien', description: 'x', coverUrl: img(9), startAt: iso(-30), registrationDeadline: iso(-60), minParticipants: 1, depositAmount: 500000, lotDurationSec: 30, softCloseSec: 15, lotGapSec: 7 }, T.admin);
rec('6.6a', 'phiên có giờ bắt đầu ở quá khứ bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/admin/sessions', { title: 'QA Phien Moi', description: 'x', coverUrl: img(9), startAt: iso(60), registrationDeadline: iso(30), minParticipants: 1, depositAmount: 500000, lotDurationSec: 30, softCloseSec: 15, lotGapSec: 7 }, T.admin);
rec('6.6b', 'tạo phiên hợp lệ', r.status < 300, '2xx', r.status + sh(r.data));
const S2 = r.data;
const rd = (await call('GET', '/admin/lots/ready', undefined, T.admin)).data.items;
r = await call('PUT', '/admin/sessions/' + S2.id + '/lots', { lotIds: rd.map(l => l.id) }, T.admin);
rec('6.7a', 'xếp lô sẵn sàng vào phiên', r.status < 300, '2xx', r.status + sh(r.data));
r = await call('POST', '/admin/sessions/' + S2.id + '/publish', undefined, T.admin);
rec('6.7b', 'công bố phiên', r.status < 300, '2xx', r.status + sh(r.data));
const pubs = (await call('GET', '/sessions', undefined, T.buyer1)).data.items;
rec('6.7c', 'người dùng thấy phiên ở Sắp diễn ra', pubs.some(s => s.id === S2.id), 'có', pubs.map(s => s.id + ':' + s.status));
// 6.15 nhật ký
const lg3 = (await call('GET', '/admin/activity-logs?size=50', undefined, T.admin)).data;
const acts = (lg3.items ?? []).map(x => x.action);
rec('6.15', 'nhật ký ghi các thao tác vừa làm (duyệt tin, khoá, cấu hình...)', ['LOCK_USER', 'APPROVE_LISTING', 'UPDATE_CONFIG'].every(a => acts.some(x => (x ?? '').includes(a.split('_')[0]) || x === a)), 'đủ hành động', [...new Set(acts)]);

writeFileSync('g6.json', JSON.stringify(results, null, 1));
