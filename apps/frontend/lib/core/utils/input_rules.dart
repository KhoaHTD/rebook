import 'package:flutter/services.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/core/utils/vietnamese.dart';

/// Lỗi kiểm tra: hàm dịch ra câu thông báo theo ngôn ngữ hiện tại.
typedef RuleError = String Function(AppLocalizations l10n);

/// Luật cho một ô nhập: chữ mờ gợi ý, bộ lọc ký tự, kiểu bàn phím và cách kiểm tra.
/// Thuần Dart (trừ kiểu bàn phím / bộ lọc của Flutter) nên test được; widget dùng chung là `RuleField`.
class InputRule {
  const InputRule({
    required this.hint,
    required this.check,
    this.keyboard,
    this.formatters = const [],
    this.maxLength,
    this.capitalization = TextCapitalization.none,
    this.optional = false,
    this.normalize = _trim,
  });

  /// Chữ mờ trong ô, tự mất khi gõ.
  final String Function(AppLocalizations l10n) hint;

  /// Nhận chuỗi đã chuẩn hoá, null = hợp lệ. Chuỗi rỗng đã được xử lý trước ([optional] hoặc "không được để trống").
  final RuleError? Function(String value) check;
  final TextInputType? keyboard;
  final List<TextInputFormatter> formatters;
  final int? maxLength;
  final TextCapitalization capitalization;

  /// Cho phép để trống.
  final bool optional;

  /// Chuẩn hoá trước khi kiểm tra và khi lưu (mặc định cắt khoảng trắng hai đầu).
  final String Function(String raw) normalize;

  static String _trim(String s) => s.trim();

  /// Giá trị đã chuẩn hoá của [raw].
  String value(String? raw) => normalize(raw ?? '');

  /// null = hợp lệ.
  RuleError? error(String? raw) {
    final v = value(raw);
    if (v.isEmpty) return optional ? null : (l) => l.fieldRequired;
    return check(v);
  }

  /// Dùng làm `validator` của TextFormField.
  String? Function(String?) validator(AppLocalizations l10n) =>
      (raw) => error(raw)?.call(l10n);

  bool isValid(String? raw) => error(raw) == null;

  InputRule copyWith({bool? optional}) => InputRule(
    hint: hint,
    check: check,
    keyboard: keyboard,
    formatters: formatters,
    maxLength: maxLength,
    capitalization: capitalization,
    optional: optional ?? this.optional,
    normalize: normalize,
  );
}

final _digits = FilteringTextInputFormatter.digitsOnly;

/// Gộp khoảng trắng liên tiếp thành một và cắt hai đầu.
String _squash(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Độ dài [min]–[max] sau khi chuẩn hoá, tuỳ chọn thêm [pattern].
RuleError? Function(String) _length(
  int min,
  int max, {
  RegExp? pattern,
  RuleError? patternError,
}) => (v) {
  if (v.length < min || v.length > max) {
    return (l) => l.ruleLen(min, max);
  }
  if (pattern != null && !pattern.hasMatch(v)) {
    return patternError ?? (l) => l.ruleLen(min, max);
  }
  return null;
};

/// Số nguyên trong [min]–[max], tuỳ chọn bội số của [step].
RuleError? Function(String) _int(
  int min,
  int max, {
  int step = 1,
  bool money = false,
}) => (v) {
  final n = int.tryParse(v);
  String show(int x) => money ? formatVnd(x) : '$x';
  if (n == null || n < min || n > max) {
    return (l) => max >= 1 << 40
        ? l.ruleMinAmount(show(min))
        : l.ruleRange(show(min), show(max));
  }
  if (step > 1 && n % step != 0) return (l) => l.ruleStep(show(step));
  return null;
};

/// Mọi luật nhập liệu của app, theo SRS (mục 3, 4.1, 5.3, 6.1–6.4, 8). Con số nào SRS không ghi thì là đề xuất.
abstract final class Rules {
  // ───────── tài khoản ─────────
  static final email = InputRule(
    hint: (l) => l.hintEmail,
    keyboard: TextInputType.emailAddress,
    normalize: (s) => s.trim().toLowerCase(),
    maxLength: 100,
    check: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
        ? null
        : (l) => l.emailInvalid,
  );

  static final phone = InputRule(
    hint: (l) => l.hintPhone,
    keyboard: TextInputType.phone,
    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
    maxLength: 13,
    normalize: (s) => s.replaceAll(' ', ''),
    check: (v) => RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(v)
        ? null
        : (l) => l.phoneInvalid,
  );

  static final password = InputRule(
    hint: (l) => l.hintPassword,
    maxLength: 64,
    normalize: (s) => s,
    check: (v) => v.length >= 6 ? null : (l) => l.passwordTooShort,
  );

  static final confirmPassword = InputRule(
    hint: (l) => l.hintConfirmPassword,
    maxLength: 64,
    normalize: (s) => s,
    check: (_) => null,
  );

  static final otp = InputRule(
    hint: (l) => l.hintOtp,
    keyboard: TextInputType.number,
    formatters: [_digits],
    maxLength: 6,
    check: (v) =>
        RegExp(r'^\d{6}$').hasMatch(v) ? null : (l) => l.ruleLen(6, 6),
  );

  /// Họ tên: chữ cái (có dấu) và dấu cách, 2–60 ký tự.
  static final fullName = InputRule(
    hint: (l) => l.hintFullName,
    capitalization: TextCapitalization.words,
    maxLength: 60,
    normalize: _squash,
    check: _length(
      2,
      60,
      pattern: RegExp(r"^[\p{L} .'-]+$", unicode: true),
      patternError: (l) => l.ruleName,
    ),
  );

  // ───────── địa chỉ / shop ─────────
  static final district = InputRule(
    hint: (l) => l.hintDistrict,
    capitalization: TextCapitalization.words,
    maxLength: 50,
    normalize: _squash,
    check: _length(2, 50),
  );

  static final ward = InputRule(
    hint: (l) => l.hintWard,
    capitalization: TextCapitalization.words,
    maxLength: 50,
    normalize: _squash,
    check: _length(2, 50),
  );

  static final street = InputRule(
    hint: (l) => l.hintStreet,
    maxLength: 120,
    normalize: _squash,
    check: _length(5, 120),
  );

  static final bankNumber = InputRule(
    hint: (l) => l.hintBankNumber,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(19)],
    maxLength: 19,
    check: (v) =>
        RegExp(r'^\d{6,19}$').hasMatch(v) ? null : (l) => l.ruleBankNumber,
  );

  /// Tên chủ tài khoản: IN HOA, không dấu (tự đổi khi gõ).
  static final bankHolder = InputRule(
    hint: (l) => l.hintBankHolder,
    capitalization: TextCapitalization.characters,
    formatters: [_UpperAsciiFormatter()],
    maxLength: 50,
    normalize: (s) => bankAccountName(s).trim(),
    check: (v) =>
        RegExp(r'^[A-Z ]{2,50}$').hasMatch(v) ? null : (l) => l.ruleBankHolder,
  );

  static final bankName = InputRule(
    hint: (l) => l.hintBankName,
    maxLength: 40,
    normalize: _squash,
    check: _length(2, 40),
  );

  static final shopName = InputRule(
    hint: (l) => l.hintShopName,
    maxLength: 40,
    normalize: _squash,
    check: _length(3, 40),
  );

  static final pickupAddress = InputRule(
    hint: (l) => l.hintPickup,
    maxLength: 150,
    normalize: _squash,
    check: _length(8, 150),
  );

  // ───────── sách (SRS 4.1, 6.1) ─────────
  static final bookTitle = InputRule(
    hint: (l) => l.hintBookTitle,
    capitalization: TextCapitalization.sentences,
    maxLength: 120,
    normalize: _squash,
    check: _length(2, 120),
  );

  static final author = InputRule(
    hint: (l) => l.hintAuthor,
    capitalization: TextCapitalization.words,
    maxLength: 80,
    normalize: _squash,
    check: _length(2, 80),
  );

  static final publisher = InputRule(
    hint: (l) => l.hintPublisher,
    maxLength: 80,
    optional: true,
    normalize: _squash,
    check: _length(2, 80),
  );

  static final language = InputRule(
    hint: (l) => l.hintLanguage,
    maxLength: 30,
    optional: true,
    normalize: _squash,
    check: _length(2, 30),
  );

  static final year = InputRule(
    hint: (l) => l.hintYear,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(4)],
    maxLength: 4,
    optional: true,
    check: _int(1450, DateTime.now().year),
  );

  /// ISBN-10 hoặc ISBN-13 (bỏ dấu gạch / dấu cách), kiểm tra chữ số cuối.
  static final isbn = InputRule(
    hint: (l) => l.hintIsbn,
    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9Xx\- ]'))],
    maxLength: 17,
    optional: true,
    normalize: (s) => s.replaceAll(RegExp(r'[\s-]'), '').toUpperCase(),
    check: (v) => isValidIsbn(v) ? null : (l) => l.ruleIsbn,
  );

  static final pages = InputRule(
    hint: (l) => l.hintPages,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(4)],
    maxLength: 4,
    optional: true,
    check: _int(1, 5000),
  );

  /// Khối lượng gam, để tính phí ship.
  static final weightGram = InputRule(
    hint: (l) => l.hintWeight,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(4)],
    maxLength: 4,
    check: _int(20, 5000),
  );

  /// Giá bán giá cố định.
  static final price = InputRule(
    hint: (l) => l.hintPrice,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(9)],
    maxLength: 9,
    check: _int(1000, 100000000, step: 1000, money: true),
  );

  static final stock = InputRule(
    hint: (l) => l.hintStock,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(3)],
    maxLength: 3,
    check: _int(0, 999),
  );

  /// Giá mong muốn khi ký gửi: dưới 300.000đ bị từ chối (SRS 6.1).
  static final expectedPrice = InputRule(
    hint: (l) => l.hintExpectedPrice,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(10)],
    maxLength: 10,
    check: _int(300000, 1 << 50, money: true),
  );

  static final story = InputRule(
    hint: (l) => l.hintStory,
    capitalization: TextCapitalization.sentences,
    maxLength: 1000,
    check: _length(20, 1000),
  );

  static final description = InputRule(
    hint: (l) => l.hintDescription,
    capitalization: TextCapitalization.sentences,
    maxLength: 2000,
    optional: true,
    check: _length(5, 2000),
  );

  // ───────── tiền, đấu giá (SRS 5.3, 6.4, 8) ─────────
  /// Số tiền nạp / rút: tối thiểu 10.000đ.
  static final amount = InputRule(
    hint: (l) => l.hintAmount,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(12)],
    maxLength: 12,
    check: _int(10000, 1 << 50, money: true),
  );

  static final proxyMax = InputRule(
    hint: (l) => l.hintProxy,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(12)],
    maxLength: 12,
    check: _int(1000, 1 << 50, step: 1000, money: true),
  );

  // ───────── kho, kiểm định (SRS 6.2) ─────────
  static final estimate = InputRule(
    hint: (l) => l.hintEstimate,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(10)],
    maxLength: 10,
    check: _int(1000, 1000000000, money: true),
  );

  static final startPrice = InputRule(
    hint: (l) => l.hintStartPrice,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(10)],
    maxLength: 10,
    check: _int(1000, 1000000000, money: true),
  );

  static final reserve = InputRule(
    hint: (l) => l.hintReserve,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(10)],
    maxLength: 10,
    check: _int(0, 1000000000, money: true),
  );

  /// Mã lịch hẹn: chữ in hoa, số, gạch; tự viết hoa.
  static final appointmentCode = InputRule(
    hint: (l) => l.hintApptCode,
    capitalization: TextCapitalization.characters,
    maxLength: 20,
    normalize: (s) => s.trim().toUpperCase(),
    check: _length(
      4,
      20,
      pattern: RegExp(r'^[A-Z0-9-]+$'),
      patternError: (l) => l.ruleCode(4, 20),
    ),
  );

  static final shelfCode = InputRule(
    hint: (l) => l.hintShelf,
    capitalization: TextCapitalization.characters,
    maxLength: 8,
    normalize: (s) => s.trim().toUpperCase(),
    check: (v) => RegExp(r'^[A-Z]\d{1,2}-\d{1,3}$').hasMatch(v)
        ? null
        : (l) => l.ruleShelf,
  );

  static final trackingCode = InputRule(
    hint: (l) => l.hintTracking,
    capitalization: TextCapitalization.characters,
    maxLength: 20,
    optional: true,
    normalize: (s) => s.trim().toUpperCase(),
    check: _length(
      8,
      20,
      pattern: RegExp(r'^[A-Z0-9]+$'),
      patternError: (l) => l.ruleCode(8, 20),
    ),
  );

  static final conditionReport = InputRule(
    hint: (l) => l.hintConditionReport,
    capitalization: TextCapitalization.sentences,
    maxLength: 1000,
    check: _length(20, 1000),
  );

  // ───────── quản trị (SRS 6.3, 8.2) ─────────
  static final sessionTitle = InputRule(
    hint: (l) => l.hintSessionTitle,
    maxLength: 80,
    normalize: _squash,
    check: _length(5, 80),
  );

  static final categoryName = InputRule(
    hint: (l) => l.hintCategoryName,
    maxLength: 40,
    normalize: _squash,
    check: _length(2, 40),
  );

  static final minParticipants = InputRule(
    hint: (l) => l.hintMinParticipants,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(3)],
    maxLength: 3,
    check: _int(1, 500),
  );

  static final deposit = InputRule(
    hint: (l) => l.hintDeposit,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(10)],
    maxLength: 10,
    check: _int(10000, 100000000, money: true),
  );

  static final lotSeconds = InputRule(
    hint: (l) => l.hintLotSeconds,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(3)],
    maxLength: 3,
    check: _int(30, 600),
  );

  static final softSeconds = InputRule(
    hint: (l) => l.hintSoftSeconds,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter(2)],
    maxLength: 2,
    check: _int(5, 60),
  );

  /// Phần trăm phí 0–100, tối đa một chữ số thập phân.
  static final percent = InputRule(
    hint: (l) => l.hintPercent,
    keyboard: const TextInputType.numberWithOptions(decimal: true),
    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    maxLength: 5,
    normalize: (s) => s.trim().replaceAll(',', '.'),
    check: (v) {
      final n = double.tryParse(v);
      if (n == null ||
          n < 0 ||
          n > 100 ||
          !RegExp(r'^\d{1,3}(\.\d)?$').hasMatch(v)) {
        return (l) => l.ruleRange('0', '100');
      }
      return null;
    },
  );

  /// Số nguyên dương trong khoảng cho các ô cấu hình (ngày, giờ, phút, hệ số).
  static InputRule integer(int min, int max, {String hint = ''}) => InputRule(
    hint: (_) => hint.isEmpty ? '$min–$max' : hint,
    keyboard: TextInputType.number,
    formatters: [_digits, LengthLimitingTextInputFormatter('$max'.length)],
    maxLength: '$max'.length,
    check: _int(min, max),
  );

  // ───────── lý do, nhận xét, tìm kiếm ─────────
  static final reason = InputRule(
    hint: (l) => l.hintReason,
    capitalization: TextCapitalization.sentences,
    maxLength: 500,
    check: _length(10, 500),
  );

  static final review = InputRule(
    hint: (l) => l.hintReview,
    capitalization: TextCapitalization.sentences,
    maxLength: 500,
    optional: true,
    check: _length(2, 500),
  );

  static final search = InputRule(
    hint: (l) => l.hintSearch,
    maxLength: 100,
    optional: true,
    check: (_) => null,
  );
}

/// ISBN-10 hoặc ISBN-13 đã bỏ dấu gạch / cách; kiểm tra chữ số cuối.
bool isValidIsbn(String s) {
  if (RegExp(r'^\d{13}$').hasMatch(s)) {
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(s[i]) * (i.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10 == int.parse(s[12]);
  }
  if (RegExp(r'^\d{9}[\dX]$').hasMatch(s)) {
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(s[i]) * (10 - i);
    }
    sum += s[9] == 'X' ? 10 : int.parse(s[9]);
    return sum % 11 == 0;
  }
  return false;
}

/// Gõ có dấu hoặc chữ thường thì đổi ngay sang IN HOA không dấu (tên chủ tài khoản ngân hàng).
class _UpperAsciiFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = bankAccountName(newValue.text);
    if (t == newValue.text) return newValue;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
