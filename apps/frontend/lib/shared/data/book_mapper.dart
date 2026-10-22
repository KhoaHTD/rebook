import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/shared/domain/book.dart';

/// Tiền backend trả về dạng số (NUMERIC 15,0) → int VND.
int vnd(num? value) => value?.toInt() ?? 0;

/// id backend là số → id domain là chuỗi (dùng trong route).
String sid(int? id) => '${id ?? ''}';

extension ListingSummaryMapper on api.ListingSummary {
  Book toBook() => Book(
    id: sid(id),
    title: title ?? '',
    author: author ?? '',
    condition: conditionGrade.toDomain(),
    price: vnd(price),
    sellerName: shop?.name ?? '',
    imageUrl: coverUrl,
  );
}

extension ListingDetailMapper on api.ListingDetail {
  Book toBook() => Book(
    id: sid(id),
    title: book?.title ?? '',
    author: book?.author ?? '',
    condition: book?.conditionGrade.toDomain() ?? BookCondition.unknown,
    price: vnd(price),
    sellerName: shop?.name ?? '',
    imageUrl: book?.coverUrl,
    description: book?.description,
  );
}

extension ConditionGradeMapper on api.ConditionGrade? {
  BookCondition toDomain() => switch (this) {
    api.ConditionGrade.valueNew => BookCondition.brandNew,
    api.ConditionGrade.likeNew => BookCondition.likeNew,
    api.ConditionGrade.veryGood => BookCondition.veryGood,
    api.ConditionGrade.good => BookCondition.good,
    api.ConditionGrade.acceptable => BookCondition.acceptable,
    _ => BookCondition.unknown,
  };
}

extension BookConditionToApi on BookCondition {
  api.ConditionGrade toApi() => switch (this) {
    BookCondition.brandNew => api.ConditionGrade.valueNew,
    BookCondition.likeNew => api.ConditionGrade.likeNew,
    BookCondition.veryGood => api.ConditionGrade.veryGood,
    BookCondition.good => api.ConditionGrade.good,
    BookCondition.acceptable ||
    BookCondition.unknown => api.ConditionGrade.acceptable,
  };
}
