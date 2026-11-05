export const BASE = 'http://localhost:8081';
export async function call(method, path, body, token) {
  const r = await fetch(BASE + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  let data = null; const t = await r.text(); try { data = t ? JSON.parse(t) : null; } catch { data = t; }
  return { status: r.status, data };
}
export async function login(email, password = 'Rebook@123') {
  const r = await call('POST', '/auth/login', { email, password });
  if (r.status !== 200) throw new Error('login ' + email + ' ' + r.status + ' ' + JSON.stringify(r.data));
  return r.data.accessToken ?? r.data.tokens?.accessToken ?? r.data;
}
export const results = [];
export function rec(id, title, ok, expected, actual, level = '') {
  results.push({ id, title, ok, expected, actual: String(typeof actual === 'string' ? actual : JSON.stringify(actual)), level });
  console.log((ok ? 'PASS' : 'FAIL') + ' ' + id + ' ' + title + (ok ? '' : '\n   expected: ' + expected + '\n   actual:   ' + String(typeof actual === 'string' ? actual : JSON.stringify(actual)).slice(0, 400)));
}
export const ids = {};
