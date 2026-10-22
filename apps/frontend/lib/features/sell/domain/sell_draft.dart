import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/book.dart';

part 'sell_draft.freezed.dart';

/// Tin đăng bán giá cố định đang soạn.
@freezed
abstract class SellDraft with _$SellDraft {
  const SellDraft._();

  /// Phí sàn bán giá cố định (%), người bán trả khi đơn hoàn tất.
  static const feePercent = 5;

  /// Bước tăng / giảm giá bằng nút +/−.
  static const priceStep = 5000;

  /// Backend yêu cầu 3–10 ảnh thật.
  static const minPhotos = 3;
  static const maxPhotos = 10;

  const factory SellDraft({
    @Default('') String title,
    @Default('') String author,
    @Default('') String publisher,
    int? publishYear,
    SellCategory? category,
    @Default(300) int weightGram,
    @Default(BookCondition.likeNew) BookCondition condition,
    @Default(65000) int price,

    /// Link ảnh (ứng dụng tải ảnh lên kho ảnh, backend chỉ lưu URL).
    @Default(<String>[]) List<String> imageUrls,
  }) = _SellDraft;

  int get fee => (price * feePercent / 100).round();

  /// Số tiền người bán thực nhận khi đơn hoàn tất.
  int get net => price - fee;

  bool get hasEnoughPhotos => imageUrls.length >= minPhotos;

  bool get isValid =>
      title.trim().isNotEmpty &&
      author.trim().isNotEmpty &&
      category != null &&
      weightGram > 0 &&
      hasEnoughPhotos &&
      price > 0;
}

@freezed
abstract class SellCategory with _$SellCategory {
  const factory SellCategory({required String id, required String name}) =
      _SellCategory;
}

/// Giá gợi ý dựa trên các tin cùng sách đã bán, theo tình trạng.
@freezed
abstract class PriceSuggestion with _$PriceSuggestion {
  const PriceSuggestion._();

  const factory PriceSuggestion({required int low, required int high}) =
      _PriceSuggestion;

  /// Điểm giữa, làm tròn tới bước giá.
  int get mid =>
      ((low + high) / 2 / SellDraft.priceStep).round() * SellDraft.priceStep;
}
