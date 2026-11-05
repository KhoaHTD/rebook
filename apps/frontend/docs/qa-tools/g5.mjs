import { call, login, rec, results } from './lib.mjs';
import { writeFileSync } from 'node:fs';
const T = {}; for (const u of ['buyer1','buyer2','buyer3','seller1','seller2','admin','staff']) T[u] = await login(u + '@rebook.vn');
const sh = (x) => JSON.stringify(x).slice(0, 320);
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const wallet = async (t) => (await call('GET', '/wallet', undefined, t)).data;
const lot = async (id, t = T.buyer1) => { const d = (await call('GET', '/lots/' + id, undefined, t)).data; const l = { ...d.lot }; if (l.status === 'OPEN') { const s = (await call('GET', '/sessions/1/state', undefined, t)).data; if (s.currentLot?.id === id) Object.assign(l, s.currentLot); } return l; };
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a);

// ---- trước phiên ----
const regS = await call('POST', '/sessions/1/register', { agreeRules: true }, T.staff);
rec('4.9s', 'Staff đăng ký tham gia đấu giá bị chặn', regS.status >= 400, '403 (người vận hành không đấu giá)', regS.status + sh(regS.data));
const regA = await call('POST', '/sessions/1/register', { agreeRules: true }, T.admin);
rec('4.9a', 'Admin đăng ký tham gia đấu giá bị chặn', regA.status >= 400, '403', regA.status + sh(regA.data));

// tài khoản mới: chưa có ví → đăng ký phiên
const mail = 'auc' + (Date.now() % 100000) + '@rebook.vn';
let r = await call('POST', '/auth/register', { email: mail, password: 'Rebook@123', fullName: 'Auction Tester', phone: '0907' + String(Date.now()).slice(-6) });
const nt = r.data.accessToken;
let reg = await call('POST', '/sessions/1/register', { agreeRules: true }, nt);
rec('4.9b', 'tài khoản mới chưa xác thực SĐT bị chặn đăng ký', reg.status >= 400, '4xx', reg.status + sh(reg.data));
let o = await call('POST', '/auth/send-otp', { purpose: 'VERIFY_PHONE' }, nt); await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_PHONE', code: o.data.devOtp }, nt);
o = await call('POST', '/auth/send-otp', { purpose: 'VERIFY_EMAIL' }, nt); await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_EMAIL', code: o.data.devOtp }, nt);
reg = await call('POST', '/sessions/1/register', { agreeRules: true }, nt);
rec('4.9c', 'thiếu số dư ví thì báo lỗi, không khoá tiền', reg.status >= 400, '4xx (thiếu ví)', reg.status + sh(reg.data));
const tp = await call('POST', '/wallet/top-up', { amount: 500000 }, nt);
const code = tp.data.payment?.code ?? tp.data.code ?? tp.data.paymentCode;
console.log('topup resp', sh(tp.data));
if (code) await call('POST', '/payments/' + code + '/simulate', undefined, nt);
reg = await call('POST', '/sessions/1/register', { agreeRules: true }, nt);
const wnt = await wallet(nt);
rec('4.9d', 'đủ ví thì đăng ký, cọc vào Đang khoá, có số bài', reg.status < 300 && !!reg.data.paddle && wnt.heldBalance === 500000, 'paddle + held 500000', { st: reg.status, paddle: reg.data.paddle, w: wnt });
// theo dõi lô / phiên (4.8)
const wl = await call('POST', '/lots/3/watch', undefined, T.buyer1); const ws = await call('POST', '/sessions/1/watch', undefined, T.buyer1);
rec('4.8', 'theo dõi lô và phiên', wl.status < 300 && ws.status < 300, '2xx', [wl.status, ws.status]);
const wb = {}; for (const u of ['buyer1', 'buyer2', 'buyer3']) wb[u] = await wallet(T[u]);
log('wallets before', sh(wb));

// ---- mở phiên ----
const stt = await call('POST', '/admin/sessions/1/start', undefined, T.admin);
rec('6.8', 'admin mở phiên', stt.status < 300, '2xx', stt.status + sh(stt.data));
async function waitOpen(id, ms = 150000) { const t0 = Date.now(); while (Date.now() - t0 < ms) { const l = await lot(id); if (l.status === 'OPEN') return l; await sleep(700); } return null; }
async function waitClosed(id, ms = 200000) { const t0 = Date.now(); while (Date.now() - t0 < ms) { const l = await lot(id); if (!['OPEN', 'SCHEDULED'].includes(l.status)) return l; await sleep(700); } return null; }

// ---- lô 1 (id 2) ----
let L = await waitOpen(2); log('lot2 open', sh({ price: L?.currentPrice, next: L?.nextMinBid, inc: L?.increment, ends: L?.endsAt }));
if (L) {
  const before = L.nextMinBid;
  let b = await call('POST', '/lots/2/bids', { amount: before }, T.buyer1);
  let l = await lot(2, T.buyer2);
  rec('4.11a', 'buyer1 trả giá một bước', b.status < 300 && l.currentPrice === before, 'giá = ' + before, { st: b.status, price: l.currentPrice, body: b.status >= 400 ? b.data : undefined });
  rec('4.11b', 'người dẫn hiện bằng số bài, không lộ tên', !!l.leadingPaddle && !JSON.stringify(l).includes('Phạm'), 'paddle, không tên', { paddle: l.leadingPaddle });
  const next = l.nextMinBid;
  const [x, y] = await Promise.all([call('POST', '/lots/2/bids', { amount: next }, T.buyer2), call('POST', '/lots/2/bids', { amount: next }, T.buyer3)]);
  const okc = [x, y].filter(z => z.status < 300).length;
  rec('4.14', 'hai người bấm cùng mức cùng lúc: chỉ một người được', okc === 1 && [x, y].some(z => z.status === 409), '1 thành công + 1 409 PRICE_CHANGED', { x: x.status + ' ' + (x.data?.code ?? ''), y: y.status + ' ' + (y.data?.code ?? '') });
  const over = await call('POST', '/lots/2/bids', { amount: 6000000 }, T.buyer1);
  rec('4.15', 'trả vượt hạn mức (cọc × 10 = 5.000.000đ) bị từ chối', over.status >= 400, '4xx', over.status + sh(over.data));
  const low = await call('POST', '/lots/2/bids', { amount: 1 }, T.buyer1);
  rec('4.15b', 'trả giá thấp hơn giá hiện tại bị từ chối', low.status >= 400, '4xx', low.status + sh(low.data));
  const px = await call('PUT', '/lots/2/proxy-bid', { maxAmount: 900000 }, T.buyer2);
  console.log('proxy resp', px.status, sh(px.data));
  l = await lot(2, T.buyer1);
  const bid1 = await call('POST', '/lots/2/bids', { amount: l.nextMinBid }, T.buyer1);
  const l2 = await lot(2, T.buyer1);
  rec('4.12', 'proxy của buyer2 tự trả thay khi buyer1 trả tiếp', l2.currentPrice > l.nextMinBid || l2.leadingPaddle !== l.leadingPaddle, 'buyer2 tự vượt lên', { px: px.status, before: l.currentPrice, bid: l.nextMinBid, after: l2.currentPrice, lead: l2.leadingPaddle });
  // soft close
  const t0 = Date.now(); let cur;
  while (Date.now() - t0 < 120000) { cur = await lot(2, T.buyer1); const rem = (new Date(cur.endsAt) - Date.now()) / 1000; if (cur.status !== 'OPEN' || rem < 12) break; await sleep(700); }
  if (cur.status === 'OPEN') {
    const endsBefore = new Date(cur.endsAt).getTime();
    const sb = await call('POST', '/lots/2/bids', { amount: cur.nextMinBid }, T.buyer1);
    const after = await lot(2, T.buyer1); const ext = (new Date(after.endsAt).getTime() - endsBefore) / 1000;
    rec('4.13', 'trả giá khi còn dưới 15 giây thì đồng hồ gia hạn', sb.status < 300 && ext > 1, 'endsAt tăng (về 15 giây)', { st: sb.status, extendedSec: ext, remAfter: (new Date(after.endsAt) - Date.now()) / 1000 });
  } else rec('4.13', 'soft close', false, 'cần lô còn mở', cur.status);
  const closed = await waitClosed(2);
  rec('4.17a', 'lô 1 hết giờ có kết quả', !!closed && !!closed.closeResult, 'SOLD/UNSOLD', closed && { status: closed.status, result: closed.closeResult, hammer: closed.hammerPrice, price: closed.currentPrice });
  log('lot2 closed', sh(closed));
}
// ---- lô 2 (id 1): không ai trả giá ----
L = await waitOpen(1); log('lot1 open'); const c1 = await waitClosed(1);
rec('4.17b', 'lô không ai trả giá → Không bán', c1?.closeResult === 'UNSOLD' || c1?.status === 'UNSOLD', 'UNSOLD', c1 && { status: c1.status, result: c1.closeResult });
// ---- lô 3 (id 3): buyer3 trả dưới giá sàn? ----
L = await waitOpen(3); log('lot3 open', sh({ next: L?.nextMinBid }));
if (L) { const b = await call('POST', '/lots/3/bids', { amount: L.nextMinBid }, T.buyer3); log('buyer3 bid lot3', b.status); }
const c3 = await waitClosed(3); log('lot3 closed', sh(c3));
rec('4.17c', 'lô 3 kết quả', !!c3, 'SOLD/UNSOLD', c3 && { status: c3.status, result: c3.closeResult, hammer: c3.hammerPrice, price: c3.currentPrice });
await sleep(8000);
// ---- sau phiên ----
const res = await call('GET', '/sessions/1/results', undefined, T.buyer1);
rec('4.17d', 'hết phiên xem được kết quả từng lô', res.status === 200, '200', res.status + sh(res.data));
const wa = {}; for (const u of ['buyer1', 'buyer2', 'buyer3']) wa[u] = await wallet(T[u]);
log('wallets after', sh(wa));
const inv = {};
for (const u of ['buyer1', 'buyer2', 'buyer3']) { const os = (await call('GET', '/orders?size=50', undefined, T[u])).data.items.filter(x => x.orderType === 'AUCTION'); inv[u] = os.map(x => ({ id: x.id, status: x.status, total: x.total, amountDue: x.amountDue })); }
log('invoices', sh(inv));
const losers = ['buyer1', 'buyer2', 'buyer3'].filter(u => inv[u].length === 0);
for (const u of losers) rec('4.18-' + u, u + ' không thắng: cọc hoàn về khả dụng', wa[u].heldBalance === wb[u].heldBalance - 500000 && wa[u].availableBalance === wb[u].availableBalance + 500000, 'held -500000, available +500000', { before: wb[u], after: wa[u] });
const winner = ['buyer1', 'buyer2', 'buyer3'].find(u => inv[u].length > 0);
if (winner) {
  const inv0 = inv[winner][0]; const full = (await call('GET', '/orders/' + inv0.id, undefined, T[winner])).data;
  log('invoice detail', sh({ subtotal: full.subtotal, premium: full.buyerPremium, ship: full.shippingFee, dep: full.depositApplied, total: full.total, due: full.amountDue, payDue: full.paymentDueAt }));
  rec('4.19', 'hoá đơn = giá búa + 10% phí − cọc', full.buyerPremium === Math.round(full.subtotal * 0.1) && full.total - full.depositApplied === full.amountDue, 'premium=10%, due=total−cọc', { subtotal: full.subtotal, premium: full.buyerPremium, ship: full.shippingFee, dep: full.depositApplied, total: full.total, due: full.amountDue });
  const cancel = await call('POST', '/orders/' + inv0.id + '/cancel', { reason: 'đổi ý' }, T[winner]);
  rec('4.20a', 'hoá đơn đấu giá không huỷ được', cancel.status >= 400, '4xx', cancel.status + sh(cancel.data));
  const addrs = (await call('GET', '/me/addresses', undefined, T[winner])).data;
  const dop = await call('POST', '/orders/' + inv0.id + '/delivery-option', { addressId: addrs[0].id, pickupAtWarehouse: false }, T[winner]);
  const pay = await call('POST', '/orders/' + inv0.id + '/pay', { method: 'WALLET' }, T[winner]);
  const after = (await call('GET', '/orders/' + inv0.id, undefined, T[winner])).data;
  rec('4.20b', 'giao tận nơi + trả bằng ví', dop.status < 300 && pay.status < 300 && after.status === 'PENDING_CONFIRM', 'PENDING_CONFIRM', { dop: dop.status, pay: pay.status + ' ' + sh(pay.data).slice(0, 120), status: after.status });
  const staffOrders = await call('GET', '/staff/orders', undefined, T.staff);
  const so = staffOrders.data.items?.find(x => x.id === inv0.id);
  rec('5.10a', 'Staff thấy đơn đấu giá đã thanh toán', !!so, 'có trong danh sách', { n: staffOrders.data.items?.length, found: !!so });
  if (so) {
    const c = await call('POST', '/staff/orders/' + so.id + '/confirm', undefined, T.staff);
    const sp = await call('POST', '/staff/orders/' + so.id + '/ship', { trackingCode: 'QAAUC1' }, T.staff);
    const dl = await call('POST', '/staff/orders/' + so.id + '/delivered', undefined, T.staff);
    const fin = (await call('GET', '/orders/' + so.id, undefined, T[winner])).data;
    rec('5.10b', 'Staff xác nhận → giao → đã giao', c.status < 300 && sp.status < 300 && dl.status < 300 && fin.status === 'DELIVERED', 'DELIVERED', { c: c.status, sp: sp.status, dl: dl.status, status: fin.status });
    const rc = await call('POST', '/orders/' + so.id + '/confirm-received', undefined, T[winner]);
    const sell = fin.items?.[0]; log('winner confirm', rc.status);
  }
}
const hist = await call('GET', '/lots/2/bids', undefined, T.buyer1);
rec('4.21', 'lịch sử trả giá có trong trạng thái phiên (GET /lots/{id}/bids không có, trả 405)', hist.status === 405, '405', hist.status);
const my = await call('GET', '/me/registrations', undefined, T.buyer1);
rec('4.21b', 'Đấu giá của tôi hiện phiên đã tham gia', my.status === 200 && JSON.stringify(my.data).includes('"sessionId":1'), 'có', sh(my.data));
writeFileSync('g5.json', JSON.stringify(results, null, 1));
log('DONE');
