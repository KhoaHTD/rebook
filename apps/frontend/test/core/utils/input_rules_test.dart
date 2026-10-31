import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/utils/input_rules.dart';

void main() {
  bool ok(InputRule r, String? v) => r.isValid(v);

  test('ô bắt buộc không cho để trống, ô tuỳ chọn thì cho', () {
    expect(ok(Rules.email, ''), isFalse);
    expect(ok(Rules.email, '   '), isFalse);
    expect(ok(Rules.publisher, ''), isTrue);
    expect(ok(Rules.isbn, null), isTrue);
  });

  test('email: chấp nhận dạng thường, tự bỏ khoảng trắng và viết thường', () {
    expect(ok(Rules.email, ' Khoa@ReBook.vn '), isTrue);
    expect(Rules.email.value(' Khoa@ReBook.vn '), 'khoa@rebook.vn');
    expect(ok(Rules.email, 'khoa@rebook'), isFalse);
    expect(ok(Rules.email, 'khoa rebook@x.vn'), isFalse);
  });

  test('số điện thoại: 0xxxxxxxxx hoặc +84, bỏ dấu cách', () {
    expect(ok(Rules.phone, '0901234567'), isTrue);
    expect(ok(Rules.phone, '+84 901 234 567'), isTrue);
    expect(ok(Rules.phone, '090123'), isFalse);
    expect(ok(Rules.phone, '12345678901'), isFalse);
  });

  test('mật khẩu ≥ 6, OTP đúng 6 chữ số', () {
    expect(ok(Rules.password, '123456'), isTrue);
    expect(ok(Rules.password, '12345'), isFalse);
    expect(ok(Rules.otp, '123456'), isTrue);
    expect(ok(Rules.otp, '12345'), isFalse);
    expect(ok(Rules.otp, '12a456'), isFalse);
  });

  test('họ tên: chữ cái có dấu, không số, gộp khoảng trắng', () {
    expect(ok(Rules.fullName, 'Nguyễn  Văn   A'), isTrue);
    expect(Rules.fullName.value('Nguyễn  Văn   A'), 'Nguyễn Văn A');
    expect(ok(Rules.fullName, 'Nguyen123'), isFalse);
    expect(ok(Rules.fullName, 'A'), isFalse);
    expect(ok(Rules.fullName, 'Ng@uyen'), isFalse);
  });

  test('tài khoản ngân hàng: 6–19 số; tên chủ IN HOA không dấu', () {
    expect(ok(Rules.bankNumber, '0011004567890'), isTrue);
    expect(ok(Rules.bankNumber, '12345'), isFalse);
    expect(ok(Rules.bankNumber, '1' * 20), isFalse);
    expect(Rules.bankHolder.value('Nguyễn Minh Ánh'), 'NGUYEN MINH ANH');
    expect(ok(Rules.bankHolder, 'Nguyễn Minh Ánh'), isTrue);
    expect(ok(Rules.bankHolder, 'A'), isFalse);
  });

  test('ISBN-10 và ISBN-13: kiểm tra chữ số cuối, bỏ dấu gạch', () {
    expect(isValidIsbn('9780306406157'), isTrue);
    expect(isValidIsbn('0306406152'), isTrue);
    expect(isValidIsbn('080442957X'), isTrue);
    expect(isValidIsbn('9780306406158'), isFalse);
    expect(isValidIsbn('0306406153'), isFalse);
    expect(ok(Rules.isbn, '978-0-306-40615-7'), isTrue);
    expect(ok(Rules.isbn, '123'), isFalse);
  });

  test('năm xuất bản, số trang, khối lượng', () {
    expect(ok(Rules.year, '1941'), isTrue);
    expect(ok(Rules.year, '${DateTime.now().year + 1}'), isFalse);
    expect(ok(Rules.year, '1200'), isFalse);
    expect(ok(Rules.pages, '280'), isTrue);
    expect(ok(Rules.pages, '0'), isFalse);
    expect(ok(Rules.pages, '6000'), isFalse);
    expect(ok(Rules.weightGram, '350'), isTrue);
    expect(ok(Rules.weightGram, '5'), isFalse);
  });

  test('giá bán: 1.000–100 triệu, bội số 1.000; giá ký gửi ≥ 300.000', () {
    expect(ok(Rules.price, '60000'), isTrue);
    expect(ok(Rules.price, '60500'), isFalse);
    expect(ok(Rules.price, '500'), isFalse);
    expect(ok(Rules.price, '200000000'), isFalse);
    expect(ok(Rules.expectedPrice, '300000'), isTrue);
    expect(ok(Rules.expectedPrice, '299999'), isFalse);
    expect(ok(Rules.stock, '0'), isTrue);
    expect(ok(Rules.stock, '1000'), isFalse);
  });

  test('số tiền nạp / rút tối thiểu 10.000', () {
    expect(ok(Rules.amount, '10000'), isTrue);
    expect(ok(Rules.amount, '9999'), isFalse);
    expect(ok(Rules.amount, 'abc'), isFalse);
  });

  test('mã lịch hẹn tự viết hoa; mã kệ dạng A3-12; mã vận đơn tuỳ chọn', () {
    expect(Rules.appointmentCode.value(' apt-1042 '), 'APT-1042');
    expect(ok(Rules.appointmentCode, 'apt-1042'), isTrue);
    expect(ok(Rules.appointmentCode, 'ab'), isFalse);
    expect(ok(Rules.appointmentCode, 'apt 1042'), isFalse);
    expect(ok(Rules.shelfCode, 'a3-12'), isTrue);
    expect(ok(Rules.shelfCode, '3A-12'), isFalse);
    expect(ok(Rules.shelfCode, 'A3'), isFalse);
    expect(ok(Rules.trackingCode, ''), isTrue);
    expect(ok(Rules.trackingCode, 'vn123456789'), isTrue);
    expect(ok(Rules.trackingCode, 'vn1'), isFalse);
  });

  test('quản trị: phần trăm, giây, số người tối thiểu, cọc', () {
    expect(ok(Rules.percent, '5'), isTrue);
    expect(ok(Rules.percent, '12.5'), isTrue);
    expect(ok(Rules.percent, '12,5'), isTrue);
    expect(ok(Rules.percent, '101'), isFalse);
    expect(ok(Rules.percent, '1.25'), isFalse);
    expect(ok(Rules.lotSeconds, '60'), isTrue);
    expect(ok(Rules.lotSeconds, '10'), isFalse);
    expect(ok(Rules.softSeconds, '15'), isTrue);
    expect(ok(Rules.softSeconds, '90'), isFalse);
    expect(ok(Rules.minParticipants, '0'), isFalse);
    expect(ok(Rules.deposit, '500000'), isTrue);
    expect(ok(Rules.deposit, '5000'), isFalse);
    expect(ok(Rules.integer(1, 30), '31'), isFalse);
  });

  test('lý do ≥ 10 ký tự; nhận xét tuỳ chọn', () {
    expect(ok(Rules.reason, 'ngắn'), isFalse);
    expect(ok(Rules.reason, 'Sách bị thiếu trang 12-20'), isTrue);
    expect(ok(Rules.review, ''), isTrue);
  });
}
