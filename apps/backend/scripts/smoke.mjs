// Kiểm tra nhanh toàn bộ API trên backend đang chạy với dữ liệu demo (sau scripts/reset-demo).
//   node scripts/smoke.mjs [http://localhost:8081]
// Đăng nhập từng vai, gọi mọi endpoint đọc chính (phải 200) và chạy vài luồng ghi: yêu thích, giỏ hàng, đặt đơn COD,
// shop xác nhận / giao, Admin duyệt tin, khoá / mở khoá người dùng, rút tiền, đăng ký phiên đấu giá.
const BASE = process.argv[2] || 'http://localhost:8081';
const PASSWORD = 'Rebook@123';
let pass = 0;
const failures = [];

async function call(method, path, { token, body, expect } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    redirect: 'manual',
  });
  let data = null;
  try { data = await res.json(); } catch { /* không có thân JSON */ }
  const ok = expect ? expect.includes(res.status) : res.status >= 200 && res.status < 300;
  const label = `${method} ${path}`;
  if (ok) pass++;
  else failures.push(`${label} → ${res.status} ${data?.code ?? ''} ${data?.message ?? ''}`.trim());
  return { status: res.status, data, ok };
}

async function login(email) {
  const r = await call('POST', '/auth/login', { body: { email, password: PASSWORD } });
  if (!r.ok) throw new Error(`Không đăng nhập được ${email}: ${r.status}`);
  return r.data.accessToken;
}

const items = (d) => (Array.isArray(d) ? d : d?.items ?? []);

const [admin, staff, seller1, seller2, buyer1, buyer2] = await Promise.all(
  ['admin', 'staff', 'seller1', 'seller2', 'buyer1', 'buyer2'].map((u) => login(`${u}@rebook.vn`)),
);

// ---- Đọc: công khai ----
for (const p of ['/categories', '/listings?size=10', '/listings?q=a&size=5', '/listings?sort=popular&size=5', '/sessions', '/shops/1', '/shops/1/reviews']) {
  await call('GET', p);
}
const listings = items((await call('GET', '/listings?size=20')).data);
const sessions = items((await call('GET', '/sessions')).data);
await call('GET', `/listings/${listings[0].id}`);
for (const s of sessions) { await call('GET', `/sessions/${s.id}`); await call('GET', `/sessions/${s.id}/state`); }
const ended = sessions.find((s) => s.status === 'ENDED');
if (ended) await call('GET', `/sessions/${ended.id}/results`);

// ---- Đọc: người mua / người bán ----
for (const p of ['/me', '/me/addresses', '/me/favorites', '/me/registrations', '/me/watched-sessions', '/me/watching', '/me/debts', '/wallet', '/wallet/withdrawable',
  '/wallet/transactions', '/wallet/withdrawals', '/wallet/bank-accounts', '/orders', '/cart', '/notifications', '/notifications/unread-count', '/consignments']) {
  await call('GET', p, { token: buyer1 });
}
for (const p of ['/me/shop', '/seller/orders', '/seller/listings', '/wallet', '/consignments', '/wallet/withdrawable']) await call('GET', p, { token: seller1 });
await call('GET', '/wallet/withdrawable', { token: await login('seller4@rebook.vn') });

// ---- Đọc: Staff / Admin ----
for (const p of ['/staff/consignments', '/staff/appointments', '/staff/warehouse', '/staff/orders', '/staff/orders/in-transit', '/staff/lots/inspecting', '/staff/warehouse-incidents']) {
  await call('GET', p, { token: staff });
}
for (const p of ['/admin/dashboard', '/admin/reports', '/admin/reports?from=2026-10-01&to=2026-10-31', '/admin/users', '/admin/users?q=buyer', '/admin/listings/pending', '/admin/listings/reviewed',
  '/admin/withdrawals', '/admin/disputes', '/admin/disputes?resolved=true', '/admin/cod/pending', '/admin/activity-logs', '/admin/sessions', '/admin/configs',
  '/admin/platform-wallet', '/admin/lots/ready', '/staff/consignments']) {
  await call('GET', p, { token: admin });
}

// ---- Quyền: người thường không vào được khu quản trị ----
await call('GET', '/admin/dashboard', { token: buyer1, expect: [403] });
await call('GET', '/staff/consignments', { token: buyer1, expect: [403] });
await call('GET', '/admin/dashboard', { expect: [401, 403] });
await call('GET', '/admin/reports?from=2026-11-10&to=2026-11-01', { token: admin, expect: [400] });

// ---- Ghi: yêu thích, giỏ hàng, đặt đơn COD ----
const l1 = listings.find((l) => (l.stock ?? 1) > 0) ?? listings[0];
await call('POST', `/listings/${l1.id}/favorite`, { token: buyer2 });
await call('DELETE', `/listings/${l1.id}/favorite`, { token: buyer2 });
await call('POST', '/cart', { token: buyer2, body: { listingId: l1.id, quantity: 1 } });
const addr = items((await call('GET', '/me/addresses', { token: buyer2 })).data)[0];
const preview = await call('POST', '/orders/checkout/preview', { token: buyer2, body: { addressId: addr.id, paymentMethod: 'COD' } });
const placed = await call('POST', '/orders/checkout', {
  token: buyer2,
  body: { addressId: addr.id, paymentMethod: 'COD', expectedTotal: preview.data?.total },
});
const orders = placed.ok ? (Array.isArray(placed.data) ? placed.data : placed.data?.orders ?? [placed.data]) : [];
if (orders[0]?.id) {
  const id = orders[0].id;
  await call('GET', `/orders/${id}`, { token: buyer2 });
  const shopOwner = orders[0].shop?.id === 2 || orders[0].shopId === 2 ? seller2 : seller1;
  await call('POST', `/seller/orders/${id}/confirm`, { token: shopOwner });
  await call('POST', `/seller/orders/${id}/ship`, { token: shopOwner, body: { trackingCode: 'SMOKE123' } });
}

// ---- Ghi: Admin duyệt tin chờ, khoá / mở khoá, cấu hình ----
const pending = items((await call('GET', '/admin/listings/pending', { token: admin })).data);
if (pending[0]) await call('POST', `/admin/listings/${pending[0].id}/approve`, { token: admin });
if (pending[1]) await call('POST', `/admin/listings/${pending[1].id}/reject`, { token: admin, body: { reason: 'Kiểm thử tự động: ảnh chưa rõ' } });
const victim = items((await call('GET', '/admin/users?q=buyer7', { token: admin })).data)[0];
if (victim) {
  await call('POST', `/admin/users/${victim.id}/lock`, { token: admin, body: { reason: 'Kiểm thử tự động' } });
  await call('POST', `/admin/users/${victim.id}/unlock`, { token: admin });
}

// ---- Ghi: rút tiền (người bán yêu cầu, Admin từ chối) ----
const w = await call('POST', '/wallet/withdrawals', {
  token: seller1,
  body: { amount: 100000, bankName: 'Vietcombank', accountNumber: '0071000123456', accountHolder: 'TRAN MINH THU' },
});
if (w.ok && w.data?.id) await call('POST', `/admin/withdrawals/${w.data.id}`, { token: admin, body: { approve: false, note: 'Kiểm thử tự động' } });

// ---- Ghi: đăng ký phiên đấu giá sắp tới ----
const open = sessions.find((s) => s.status === 'PUBLISHED');
if (open) await call('POST', `/sessions/${open.id}/watch`, { token: buyer1, expect: [200, 201, 204, 409] });

console.log(`\nĐạt ${pass} lời gọi, lỗi ${failures.length}.`);
if (failures.length) {
  console.log(failures.map((f) => '  ✗ ' + f).join('\n'));
  process.exit(1);
}
