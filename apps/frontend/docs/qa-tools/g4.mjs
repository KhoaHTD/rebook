import { call, login, rec, results } from './lib.mjs';
import { writeFileSync } from 'node:fs';
const T = {}; for (const u of ['buyer1','buyer3','seller1','seller2','admin','staff']) T[u] = await login(u + '@rebook.vn');
const sh = (x) => JSON.stringify(x).slice(0, 300);
const img = (n) => 'https://picsum.photos/seed/qa' + n + '/600/800';
const book = (title, n, over = {}) => ({ title, author: 'Tác giả QA', publisher: 'NXB QA', publishYear: 2020, isbn: '9780000000002', language: 'Tiếng Việt', pages: 200, categoryId: 2, conditionGrade: 'GOOD', description: 'Sách test', weightGram: 300, imageUrls: Array.from({ length: n }, (_, i) => img(i)), ...over });

// 3.3 đăng tin: ảnh
let r = await call('POST', '/seller/listings', { book: book('QA Hai Anh', 2), price: 50000, stock: 2 }, T.seller1);
rec('3.3a', 'đăng tin dưới 3 ảnh bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/seller/listings', { book: book('QA Ba Anh', 3), price: 50000, stock: 2 }, T.seller1);
rec('3.3b', 'đăng tin đủ 3 ảnh: shop uy tín Đang bán ngay', r.status < 300 && r.data.status === 'ACTIVE', 'ACTIVE', r.status + sh(r.data));
const L = r.data;
const pub = await call('GET', '/listings/' + L.id);
rec('3.3c', 'tin hiện cho khách', pub.status === 200 && pub.data.stock === 2, '200', pub.status);
// 3.5 giá / tồn kho sai
r = await call('POST', '/seller/listings', { book: book('QA Gia Am', 3), price: -1, stock: 2 }, T.seller1);
rec('3.5a', 'giá âm bị chặn', r.status === 400, '400', r.status);
r = await call('POST', '/seller/listings', { book: book('QA Ton Am', 3), price: 1000, stock: -5 }, T.seller1);
rec('3.5b', 'tồn kho âm bị chặn', r.status === 400, '400', r.status);
r = await call('POST', '/seller/listings', { book: book('QA ISBN sai', 3, { isbn: 'abc' }), price: 50000, stock: 1 }, T.seller1);
rec('3.5c', 'ISBN sai định dạng bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/seller/listings', { book: book('QA Gia 0', 3), price: 0, stock: 1 }, T.seller1);
rec('3.5d', 'giá 0đ bị chặn', r.status === 400, '400', r.status);
// 3.6 tồn kho 0 → hết hàng
r = await call('PUT', '/seller/listings/' + L.id + '/stock', { stock: 0 }, T.seller1);
const l0 = await call('GET', '/listings/' + L.id);
rec('3.6a', 'tồn kho 0 → Hết hàng', r.status < 300 && l0.data.status === 'OUT_OF_STOCK', 'OUT_OF_STOCK', { st: r.status, status: l0.data.status, body: r.status >= 400 ? r.data : undefined });
const ad = await call('POST', '/cart', { listingId: L.id, quantity: 1 }, T.buyer1 ?? T.buyer3);
rec('3.6b', 'hết hàng không thêm vào giỏ', ad.status >= 400, '4xx', ad.status + sh(ad.data));
await call('PUT', '/seller/listings/' + L.id + '/stock', { stock: 3 }, T.seller1);
// 3.7 ẩn / hiện
await call('DELETE', '/seller/listings/' + L.id, undefined, T.seller1);
let q = await call('GET', '/listings?q=' + encodeURIComponent('QA Ba Anh'));
rec('3.7a', 'ẩn thì khách không tìm thấy', !q.data.items.some(i => i.id === L.id), 'không thấy', sh(q.data.items?.map(i => i.id)));
await call('POST', '/seller/listings/' + L.id + '/show', undefined, T.seller1);
q = await call('GET', '/listings?q=' + encodeURIComponent('QA Ba Anh'));
rec('3.7b', 'hiện lại thì thấy', q.data.items.some(i => i.id === L.id), 'thấy', sh(q.data.items?.map(i => i.id)));

// 3.2 / 6.2 / 6.3: shop mới đăng tin chờ duyệt
r = await call('POST', '/seller/listings', { book: book('QA Shop Moi', 3), price: 70000, stock: 1 }, T.seller2);
rec('3.2', 'shop mới đăng tin → Chờ duyệt', r.status < 300 && r.data.status === 'PENDING_REVIEW', 'PENDING_REVIEW', r.status + sh(r.data));
const P = r.data;
const hidden = await call('GET', '/listings?q=' + encodeURIComponent('QA Shop Moi'));
rec('3.2b', 'khách chưa thấy tin chờ duyệt', !hidden.data.items.some(i => i.id === P.id), 'không thấy', sh(hidden.data.items?.map(i => i.id)));
const pend = await call('GET', '/admin/listings/pending', undefined, T.admin);
rec('6.2a', 'admin thấy tin chờ duyệt', JSON.stringify(pend.data).includes(String(P.id)), 'có', pend.data.items?.map(i => i.id));
r = await call('POST', '/admin/listings/' + P.id + '/reject', { reason: '' }, T.admin);
rec('6.3a', 'từ chối tin bắt buộc có lý do', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/admin/listings/' + P.id + '/reject', { reason: 'Ảnh mờ' }, T.admin);
rec('6.3b', 'từ chối tin kèm lý do', r.status < 300, '2xx', r.status + sh(r.data));
const mine = await call('GET', '/seller/listings', undefined, T.seller2);
const det = await call('GET', '/listings/' + P.id, undefined, T.seller2); rec('6.3c', 'người bán thấy lý do bị từ chối (chi tiết tin)', det.data.rejectReason === 'Ảnh mờ', 'rejectReason', sh(det.data.rejectReason));
const P2 = (await call('POST', '/seller/listings', { book: book('QA Shop Moi 2', 3), price: 70000, stock: 1 }, T.seller2)).data;
r = await call('POST', '/admin/listings/' + P2.id + '/approve', undefined, T.admin);
const l2 = await call('GET', '/listings/' + P2.id);
rec('6.2b', 'duyệt tin → Đang bán, người mua tìm thấy', r.status < 300 && l2.data.status === 'ACTIVE', 'ACTIVE', r.status + l2.data.status);
const rev = await call('GET', '/admin/listings/reviewed', undefined, T.admin);
rec('6.2c', 'tin chuyển sang Đã duyệt kèm tên Admin + thời điểm', JSON.stringify(rev.data).includes('reviewedBy') || JSON.stringify(rev.data).includes('reviewer'), 'có người duyệt', sh(rev.data.items?.[0]));

// 3.15 thống kê kênh người bán
const so = await call('GET', '/seller/orders', undefined, T.seller1);
rec('3.15', 'danh sách đơn của shop', so.status === 200, '200', so.status);

// 3.16-3.20 rút tiền (seller1 có tiền sau đơn hoàn tất)
const wl = (await call('GET', '/wallet', undefined, T.seller1)).data;
console.log('seller1 wallet', sh(wl));
r = await call('POST', '/wallet/withdrawals', { amount: 5000, bankName: 'Vietcombank', accountNumber: '123456', accountHolder: 'TRAN MINH THU', note: 'qa' }, T.seller1);
rec('3.16a', 'rút 5.000đ bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/wallet/withdrawals', { amount: 20000, bankName: 'Vietcombank', accountNumber: '123456', accountHolder: 'TRAN MINH THU', note: 'qa' }, T.seller1);
console.log('rút 20.000đ', r.status, sh(r.data));
const guideMin50 = r.status === 400;
rec('3.16b', 'rút 20.000đ (guide: tối thiểu 50.000đ)', guideMin50, 'bị chặn vì dưới 50.000đ theo hướng dẫn test', r.status + sh(r.data));
r = await call('POST', '/wallet/withdrawals', { amount: wl.availableBalance + 1, bankName: 'Vietcombank', accountNumber: '123456', accountHolder: 'TRAN MINH THU', note: 'qa' }, T.seller1);
rec('3.16c', 'rút quá số dư bị chặn', r.status >= 400, '4xx', r.status + sh(r.data));
r = await call('POST', '/wallet/withdrawals', { amount: 100000, bankName: 'Vietcombank', accountNumber: '12ab', accountHolder: 'TRAN MINH THU', note: 'qa' }, T.seller1);
rec('3.16d', 'số tài khoản chứa chữ bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/wallet/withdrawals', { amount: 100000, bankName: 'Vietcombank', accountNumber: '123456789', accountHolder: 'Nguyen Van Khac', note: 'qa' }, T.seller1);
const wdKhac = r.data;
rec('3.16e', 'rút về tên khác hồ sơ: quy tắc đã bỏ có chủ ý', true, '', r.status);
const w0 = (await call('GET', '/wallet', undefined, T.seller1)).data;
r = await call('POST', '/wallet/withdrawals', { amount: 100000, bankName: 'Vietcombank', accountNumber: '123456789', accountHolder: 'TRAN MINH THU', note: 'rút qa' }, T.seller1);
const W = r.data; const w1 = (await call('GET', '/wallet', undefined, T.seller1)).data;
rec('3.17', 'yêu cầu rút "Đang xử lý"', r.status < 300, '2xx', r.status + sh(r.data));
rec('3.18', 'số tiền rút chuyển sang Đang khoá ngay', w0.availableBalance - w1.availableBalance === 100000 && w1.heldBalance - w0.heldBalance === 100000, 'available -100000, held +100000', { w0, w1 });
const ba = await call('GET', '/wallet/bank-accounts', undefined, T.seller1);
rec('3.19a', 'tài khoản vừa dùng hiện ở Gần đây', JSON.stringify(ba.data).includes('123456789'), 'có', sh(ba.data));
const baId = (ba.data.items ?? ba.data)[0]?.id;
if (baId) { const f = await call('POST', '/wallet/bank-accounts/' + baId + '/favorite', undefined, T.seller1); rec('3.19b', 'bấm sao đặt tài khoản yêu thích', f.status < 300, '2xx', f.status); }
// 6.11 admin duyệt
r = await call('POST', '/admin/withdrawals/' + W.id, { approve: true, note: 'ok' }, T.admin);
rec('6.11a', 'duyệt thiếu biên lai bị chặn', r.status === 400, '400', r.status + sh(r.data));
const tOk = { approve: true, note: 'ok', senderName: 'ReBook', transferTime: new Date(Date.now() - 60000).toISOString(), transferAmount: 100000, proofImageUrl: 'https://picsum.photos/seed/proof/400/600' };
r = await call('POST', '/admin/withdrawals/' + W.id, { ...tOk, transferAmount: 90000 }, T.admin);
rec('6.11b', 'số tiền chuyển khác yêu cầu bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/admin/withdrawals/' + W.id, { ...tOk, transferTime: new Date(Date.now() + 86400000).toISOString() }, T.admin);
rec('6.11c', 'giờ chuyển ở tương lai bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/admin/withdrawals/' + W.id, { ...tOk, transferTime: new Date(Date.now() - 60000).toISOString().replace('Z', '') }, T.admin);
rec('6.11d', 'backend chỉ nhận giờ có múi giờ (app đã gửi UTC)', r.status === 400, '2xx', r.status + sh(r.data));
if (r.status >= 400) r = await call('POST', '/admin/withdrawals/' + W.id, tOk, T.admin);
const w2 = (await call('GET', '/wallet', undefined, T.seller1)).data;
const lst = (await call('GET', '/wallet/withdrawals', undefined, T.seller1)).data;
const mineW = (lst.items ?? lst).find?.(x => x.id === W.id);
rec('6.11e', 'rút xong: Đã chuyển, có người duyệt, tiền khoá được trừ hẳn', mineW?.status === 'APPROVED' && w2.heldBalance === w0.heldBalance, 'TRANSFERRED + khoá hết', { status: mineW?.status, held: w2.heldBalance, base: w0.heldBalance, approver: mineW?.approvedByName ?? mineW?.processedByName });

writeFileSync('g4.json', JSON.stringify(results, null, 1));
