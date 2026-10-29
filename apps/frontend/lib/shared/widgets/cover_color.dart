import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/network/upload_service.dart';

/// Màu chủ đạo của bìa sách, dùng làm nền đầu trang chủ điện thoại (đổi theo cuốn đang chọn).
///
/// Lấy mẫu một bản thu nhỏ của ảnh bìa, trung bình có trọng số theo độ rực của từng điểm ảnh
/// (nền trắng / xám ít được tính), rồi hạ độ sáng về khoảng tối vừa để chữ trắng đặt lên luôn đọc được.
/// Không có ảnh (bìa tự vẽ) hoặc ảnh lỗi thì dùng màu của bìa vẽ theo [seed].
abstract final class CoverColor {
  static final _cache = <String, Color>{};

  static const _minLight = 0.2;
  static const _maxLight = 0.4;

  /// Màu tức thời (không đợi giải mã ảnh): đã tính rồi thì lấy từ bộ nhớ, chưa thì màu bìa vẽ theo [seed].
  static Color peek({String? url, required String seed}) =>
      _cache[url ?? seed] ?? fallback(seed);

  /// Màu của bìa tự vẽ cho [seed], đã chỉnh về khoảng tối vừa.
  static Color fallback(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return tone(CoverPalette.pairs[h % CoverPalette.pairs.length].$1);
  }

  /// Giữ sắc, nhưng ép độ sáng vào [_minLight].. [_maxLight] và không để quá xỉn.
  static Color tone(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(hsl.lightness.clamp(_minLight, _maxLight))
        .withSaturation(
          hsl.saturation < 0.12
              ? hsl.saturation
              : hsl.saturation.clamp(0.3, 0.75),
        )
        .toColor();
  }

  /// Giải mã bìa ở độ phân giải rất nhỏ và trả màu chủ đạo (có nhớ lại kết quả).
  static Future<Color> of({String? url, required String seed}) async {
    final key = url ?? seed;
    final hit = _cache[key];
    if (hit != null) return hit;
    Color result;
    try {
      result = url == null ? fallback(seed) : await _fromImage(url);
    } on Object {
      result = fallback(seed);
    }
    return _cache[key] = result;
  }

  static ImageProvider _provider(String url) {
    if (MemoryImages.isMemory(url)) {
      final bytes = MemoryImages.get(url);
      if (bytes != null) return MemoryImage(bytes);
    }
    if (url.startsWith('assets/')) return AssetImage(url);
    return CachedNetworkImageProvider(url);
  }

  static Future<Color> _fromImage(String url) async {
    final completer = Completer<ui.Image>();
    final stream = ResizeImage(
      _provider(url),
      width: 24,
    ).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (e, _) {
        if (!completer.isCompleted) completer.completeError(e);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    final image = await completer.future;
    final data = await image.toByteData();
    if (data == null) return fallback(url);

    var r = 0.0, g = 0.0, b = 0.0, total = 0.0;
    for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
      if (data.getUint8(i + 3) < 128) continue;
      final px = Color.fromARGB(
        255,
        data.getUint8(i),
        data.getUint8(i + 1),
        data.getUint8(i + 2),
      );
      final hsl = HSLColor.fromColor(px);
      // Điểm càng rực (bão hoà cao, sáng vừa) càng nặng ký; trắng / đen / xám gần như bị bỏ qua.
      final w = 0.05 + hsl.saturation * (1 - (2 * hsl.lightness - 1).abs());
      r += px.r * w;
      g += px.g * w;
      b += px.b * w;
      total += w;
    }
    if (total == 0) return fallback(url);
    return tone(
      Color.from(alpha: 1, red: r / total, green: g / total, blue: b / total),
    );
  }
}
