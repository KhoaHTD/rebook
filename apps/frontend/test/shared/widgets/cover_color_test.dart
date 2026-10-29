import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/shared/widgets/cover_color.dart';

void main() {
  group('CoverColor', () {
    test('bìa tự vẽ: cùng seed luôn ra cùng một màu', () {
      expect(CoverColor.fallback('l1'), CoverColor.fallback('l1'));
    });

    test('mọi màu đều đủ tối để chữ trắng đọc được', () {
      for (final seed in ['a', 'l1', 'l2', 'sach-hiem', 'x' * 40]) {
        final hsl = HSLColor.fromColor(CoverColor.fallback(seed));
        expect(hsl.lightness, inInclusiveRange(0.19, 0.41), reason: seed);
      }
    });

    test('tone kéo màu trắng về xám tối, không ra màu lòe loẹt', () {
      final hsl = HSLColor.fromColor(CoverColor.tone(const Color(0xFFFFFFFF)));
      expect(hsl.lightness, lessThanOrEqualTo(0.4));
      expect(hsl.saturation, lessThan(0.12));
    });

    test('không có ảnh thì of() trả màu bìa vẽ và nhớ lại', () async {
      final c = await CoverColor.of(seed: 'quyen-sach');
      expect(c, CoverColor.fallback('quyen-sach'));
      expect(CoverColor.peek(seed: 'quyen-sach'), c);
    });
  });
}
