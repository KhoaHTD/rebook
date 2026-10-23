/// Bìa sách đóng gói sẵn trong `assets/books/`, ghép với sách do backend trả về theo tên sách.
///
/// Backend chỉ có ảnh giả (picsum), còn bản mock đã có bìa thật cho cùng bộ sách mẫu.
/// Khóa là tên sách đã chuẩn hóa (bỏ dấu, chữ thường); sách nào có tên **bắt đầu bằng** khóa thì dùng bìa này,
/// nên "Vang Bóng Một Thời – có chữ ký" hay "Truyện Kiều (…) – bản in 1925" vẫn khớp.
const _bundledCovers = <String, List<String>>{
  'de men phieu luu ky': ['de-men-0.jpg', 'de-men-1.jpg'],
  'so do': ['so-do-0.jpg', 'so-do-1.jpg', 'so-do-2.webp'],
  'nha gia kim': ['nha-gia-kim-0.jpg'],
  'dac nhan tam': ['dac-nhan-tam-0.jpg'],
  'giao trinh cau truc du lieu': ['giao-trinh-ctdl-0.jpg'],
  'clean code': ['clean-code-0.jpg', 'clean-code-1.jpg'],
  'tat den': ['tat-den-0.jpg', 'tat-den-1.jpg'],
  'sapiens': ['sapiens-0.jpg', 'sapiens-1.jpg', 'sapiens-2.jpg'],
  'rung na uy': ['rung-na-uy-0.jpg', 'rung-na-uy-1.jpg'],
  'truyen kieu': ['truyen-kieu-0.jpg', 'truyen-kieu-1.jpg'],
  'leu chong': ['leu-chong-0.jpg', 'leu-chong-1.jpg'],
  'vang bong mot thoi': [
    'vang-bong-0.jpg',
    'vang-bong-1.jpg',
    'vang-bong-2.jpg',
  ],
  'bi vo': ['bi-vo-0.jpg', 'bi-vo-1.jpg'],
  'tu dien annam': ['tu-dien-0.jpg'],
  'nam phong tap chi': ['nam-phong-0.jpg', 'nam-phong-1.jpg'],
  'tho tho': ['tho-tho-0.jpg', 'tho-tho-1.jpg', 'tho-tho-2.jpg'],
};

const _from =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _to =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

String _normalize(String s) {
  final out = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final i = _from.indexOf(c);
    out.write(i >= 0 ? _to[i] : c);
  }
  return out.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Đường dẫn bìa đóng gói cho sách tên [title]; rỗng nếu không có bìa nào khớp.
List<String> bundledCoversFor(String title) {
  final name = _normalize(title);
  for (final e in _bundledCovers.entries) {
    if (name == e.key || name.startsWith('${e.key} ')) {
      return [for (final f in e.value) 'assets/books/$f'];
    }
  }
  return const [];
}
