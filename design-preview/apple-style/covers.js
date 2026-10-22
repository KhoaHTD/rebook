// Bìa concept cho sách chưa có ảnh bìa giấy phép mở. Mỗi motif lấy từ chất liệu có thật của tác phẩm.
// ĐÂY KHÔNG PHẢI BÌA CHÍNH THỨC — mỗi bìa mang nhãn "concept".
const M = {
  // Số đỏ (Vũ Trọng Phụng, 1936): trào phúng phong trào "Âu hoá", quần vợt, thời trang.
  sodo: ['Số đỏ', 'Vũ Trọng Phụng',
    '<ellipse cx="118" cy="170" rx="46" ry="58" fill="none" stroke="currentColor" stroke-width="7"/><rect x="113" y="226" width="10" height="66" fill="currentColor"/><circle cx="58" cy="246" r="13" fill="currentColor"/>'],
  // Chí Phèo (Nam Cao, 1941): bát cháo hành của Thị Nở.
  chipheo: ['Chí Phèo', 'Nam Cao',
    '<path d="M38 214h124a62 52 0 0 1-124 0z" fill="#6d5640"/><rect x="74" y="266" width="52" height="8" fill="#6d5640"/><circle cx="82" cy="206" r="5" fill="#5f7a3f"/><circle cx="104" cy="200" r="5" fill="#5f7a3f"/><circle cx="124" cy="207" r="5" fill="#5f7a3f"/>'],
  // Tắt đèn (Ngô Tất Tố, 1937): mùa sưu thuế, ngọn đèn dầu đã tắt.
  tatden: ['Tắt đèn', 'Ngô Tất Tố',
    '<path d="M86 150h28l6 40c18 8 28 24 28 42 0 30-22 46-48 46s-48-16-48-46c0-18 10-34 28-42z" fill="#3a3632"/><rect x="62" y="276" width="76" height="10" fill="#3a3632"/><path d="M100 146c-8-16 10-22 2-40" fill="none" stroke="#6b645c" stroke-width="3"/>'],
  // Truyện Kiều (Nguyễn Du): trăng và nước — hình ảnh lặp lại trong thơ.
  kieu: ['Truyện Kiều', 'Nguyễn Du',
    '<circle cx="132" cy="168" r="30" fill="#b9472f"/><rect x="0" y="232" width="200" height="6" fill="#3a2e22"/><rect x="30" y="250" width="140" height="6" fill="#3a2e22"/><rect x="60" y="268" width="80" height="6" fill="#3a2e22"/>'],
  // Vang bóng một thời (Nguyễn Tuân, 1940): thú uống trà, chữ đẹp.
  vang: ['Vang bóng một thời', 'Nguyễn Tuân',
    '<ellipse cx="96" cy="236" rx="46" ry="38" fill="#c9b78f"/><rect x="82" y="190" width="28" height="10" fill="#c9b78f"/><path d="M142 226c22-6 30-22 34-30" stroke="#c9b78f" stroke-width="9" fill="none"/><path d="M50 222c-16 0-16 28 0 28" stroke="#c9b78f" stroke-width="8" fill="none"/>'],
  // Hà Nội băm sáu phố phường (Thạch Lam, 1943): dãy nhà ống phố cổ.
  hanoi: ['Hà Nội băm sáu phố phường', 'Thạch Lam',
    '<path d="M0 300V222l20-14 20 14v-10l22-16 22 16v12l18-12 18 12v-18l20-14 20 14v10l20-14 20 14v76z" fill="#6e5a3c"/>'],
  // Nỗi buồn chiến tranh (Bảo Ninh, 1987): rừng, mưa.
  noibuon: ['Nỗi buồn chiến tranh', 'Bảo Ninh',
    '<path d="M30 300c0-60 10-100 24-130 4 40 4 90-4 130zM80 300c-2-70 10-120 30-150 0 50-6 110-12 150zM130 300c2-50 14-90 34-114-4 40-10 84-18 114z" fill="#5d7a5c"/>'],
  // Thương nhớ mười hai (Vũ Bằng): mười hai tháng Hà Nội.
  thuongnho: ['Thương nhớ mười hai', 'Vũ Bằng',
    Array.from({length: 12}, (_, i) => `<circle cx="${46 + (i % 4) * 36}" cy="${196 + Math.floor(i / 4) * 32}" r="9" fill="${i === 0 ? '#a8402c' : '#3b3530'}"/>`).join('')],
  // Gió đầu mùa (Thạch Lam, 1937).
  gio: ['Gió đầu mùa', 'Thạch Lam',
    '<path d="M60 250c30-70 90-80 110-80-10 40-50 90-110 80z" fill="#e9e3d6"/><path d="M20 210h70M40 230h50" stroke="#e9e3d6" stroke-width="4"/>'],
  // Trăm năm cô đơn — bản dịch tiếng Việt (bướm vàng của Mauricio Babilonia).
  tramnam: ['Trăm năm cô đơn', 'Gabriel García Márquez',
    '<g fill="#2a2620"><path d="M60 200l18 10-18 10zM96 210l-18-10v20z"/><path d="M118 240l14 8-14 8zM146 248l-14-8v16z"/><path d="M70 262l10 6-10 6zM90 268l-10-6v12z"/></g>'],
};

for (const el of document.querySelectorAll('[data-concept]')) {
  const [title, author, svg] = M[el.dataset.concept];
  el.classList.add('cover', 'concept', `c-${el.dataset.concept}`);
  el.setAttribute('role', 'img');
  el.setAttribute('aria-label', `Bìa concept (không phải bìa chính thức): ${title} — ${author}`);
  el.innerHTML = `<span class="ct">${title}</span><span class="ca">${author}</span>` +
    `<svg viewBox="0 0 200 300" aria-hidden="true" style="color:currentColor">${svg}</svg><span class="tag">concept</span>`;
}
