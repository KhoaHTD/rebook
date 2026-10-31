import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'catalog.freezed.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    String? parentId,
  }) = _Category;
}

@freezed
abstract class BookImage with _$BookImage {
  const factory BookImage({
    required String url,
    @Default(false) bool fromStaff,
  }) = _BookImage;
}

/// Thông tin cuốn sách, tách khỏi Listing và Lot (SRS 9) để một cuốn
/// không bán được ở đấu giá có thể chuyển sang bán thường.
@freezed
abstract class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String title,
    required String author,
    required ConditionGrade condition,
    @Default([]) List<BookImage> images,
    String? publisher,
    int? publishYear,
    String? isbn,
    String? language,
    int? pages,
    String? categoryId,
    String? categoryName,
    String? description,
    int? weightGram,
  }) = _Book;

  String? get coverUrl => images.isEmpty ? null : images.first.url;
}

/// Thông tin sách người dùng nhập khi đăng bán hoặc ký gửi.
@freezed
abstract class BookDraft with _$BookDraft {
  const factory BookDraft({
    required String title,
    required String author,
    required ConditionGrade condition,
    required List<String> imageUrls,
    String? publisher,
    int? publishYear,
    String? isbn,
    String? language,
    int? pages,
    String? categoryId,
    String? description,
    int? weightGram,
  }) = _BookDraft;
}

/// Tin bán giá cố định.
@freezed
abstract class Listing with _$Listing {
  const Listing._();

  const factory Listing({
    required String id,
    required Book book,
    required ShopSummary shop,
    required int price,
    required int stock,
    required ListingStatus status,
    required DateTime createdAt,
    String? rejectReason,

    /// Admin duyệt / từ chối tin này và lúc nào (SRS 8.1: nhật ký).
    String? reviewedBy,
    DateTime? reviewedAt,
  }) = _Listing;

  bool get purchasable => status == ListingStatus.active && stock > 0;
}

@freezed
abstract class ListingQuery with _$ListingQuery {
  const factory ListingQuery({
    String? q,
    String? categoryId,
    String? author,
    ConditionGrade? condition,
    int? minPrice,
    int? maxPrice,
    String? shopId,
    @Default(ListingSort.newest) ListingSort sort,
  }) = _ListingQuery;
}

@freezed
abstract class Review with _$Review {
  const factory Review({
    required String id,
    required String orderId,
    required String reviewerName,
    required int rating,
    required DateTime createdAt,
    String? comment,
  }) = _Review;
}

/// Một trang kết quả phân trang.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int size;
  final int total;

  bool get hasMore => (page + 1) * size < total;
}
