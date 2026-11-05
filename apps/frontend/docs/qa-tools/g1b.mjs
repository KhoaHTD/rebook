import { call, rec, results } from './lib.mjs';
import { writeFileSync } from 'node:fs';
const mail = 'tester' + (Date.now() % 100000) + '@rebook.vn';
let r = await call('POST', '/auth/register', { email: mail, password: 'Rebook@123', fullName: 'Tester Hai', phone: '0901234599' });
const tk = r.data.accessToken;
const me0 = (await call('GET', '/me', undefined, tk)).data;
rec('1.8b', 'tài khoản mới chưa xác thực email', me0.emailVerified === false, 'emailVerified=false', me0);
const wrong = await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_EMAIL', code: '000000' }, tk);
rec('1.10', 'OTP sai', wrong.status === 400, '400', wrong.status + ' ' + JSON.stringify(wrong.data));
const s = await call('POST', '/auth/send-otp', { purpose: 'VERIFY_EMAIL' }, tk);
const ok = await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_EMAIL', code: s.data.devOtp }, tk);
rec('1.9', 'OTP đúng kích hoạt', ok.status === 200 || ok.status === 204, '200', ok.status + ' ' + JSON.stringify(ok.data));
const me1 = (await call('GET', '/me', undefined, tk)).data;
rec('1.9c', 'sau OTP emailVerified=true', me1.emailVerified === true, 'true', me1);
const f = await call('POST', '/auth/forgot-password', { email: mail });
const rr = await call('POST', '/auth/reset-password', { email: mail, code: f.data.devOtp, newPassword: 'NewPass@123' });
rec('1.14b', 'đặt lại mật khẩu', rr.status === 200 || rr.status === 204, '200', rr.status + JSON.stringify(rr.data));
const lg = await call('POST', '/auth/login', { email: mail, password: 'NewPass@123' });
rec('1.14c', 'đăng nhập bằng mật khẩu mới', lg.status === 200, '200', lg.status);
const old = await call('POST', '/auth/login', { email: mail, password: 'Rebook@123' });
rec('1.14d', 'mật khẩu cũ không còn dùng được', old.status === 401, '401', old.status);
// khoá nhiều lần sai?
let last; for (let i = 0; i < 12; i++) last = await call('POST', '/auth/login', { email: 'khoa-thu@rebook.vn', password: 'Sai' + i });
rec('1.15b', 'sai mật khẩu 12 lần: có chặn dò mật khẩu không', last.status === 429, '429 sau nhiều lần sai', last.status + ' ' + JSON.stringify(last.data));
// OTP brute force
const s2 = await call('POST', '/auth/send-otp', { purpose: 'VERIFY_PHONE' }, tk); let st = [];
for (let i = 0; i < 8; i++) { const x = await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_PHONE', code: String(100000 + i) }, tk); st.push(x.status + ':' + (x.data.code || '')); }
const good = await call('POST', '/auth/verify-otp', { purpose: 'VERIFY_PHONE', code: s2.data.devOtp }, tk);
rec('1.10b', 'đoán sai OTP 8 lần rồi nhập đúng: mã phải bị khoá', good.status >= 400, 'mã đúng bị từ chối sau 5 lần sai', { attempts: st.join(' '), correct: good.status });
writeFileSync('g1b.json', JSON.stringify(results, null, 1));
