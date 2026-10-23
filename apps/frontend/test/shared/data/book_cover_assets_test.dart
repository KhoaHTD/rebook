import 'dart:io';

import 'package:book_marketplace/shared/data/book_cover_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tên sách backend khớp bìa đóng gói, kể cả khi có hậu tố', () {
    expect(bundledCoversFor('Dế Mèn Phiêu Lưu Ký'), isNotEmpty);
    expect(bundledCoversFor('Đắc Nhân Tâm'), ['assets/books/dac-nhan-tam-0.jpg']);
    expect(bundledCoversFor('Clean Code'), hasLength(2));
    expect(bundledCoversFor('Sapiens: Lược Sử Loài Người'), hasLength(3));
    expect(bundledCoversFor('Vang Bóng Một Thời – có chữ ký'), hasLength(3));
    expect(
      bundledCoversFor('Truyện Kiều (Kim Vân Kiều) – bản in 1925'),
      hasLength(2),
    );
    expect(bundledCoversFor('Lều Chõng – bản in lần đầu'), hasLength(2));
    expect(
      bundledCoversFor('Từ điển Annam – Lusitan – Latinh (tái bản)'),
      isNotEmpty,
    );
    expect(bundledCoversFor('Một cuốn lạ'), isEmpty);
  });

  test('mọi đường dẫn bìa đều có file thật', () {
    for (final t in [
      'Dế Mèn Phiêu Lưu Ký', 'Số Đỏ', 'Nhà Giả Kim', 'Đắc Nhân Tâm',
      'Giáo trình Cấu trúc dữ liệu và giải thuật', 'Clean Code', 'Tắt Đèn',
      'Sapiens: Lược Sử Loài Người', 'Rừng Na Uy', 'Truyện Kiều',
      'Lều Chõng', 'Vang Bóng Một Thời', 'Bỉ Vỏ', 'Từ điển Annam',
      'Nam Phong Tạp Chí – số 1', 'Thơ Thơ',
    ]) {
      final covers = bundledCoversFor(t);
      expect(covers, isNotEmpty, reason: t);
      for (final p in covers) {
        expect(File(p).existsSync(), isTrue, reason: p);
      }
    }
  });
}
