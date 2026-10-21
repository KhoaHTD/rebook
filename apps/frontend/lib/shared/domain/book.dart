import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';

/// Entity dùng chung cho nhiều feature (catalog, auction, cart, orders...).
/// Entity chỉ thuộc một feature thì đặt trong `features/<x>/domain/`.
enum BookCondition { likeNew, good, fair, worn, unknown }

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
