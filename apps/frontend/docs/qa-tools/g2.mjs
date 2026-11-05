import { call, login, rec, results } from './lib.mjs';
import { writeFileSync } from 'node:fs';
const T = {}; for (const u of ['buyer1','buyer2','seller1','seller2','admin','staff']) T[u] = await login(u + '@rebook.vn');
const b1 = T.buyer1;
const wallet = async (t = b1) => (await call('GET', '/wallet', undefined, t)).data;
const sh = (x) => JSON.stringify(x).slice(0, 350);

// dọn giỏ
let cart = await call('GET', '/cart', undefined, b1);
console.log('cart shape', sh(cart.data));
for (const g of cart.data.shops ?? []) for (const it of g.items ?? []) await call('DELETE', '/cart/' + it.listingId, undefined, b1);

// danh sách tin theo shop
const all = (await call('GET', '/listings?size=50')).data.items;
const byShop = {}; for (const l of all) (byShop[l.shop.id] ??= []).push(l);
console.log('shops', Object.entries(byShop).map(([k, v]) => k + ':' + v.map(l => l.id + '(' + l.stock + ')').join(',')).join(' | '));
const s1 = byShop[1] ?? [], s2 = byShop[2] ?? [];
const lowStock = all.find(l => l.stock === 1);

// 2.1 địa chỉ
let r = await call('POST', '/me/addresses', { receiverName: 'Pham Thu Ha', phone: '09abc', province: 'Hà Nội', district: 'Quận Ba Đình', ward: 'Phường Liễu Giai', detail: '12 Kim Mã', addressType: 'HOME', isDefault: false }, b1);
rec('2.4', 'địa chỉ với số điện thoại sai bị chặn', r.status === 400, '400', r.status + ' ' + sh(r.data));
r = await call('POST', '/me/addresses', { receiverName: 'Pham Thu Ha', phone: '0933333333', province: 'Hà Nội', district: 'Quận Ba Đình', ward: 'Phường Liễu Giai', detail: '12 Kim Mã', addressType: 'OFFICE', isDefault: false, latitude: 21.03, longitude: 105.82 }, b1);
rec('2.3', 'thêm địa chỉ Hà Nội, loại Văn phòng, có toạ độ', r.status === 200 || r.status === 201, '200/201', r.status + ' ' + sh(r.data));
const hn = r.data;
const addrs = (await call('GET', '/me/addresses', undefined, b1)).data;
rec('2.3b', 'địa chỉ lưu đúng loại + ghim', addrs.find(a => a.id === hn.id)?.addressType === 'OFFICE' && addrs.find(a => a.id === hn.id)?.latitude === 21.03, 'OFFICE + lat 21.03', addrs.find(a => a.id === hn.id));
const hcm = addrs.find(a => a.isDefault);

// 2.5 hồ sơ
r = await call('PUT', '/me', { fullName: 'Phạm Thu Hà', phone: '0933333333', avatarUrl: 'https://i.pravatar.cc/200?u=buyer1' });
rec('2.5a', 'sửa hồ sơ', r.status === 200, '200', r.status + sh(r.data));

// 2.6 yêu thích
const fav = s2[0].id;
r = await call('POST', '/listings/' + fav + '/favorite', undefined, b1);
let favs = (await call('GET', '/me/favorites', undefined, b1)).data;
rec('2.6a', 'thả tim thì có trong yêu thích', (favs.items ?? favs).some?.(x => (x.id ?? x.listingId) === fav), 'có', sh(favs));
r = await call('DELETE', '/listings/' + fav + '/favorite', undefined, b1);
favs = (await call('GET', '/me/favorites', undefined, b1)).data;
rec('2.6b', 'bỏ tim thì mất', !(favs.items ?? favs).some?.(x => (x.id ?? x.listingId) === fav), 'mất', sh(favs));

// 2.7 / 2.8 giỏ
const add = async (id, q = 1) => call('POST', '/cart', { listingId: id, quantity: q }, b1);
const a1 = await add(s1[0].id), a2 = await add(s1[1].id), a3 = await add(s2[0].id);
rec('2.7', 'thêm 2 sách shop 1 + 1 sách shop 2 vào giỏ', [a1, a2, a3].every(x => x.status < 300), '2xx', [a1.status, a2.status, a3.status]);
cart = (await call('GET', '/cart', undefined, b1)).data;
rec('2.7b', 'giỏ chia 2 shop', cart.shops?.length === 2, '2 nhóm', cart.shops?.map(g => g.shop?.name));
if (lowStock) { const x = await call('PUT', '/cart/' + lowStock.id, { quantity: 5 }, b1); const y = await add(lowStock.id, 5); rec('2.8', 'số lượng vượt tồn kho bị chặn', x.status >= 400 || y.status >= 400, '4xx', { put: x.status, post: y.status, stock: lowStock.stock }); await call('DELETE', '/cart/' + lowStock.id, undefined, b1); }
else console.log('NO stock=1 listing found; skip 2.8 api');

// 2.10 phí ship theo địa chỉ
const ids = [s1[0].id, s1[1].id, s2[0].id];
const pHcm = await call('POST', '/orders/checkout/preview', { addressId: hcm.id, listingIds: ids }, b1);
const pHn = await call('POST', '/orders/checkout/preview', { addressId: hn.id, listingIds: ids }, b1);
console.log('preview shape', sh(pHcm.data));
const shipOf = (p, shopIdx) => p.data.shops?.[shopIdx]?.shippingFee;
rec('2.10', 'phí ship đổi theo địa chỉ (cùng tỉnh rẻ hơn liên tỉnh)', pHcm.status === 200 && pHn.status === 200 && JSON.stringify(p => 0) && (pHcm.data.shippingFee ?? 0) !== (pHn.data.shippingFee ?? 0), 'khác nhau', { hcm: pHcm.data.shippingTotal, hn: pHn.data.shippingTotal, g: [pHcm.data.shops?.map(g => [g.shop?.name, g.shippingFee]), pHn.data.shops?.map(g => [g.shop?.name, g.shippingFee])] });

// 2.11 đặt giỏ 2 shop bằng ví
const w0 = await wallet();
r = await call('POST', '/orders/checkout', { addressId: hcm.id, paymentMethod: 'WALLET', listingIds: ids, note: 'qa 2.11' }, b1);
console.log('checkout shape', sh(r.data));
const orders1 = r.data.orders ?? r.data;
const w1 = await wallet();
const total = (orders1 ?? []).reduce((s, o) => s + (o.total ?? 0), 0);
rec('2.11a', 'tách 2 đơn (mỗi shop một đơn)', r.status < 300 && orders1.length === 2, '2 đơn', { st: r.status, n: orders1?.length, body: r.status >= 400 ? r.data : undefined });
rec('2.11b', 'ví bị trừ đúng tổng', w0.availableBalance - w1.availableBalance === total, 'trừ ' + total, { before: w0.availableBalance, after: w1.availableBalance, total });
rec('2.11c', 'trạng thái Chờ xác nhận', orders1.every(o => o.status === 'PENDING_CONFIRM'), 'PENDING_CONFIRM', orders1.map(o => o.status));
cart = (await call('GET', '/cart', undefined, b1)).data;
rec('2.11d', 'món đã đặt biến mất khỏi giỏ', (cart.shops ?? []).length === 0, 'giỏ rỗng', sh(cart));

// 2.13 COD
await add(s1[2]?.id ?? s1[0].id);
r = await call('POST', '/orders/checkout', { addressId: hcm.id, paymentMethod: 'COD', listingIds: [s1[2]?.id ?? s1[0].id], note: 'qa cod' }, b1);
const cod = (r.data.orders ?? [r.data])[0]; const w2 = await wallet();
rec('2.13', 'COD: Chờ xác nhận, không trừ ví', r.status < 300 && cod.status === 'PENDING_CONFIRM' && w2.availableBalance === w1.availableBalance, 'PENDING_CONFIRM, ví giữ', { st: r.status, status: cod?.status, w1: w1.availableBalance, w2: w2.availableBalance, body: r.status >= 400 ? r.data : undefined });

// 2.12 ZaloPay
const zl = s2[1]?.id ?? s2[0].id; await add(zl);
r = await call('POST', '/orders/checkout', { addressId: hcm.id, paymentMethod: 'ZALOPAY', listingIds: [zl], note: 'qa zalopay' }, b1);
console.log('zalopay checkout', sh(r.data));
const zOrder = (r.data.orders ?? [])[0]; const pay = r.data.payment;
rec('2.12a', 'ZaloPay: đơn chờ thanh toán + có payment', r.status < 300 && zOrder?.status === 'PENDING_PAYMENT' && !!pay, 'PENDING_PAYMENT + payment', { st: r.status, status: zOrder?.status, pay: sh(pay) });
if (pay?.code) {
  const pp = await call('POST', '/payments/' + pay.code + '/simulate', undefined, b1);
  const o = (await call('GET', '/orders/' + zOrder.id, undefined, b1)).data;
  rec('2.12b', 'trả xong thì đơn sang Chờ xác nhận', pp.status < 300 && o.status === 'PENDING_CONFIRM', 'PENDING_CONFIRM', { sim: pp.status, status: o.status });
}
// 2.14 trả lại bằng ví
await add(zl);
r = await call('POST', '/orders/checkout', { addressId: hcm.id, paymentMethod: 'ZALOPAY', listingIds: [zl], note: 'qa 2.14' }, b1);
const z2 = (r.data.orders ?? [])[0]; const wBefore = await wallet();
const pw = await call('POST', '/orders/' + z2.id + '/pay', { method: 'WALLET' }, b1);
const o2 = (await call('GET', '/orders/' + z2.id, undefined, b1)).data; const wAfter = await wallet();
rec('2.14', 'đơn chờ thanh toán trả lại bằng ví', pw.status < 300 && o2.status === 'PENDING_CONFIRM' && wBefore.availableBalance - wAfter.availableBalance === o2.total, 'PENDING_CONFIRM, trừ ' + o2.total, { st: pw.status, status: o2.status, diff: wBefore.availableBalance - wAfter.availableBalance, body: pw.status >= 400 ? pw.data : undefined });
const again = await call('POST', '/orders/' + z2.id + '/pay', { method: 'WALLET' }, b1);
rec('2.14b', 'không trả tiền hai lần', again.status >= 400, '4xx', again.status + sh(again.data));

// 2.16 huỷ đơn chờ xác nhận -> hoàn tiền
const wc0 = await wallet();
const cx = await call('POST', '/orders/' + z2.id + '/cancel', { reason: 'Đặt nhầm' }, b1);
const wc1 = await wallet();
rec('2.16a', 'huỷ đơn Chờ xác nhận hoàn tiền vào ví', cx.status < 300 && wc1.availableBalance - wc0.availableBalance === o2.total, 'hoàn ' + o2.total, { st: cx.status, diff: wc1.availableBalance - wc0.availableBalance, body: cx.status >= 400 ? cx.data : undefined });

// lưu ids để các nhóm sau dùng
writeFileSync('g2state.json', JSON.stringify({ orders1: orders1.map(o => ({ id: o.id, code: o.code, shopId: o.shopId, total: o.total })), cod: { id: cod?.id }, zOrder: { id: zOrder?.id }, hn, hcm }, null, 1));
writeFileSync('g2.json', JSON.stringify(results, null, 1));
