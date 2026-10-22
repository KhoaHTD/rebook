import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';

/// Thang tình trạng sách chuẩn (khớp backend `ConditionGrade`):
/// Mới · Như mới · Tốt · Khá · Trung bình.
enum BookCondition {
  /// NEW — chưa đọc, còn nguyên.
  brandNew,

  /// LIKE_NEW — đã đọc, không dấu vết.
  likeNew,

  /// VERY_GOOD — dấu hiệu dùng nhẹ, không ghi chú.
  veryGood,

  /// GOOD — có ghi chú / gấp góc / ố vàng nhẹ, đủ trang.
  good,

  /// ACCEPTABLE — hư hại rõ, vẫn đọc được.
  acceptable,
  unknown;

  /// Các mức người dùng chọn được (bỏ `unknown`).
  static const selectable = [brandNew, likeNew, veryGood, good, acceptable];
}

/// Entity dùng chung cho nhiều feature (catalog, auction, cart, orders...).
/// Entity chỉ thuộc một feature thì đặt trong `features/<x>/domain/`.
@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    required String author,
    required BookCondition condition,

    /// VND
    required int price,
    required String sellerName,
    String? imageUrl,
    String? description,
  }) = _Book;
}
