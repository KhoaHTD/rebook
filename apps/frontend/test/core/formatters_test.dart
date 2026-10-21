import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:book_marketplace/core/utils/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  test('formatVnd', () {
    expect(formatVnd(45000), contains('45.000'));
    expect(formatVnd(45000), contains('₫'));
  });

  test('formatCountdown', () {
    expect(formatCountdown(const Duration(minutes: 4, seconds: 12)), '04:12');
    expect(
      formatCountdown(const Duration(hours: 1, minutes: 5, seconds: 9)),
      '1:05:09',
    );
    expect(formatCountdown(const Duration(seconds: -3)), '00:00');
  });
}
