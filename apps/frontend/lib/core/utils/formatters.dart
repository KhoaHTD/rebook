import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

/// Giá luôn lưu dạng `int` (VND), chỉ format khi hiển thị.
String formatVnd(int amount) => _vnd.format(amount);

/// `1:05:09`, `04:12` — dùng cho đồng hồ đếm ngược phiên đấu giá.
String formatCountdown(Duration d) {
  if (d.isNegative) return '00:00';
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = two(d.inMinutes.remainder(60));
  final s = two(d.inSeconds.remainder(60));
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
