import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

final _millions = NumberFormat('#,##0.#', 'vi_VN');

/// Giá luôn lưu dạng `int` (VND), chỉ format khi hiển thị.
String formatVnd(int amount) => _vnd.format(amount);

/// Số triệu đồng, tối đa 1 chữ số thập phân: 4500000 → "4,5", 3000000 → "3".
String formatMillions(int amount) => _millions.format(amount / 1000000);

/// Khoảng ước tính theo triệu: (3000000, 4500000) → "3–4,5".
String formatMillionsRange(int low, int high) =>
    '${formatMillions(low)}–${formatMillions(high)}';

/// `1:05:09`, `04:12` — dùng cho đồng hồ đếm ngược phiên đấu giá.
String formatCountdown(Duration d) {
  if (d.isNegative) return '00:00';
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = two(d.inMinutes.remainder(60));
  final s = two(d.inSeconds.remainder(60));
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Đồng hồ ngắn trong phòng đấu giá: `0:42`, `1:05`.
String formatClock(Duration d) {
  if (d.isNegative) return '0:00';
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
}

/// `02/11`
String formatDayMonth(DateTime t) => DateFormat('dd/MM').format(t);

/// `19:30`
String formatTime(DateTime t) => DateFormat('HH:mm').format(t);

/// `02/11/2026`
String formatDate(DateTime t) => DateFormat('dd/MM/yyyy').format(t);

/// Số tiền rút gọn cho nút bấm: 500000 → "500k", 1500000 → "1,5tr".
String formatMillionsShort(int amount) => amount >= 1000000
    ? '${formatMillions(amount)}tr'
    : '${NumberFormat('#,##0', 'vi_VN').format(amount / 1000)}k';
