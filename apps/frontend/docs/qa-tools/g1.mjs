import { call, login, rec, results } from './lib.mjs';
import { writeFileSync } from 'node:fs';
const T = {}; for (const u of ['buyer1','seller1','admin','staff']) T[u] = await login(u + '@rebook.vn');

// 1.3 tìm kiếm / lọc / sắp xếp
let r = await call('GET', '/listings?q=' + encodeURIComponent('Nhân Tâm'));
rec('1.3a', 'tìm "Nhân Tâm"', r.status === 200 && r.data.items.length >= 1 && r.data.items.every(i => /nhân tâm/i.test(i.title)), '>=1 kết quả đúng tên', r.data.items?.map(i => i.title));
r = await call('GET', '/listings?category=2');
rec('1.3b', 'lọc danh mục 2', r.status === 200, '200', r.status + ' ' + r.data.items?.length);
r = await call('GET', '/listings?condition=NEW&minPrice=30000&maxPrice=60000');
rec('1.3c', 'lọc tình trạng+giá', r.status === 200 && r.data.items.every(i => i.conditionGrade === 'NEW' && i.price >= 30000 && i.price <= 60000), 'đúng bộ lọc', r.data.items?.map(i => [i.title, i.conditionGrade, i.price]));
const asc = await call('GET', '/listings?sort=price_asc'); const desc = await call('GET', '/listings?sort=price_desc');
const pa = asc.data.items?.map(i => i.price), pd = desc.data.items?.map(i => i.price);
rec('1.3d', 'sắp xếp giá tăng/giảm', pa && pd && JSON.stringify(pa) === JSON.stringify([...pa].sort((a, b) => a - b)) && JSON.stringify(pd) === JSON.stringify([...pd].sort((a, b) => b - a)), 'tăng/giảm đúng', { pa, pd, st: [asc.status, desc.status] });
// 1.4 chi tiết
r = await call('GET', '/listings/7');
rec('1.4', 'chi tiết sách (bìa, tình trạng, giá, tồn, shop, ảnh)', r.status === 200 && r.data.price && r.data.stock !== undefined && r.data.shop, 'đủ trường', Object.keys(r.data || {}));
// 1.7 các endpoint cần đăng nhập
for (const p of ['/cart', '/me', '/orders', '/wallet', '/notifications']) { r = await call('GET', p); rec('1.7' + p, 'khách gọi ' + p, r.status === 401, '401', r.status); }
// 1.6 khách xem phiên
r = await call('GET', '/sessions'); rec('1.6a', 'khách xem danh sách phiên', r.status === 200, '200', r.status);
r = await call('GET', '/sessions/1/state'); rec('1.6b', 'khách xem state phiên', r.status === 200, '200', r.status);
r = await call('POST', '/lots/1/bids', { amount: 100000 }); rec('1.6c', 'khách trả giá bị chặn', r.status === 401, '401', r.status);

// 1.8-1.15 đăng ký
const mail = 'tester' + (Date.now() % 100000) + '@rebook.vn';
r = await call('POST', '/auth/register', { email: mail, password: 'Rebook@123', fullName: 'Tester Mot', phone: '0901234567' });
rec('1.8', 'đăng ký hợp lệ', r.status === 200 || r.status === 201, '200/201', r.status + ' ' + JSON.stringify(r.data).slice(0, 200));
const reg = r.data;
const tk = reg?.accessToken ?? reg?.tokens?.accessToken;
console.log('register response keys', Object.keys(reg || {}), 'token?', !!tk);
r = await call('POST', '/auth/register', { email: 'buyer1@rebook.vn', password: 'Rebook@123', fullName: 'X Y', phone: '0911111111' });
rec('1.11', 'đăng ký trùng email', r.status === 409 || r.status === 400, '409/400 báo email đã dùng', r.status + ' ' + JSON.stringify(r.data).slice(0, 200));
r = await call('POST', '/auth/register', { email: 'short1@rebook.vn', password: '1234567', fullName: 'Short Pass', phone: '0911111112' });
rec('1.12', 'mật khẩu 7 ký tự bị chặn', r.status === 400, '400', r.status + ' ' + JSON.stringify(r.data).slice(0, 200));
r = await call('POST', '/auth/register', { email: 'plus84@rebook.vn', password: 'Rebook@123', fullName: 'Plus Eighty', phone: '+84901234568' });
const t84 = r.data?.accessToken ?? r.data?.tokens?.accessToken; let me84 = null; if (t84) me84 = (await call('GET', '/me', undefined, t84)).data;
rec('1.13', 'backend từ chối +84 thô (app đổi +84 thành 0 trước khi gửi)', r.status === 400, '400', r.status);
// OTP
if (tk) {
  r = await call('POST', '/auth/send-otp', { purpose: 'VERIFY_EMAIL' }, tk);
  console.log('send-otp body', JSON.stringify(r.data));
  const code = r.data?.devOtp;
  rec('1.9a', 'gửi OTP trả mã (dev)', r.status === 200 && !!code, '200 + mã', r.status + ' ' + JSON.stringify(r.data));
  const wrong = await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_EMAIL', code: '000000' }, tk);
  rec('1.10', 'OTP sai', wrong.status === 400, '400 INVALID_OTP', wrong.status + ' ' + JSON.stringify(wrong.data));
  const ok = await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_EMAIL', code }, tk);
  rec('1.9b', 'OTP đúng', ok.status === 200 || ok.status === 204, '200', ok.status + ' ' + JSON.stringify(ok.data));
}
// 1.15 sai mật khẩu
const bad = await call('POST', '/auth/login', { email: 'buyer1@rebook.vn', password: 'WrongPass123' });
const bad2 = await call('POST', '/auth/login', { email: 'khongco@rebook.vn', password: 'WrongPass123' });
rec('1.15', 'sai mật khẩu: thông báo không lộ email, giống nhau', bad.status === 401 && bad.data.message === bad2.data.message && bad.data.code === 'INVALID_CREDENTIALS', '401 cùng nội dung', { a: bad.data, b: bad2.data });
console.log('LOGIN-WRONG body:', JSON.stringify(bad.data));
// 1.14 quên mật khẩu
r = await call('POST', '/auth/forgot-password', { email: mail });
console.log('forgot body', JSON.stringify(r.data));
const rc = r.data?.devOtp;
rec('1.14a', 'quên mật khẩu trả mã (dev)', r.status === 200 && !!rc, '200 + mã', r.status + ' ' + JSON.stringify(r.data));
if (rc) { const rr = await call('POST', '/auth/reset-password', { email: mail, code: rc, newPassword: 'NewPass@123' }); rec('1.14b', 'đặt lại mật khẩu', rr.status === 200 || rr.status === 204, '200/204', rr.status + JSON.stringify(rr.data)); const lg = await call('POST', '/auth/login', { email: mail, password: 'NewPass@123' }); rec('1.14c', 'đăng nhập bằng mật khẩu mới', lg.status === 200, '200', lg.status); }
writeFileSync('g1.json', JSON.stringify(results, null, 1));
