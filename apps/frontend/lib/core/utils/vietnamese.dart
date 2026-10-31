/// Bỏ dấu tiếng Việt, giữ nguyên chữ hoa / thường (dùng cho tên chủ tài khoản ngân hàng: IN HOA, không dấu).
String removeDiacritics(String s) {
  const from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final lower = ch.toLowerCase();
    final i = from.indexOf(lower);
    if (i < 0) {
      b.write(ch);
    } else {
      b.write(ch == lower ? to[i] : to[i].toUpperCase());
    }
  }
  return b.toString();
}

/// Tên chủ tài khoản: IN HOA, không dấu, bỏ ký tự lạ, gộp khoảng trắng.
String bankAccountName(String s) =>
    removeDiacritics(s)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z ]'), '')
        .replaceAll(RegExp(r' +'), ' ');
