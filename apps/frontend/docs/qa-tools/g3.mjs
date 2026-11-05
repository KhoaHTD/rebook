import { call, login, rec, results } from './lib.mjs';
import { readFileSync, writeFileSync } from 'node:fs';
const T = {}; for (const u of ['buyer1','buyer2','seller1','seller2','admin','staff']) T[u] = await login(u + '@rebook.vn');
const b1 = T.buyer1;
const st = JSON.parse(readFileSync('g2state.json', 'utf8'));
const sh = (x) => JSON.stringify(x).slice(0, 300);
const wallet = async (t) => (await call('GET', '/wallet', undefined, t)).data;
const ord = async (id, t = b1) => (await call('GET', '/orders/' + id, undefined, t)).data;
const o2 = st.orders1.find(o => o.shopId === 2), o1 = st.orders1.find(o => o.shopId === 1);
console.log('orders', sh(st.orders1), 'cod', st.cod.id, 'z', st.zOrder.id);

// 2.5 hồ sơ (bù)
let r = await call('PUT', '/me', { fullName: 'Phạm Thu Hà', phone: '0933333333', avatarUrl: 'https://i.pravatar.cc/200?u=buyer1' }, b1);
rec('2.5a', 'sửa hồ sơ', r.status === 200, '200', r.status + sh(r.data));
r = await call('PUT', '/me', { fullName: 'Phạm Thu Hà', phone: 'abc', avatarUrl: '' }, b1);
rec('2.5b', 'sửa hồ sơ với số điện thoại sai bị chặn', r.status === 400, '400', r.status);

// 3.8-3.10 seller1: xác nhận → giao → đã giao ; người mua nhận ; tiền người bán
const w1a = await wallet(T.seller1);
r = await call('POST', '/seller/orders/' + o1.id + '/confirm', undefined, T.seller1);
rec('3.8', 'seller1 xác nhận đơn', r.status < 300 && (await ord(o1.id)).status === 'PREPARING', 'PREPARING', r.status + sh(r.data));
r = await call('POST', '/seller/orders/' + o1.id + '/ship', { trackingCode: 'QA123456' }, T.seller1);
let o = await ord(o1.id);
rec('3.9', 'giao hàng nhập mã vận đơn', r.status < 300 && o.status === 'SHIPPING' && o.trackingCode === 'QA123456', 'SHIPPING + mã', { st: r.status, status: o.status, tr: o.trackingCode });
r = await call('POST', '/seller/orders/' + o1.id + '/delivered', undefined, T.seller1);
o = await ord(o1.id);
rec('3.10', 'đã giao', r.status < 300 && o.status === 'DELIVERED', 'DELIVERED', r.status + o.status);
const wMid = await wallet(T.seller1);
r = await call('POST', '/orders/' + o1.id + '/confirm-received', undefined, b1);
o = await ord(o1.id); const w1b = await wallet(T.seller1);
const gross = o.subtotal ?? (o.total - o.shippingFee);
console.log('order detail keys', Object.keys(o).join(','), 'subtotal', o.subtotal, 'ship', o.shippingFee, 'total', o.total);
rec('2.18a', 'xác nhận đã nhận → Hoàn tất', r.status < 300 && o.status === 'COMPLETED', 'COMPLETED', r.status + o.status);
const gain = w1b.availableBalance - w1a.availableBalance;
rec('2.18b', 'tiền về ví người bán = giá sách + ship − 5% giá sách', gain === gross + o.shippingFee - Math.round(gross * 0.05), 'tăng ' + (gross + o.shippingFee - Math.round(gross * 0.05)), { gain, gross, held_before: wMid.heldBalance, held_after: w1b.heldBalance });
r = await call('POST', '/orders/' + o1.id + '/review', { rating: 5, comment: 'Sách đẹp' }, b1);
rec('2.19a', 'đánh giá shop', r.status < 300, '2xx', r.status + sh(r.data));
r = await call('POST', '/orders/' + o1.id + '/review', { rating: 4, comment: 'Lần hai' }, b1);
rec('2.19b', 'mỗi đơn chỉ đánh giá một lần', r.status >= 400, '4xx', r.status + sh(r.data));
const shop1 = (await call('GET', '/shops/1')).data;
rec('2.19c', 'sao của shop cập nhật', shop1.ratingCount >= 1, 'ratingCount>=1', sh(shop1));
r = await call('POST', '/orders/' + o1.id + '/review', { rating: 9, comment: 'x' }, b1);

// seller2: đơn o2 xác nhận → xin huỷ khi PREPARING
await call('POST', '/seller/orders/' + o2.id + '/confirm', undefined, T.seller2);
const wb0 = await wallet(b1);
r = await call('POST', '/orders/' + o2.id + '/cancel', { reason: 'Muốn đổi' }, b1);
o = await ord(o2.id);
rec('2.16b', 'xin huỷ đơn Đang chuẩn bị chỉ gửi yêu cầu', r.status < 300 && o.status === 'PREPARING' && o.cancelRequested === true, 'PREPARING + cancelRequested', { st: r.status, status: o.status, cr: o.cancelRequested });
r = await call('POST', '/seller/orders/' + o2.id + '/cancel-request', { approve: false, note: 'Đã đóng gói' }, T.seller2);
o = await ord(o2.id);
rec('3.12a', 'seller từ chối huỷ: đơn giữ nguyên', r.status < 300 && o.status === 'PREPARING', 'PREPARING', r.status + o.status + sh(o.history?.slice(-1)));
r = await call('POST', '/orders/' + o2.id + '/cancel', { reason: 'Lần hai' }, b1);
r = await call('POST', '/seller/orders/' + o2.id + '/cancel-request', { approve: true, note: 'ok' }, T.seller2);
o = await ord(o2.id); const wb1 = await wallet(b1);
rec('3.12b', 'seller đồng ý huỷ: đơn huỷ, hoàn tiền', r.status < 300 && o.status === 'CANCELLED' && wb1.availableBalance - wb0.availableBalance === o.total, 'CANCELLED, hoàn ' + o.total, { st: r.status, status: o.status, diff: wb1.availableBalance - wb0.availableBalance });

// zOrder (shop 2, đã trả ZaloPay): giao thất bại
await call('POST', '/seller/orders/' + st.zOrder.id + '/confirm', undefined, T.seller2);
await call('POST', '/seller/orders/' + st.zOrder.id + '/ship', { trackingCode: 'QAFAIL1' }, T.seller2);
const wf0 = await wallet(b1);
r = await call('POST', '/seller/orders/' + st.zOrder.id + '/delivery-failed', { reason: 'Không liên lạc được' }, T.seller2);
o = await ord(st.zOrder.id); const wf1 = await wallet(b1);
rec('3.11', 'giao thất bại, hoàn tiền người mua', r.status < 300 && o.status === 'FAILED_DELIVERY' && wf1.availableBalance - wf0.availableBalance === o.total, 'FAILED_DELIVERY + hoàn ' + o.total, { st: r.status, status: o.status, diff: wf1.availableBalance - wf0.availableBalance, paidOnline: o.paid });

// trả hàng: cần 3 đơn đã giao
async function makeDelivered(sellerTok, listingId, addrId) {
  await call('POST', '/cart', { listingId, quantity: 1 }, b1);
  const c = await call('POST', '/orders/checkout', { addressId: addrId, paymentMethod: 'WALLET', listingIds: [listingId], note: 'qa return' }, b1);
  const id = c.data.orders[0].id;
  await call('POST', '/seller/orders/' + id + '/confirm', undefined, sellerTok);
  await call('POST', '/seller/orders/' + id + '/ship', { trackingCode: 'QARET' + id }, sellerTok);
  await call('POST', '/seller/orders/' + id + '/delivered', undefined, sellerTok);
  return id;
}
const A = st.hcm.id;
const rA = await makeDelivered(T.seller1, 2, A), rB = await makeDelivered(T.seller1, 3, A), rC = await makeDelivered(T.seller1, 4, A);
const img = 'https://picsum.photos/seed/qa/400/300';
r = await call('POST', '/orders/' + rA + '/return', { reason: 'MISSING_PAGES', description: 'Thiếu trang', images: [] }, b1);
rec('2.20a', 'trả hàng không kèm ảnh bị chặn (1–10 ảnh)', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/orders/' + rA + '/return', { reason: 'MISSING_PAGES', description: 'Thiếu trang', images: Array(11).fill(img) }, b1);
rec('2.20b', 'trả hàng 11 ảnh bị chặn', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/orders/' + rA + '/return', { reason: 'MISSING_PAGES', description: 'Thiếu trang 20-30', images: [img, img] }, b1);
o = await ord(rA);
rec('2.20c', 'yêu cầu trả hàng kèm hạn shop trả lời', r.status < 300 && o.status === 'RETURN_REQUESTED' && !!o.returnRequest?.respondBy, 'RETURN_REQUESTED + respondBy', { st: r.status, status: o.status, respondBy: o.returnRequest?.respondBy, body: r.status >= 400 ? r.data : undefined });
r = await call('POST', '/orders/' + rA + '/confirm-received', undefined, b1);
o = await ord(rA);
rec('2.21', 'đang yêu cầu trả hàng mà bấm Đã nhận → rút yêu cầu, hoàn tất', r.status < 300 && o.status === 'COMPLETED', 'COMPLETED', r.status + o.status);
// shop đồng ý
await call('POST', '/orders/' + rB + '/return', { reason: 'WRONG_EDITION', description: 'Sai ấn bản', images: [img] }, b1);
const wr0 = await wallet(b1);
r = await call('POST', '/seller/orders/' + rB + '/return-decision', { approve: true, note: 'Đồng ý' }, T.seller1);
o = await ord(rB); const wr1 = await wallet(b1);
rec('3.14a', 'shop đồng ý trả hàng: hoàn tiền', r.status < 300 && o.status === 'RETURNED' && wr1.availableBalance - wr0.availableBalance === o.total, 'RETURNED + hoàn ' + o.total, { st: r.status, status: o.status, diff: wr1.availableBalance - wr0.availableBalance });
// shop từ chối → admin
await call('POST', '/orders/' + rC + '/return', { reason: 'OTHER_NOT_AS_DESCRIBED', description: 'Không như mô tả', images: [img] }, b1);
r = await call('POST', '/seller/orders/' + rC + '/return-decision', { approve: false, note: 'Sách đúng mô tả' }, T.seller1);
const disp = (await call('GET', '/admin/disputes', undefined, T.admin)).data;
rec('3.14b', 'shop từ chối: sang Admin phân xử', r.status < 300 && JSON.stringify(disp).includes(String(rC)), 'có trong khiếu nại', { st: r.status, n: disp.items?.length });
const wd0 = await wallet(b1);
r = await call('POST', '/admin/disputes/' + rC + '/resolve', { approve: true, note: 'Hoàn tiền người mua' }, T.admin);
o = await ord(rC); const wd1 = await wallet(b1);
rec('6.13a', 'admin hoàn tiền người mua', r.status < 300 && o.status === 'RETURNED' && wd1.availableBalance - wd0.availableBalance === o.total, 'RETURNED + hoàn ' + o.total, { st: r.status, status: o.status, diff: wd1.availableBalance - wd0.availableBalance });
const resolved = (await call('GET', '/admin/disputes?resolved=true', undefined, T.admin)).data;
rec('6.13b', 'khiếu nại sang danh sách Đã phân xử kèm tên Admin + thời điểm', JSON.stringify(resolved).includes('resolvedBy') || JSON.stringify(resolved).includes('resolvedByName'), 'có người xử lý', sh(resolved));

// ví: nạp tiền
r = await call('POST', '/wallet/top-up', { amount: 5000 }, b1);
rec('2.23a', 'nạp 5.000đ bị chặn (tối thiểu 10.000)', r.status === 400, '400', r.status + sh(r.data));
r = await call('POST', '/wallet/top-up', { amount: 10000 }, b1);
rec('2.23b', 'nạp 10.000đ tạo giao dịch ZaloPay', r.status < 300, '2xx', r.status + sh(r.data));
const tx = (await call('GET', '/wallet/transactions?size=5', undefined, b1)).data;
rec('2.24', 'lịch sử giao dịch có loại, số tiền, số dư sau, giờ', !!tx.items?.[0] && ['type', 'availableChange', 'availableAfter', 'createdAt'].every(k => k in tx.items[0]), 'đủ trường', Object.keys(tx.items?.[0] ?? {}));
const noti = (await call('GET', '/notifications?size=10', undefined, b1)).data; const uc = (await call('GET', '/notifications/unread-count', undefined, b1)).data;
rec('2.25a', 'có thông báo đơn hàng', (noti.items?.length ?? 0) > 0, '>0', sh(uc));
await call('POST', '/notifications/read-all', undefined, b1); const uc2 = (await call('GET', '/notifications/unread-count', undefined, b1)).data;
rec('2.25b', 'đánh dấu đã đọc làm mất số đếm', JSON.stringify(uc2).includes('0'), 'count=0', sh(uc2));

writeFileSync('g3state.json', JSON.stringify({ o1, o2, rA, rB, rC }, null, 1));
writeFileSync('g3.json', JSON.stringify(results, null, 1));
