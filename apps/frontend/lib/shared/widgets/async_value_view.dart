import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/skeleton.dart';

/// Hiển thị AsyncValue theo một kiểu thống nhất toàn app:
///
/// ```dart
/// AsyncValueView(
///   value: ref.watch(bookListProvider),
///   onRetry: () => ref.invalidate(bookListProvider),
///   data: (books) => BookGrid(books: books),
/// )
/// ```
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      // Tải lại (đổi dữ liệu, tải định kỳ) thì giữ nội dung cũ, không nháy lại khung xương.
      skipLoadingOnReload: true,
      data: data,
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
      loading: () => loading ?? const SkeletonList(),
    );
  }
}
