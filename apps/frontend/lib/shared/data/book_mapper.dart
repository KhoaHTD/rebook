import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/shared/domain/book.dart';

/// DTO (sinh từ OpenAPI) -> entity. Khi backend đổi field, chỉ sửa mapper.
extension BookDtoMapper on api.BookDto {
  Book toDomain() => Book(
    id: id,
    title: title,
    author: author,
    condition: condition.toDomain(),
    price: price,
    sellerName: sellerName,
    imageUrl: imageUrl,
    description: description,
  );
}

extension BookConditionMapper on api.BookCondition {
  BookCondition toDomain() => switch (this) {
    api.BookCondition.likeNew => BookCondition.likeNew,
    api.BookCondition.good => BookCondition.good,
    api.BookCondition.fair => BookCondition.fair,
    api.BookCondition.worn => BookCondition.worn,
    api.BookCondition.$unknown => BookCondition.unknown,
  };
}
