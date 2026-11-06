import 'package:flutter/material.dart';

/// Bảng màu phẳng, mềm của luồng mở app trên điện thoại (splash, giới thiệu, đăng nhập / đăng ký).
/// Đây là bảng màu riêng cho các màn "chào khách", không dùng cho phần còn lại của app.
abstract final class SoftPalette {
  static const ink = Color(0xFF2B2527);
  static const cream = Color(0xFFFBF6F2);
  static const paper = Color(0xFFFFFFFF);
  static const underline = Color(0x33000000);
  static const outline = Color(0x1F000000);

  // Nền ba trang giới thiệu.
  static const peach = Color(0xFFEDB88D);
  static const blush = Color(0xFFFAD8D4);
  static const brick = Color(0xFFD2573A);

  // Màu tranh minh hoạ.
  static const orange = Color(0xFFE9693D);
  static const tan = Color(0xFFA99679);
  static const sand = Color(0xFFD3C2A5);
  static const teal = Color(0xFF1F4B5A);
  static const sage = Color(0xFF9CC17B);
  static const rose = Color(0xFFF2A3A3);
  static const gold = Color(0xFFEBB94A);
  static const wood = Color(0xFF8A5B3C);
  static const pages = Color(0xFFFFF7EA);
}
