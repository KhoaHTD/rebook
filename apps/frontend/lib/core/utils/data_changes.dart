import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_changes.g.dart';

/// Vùng dữ liệu vừa đổi ở feature khác (feature không import nhau được).
abstract final class DataArea {
  static const cart = 'cart';
  static const orders = 'orders';
  static const wallet = 'wallet';
  static const notifications = 'notifications';
  static const listings = 'listings';
  static const auctions = 'auctions';
  static const consignments = 'consignments';
  static const warehouse = 'warehouse';
  static const profile = 'profile';
  static const favorites = 'favorites';
}

/// Bộ đếm phiên bản theo vùng. Provider đọc dữ liệu `watch` vùng của mình để tự tải lại:
///
/// ```dart
/// ref.watch(dataChangesProvider.select((v) => v[DataArea.cart]));
/// ```
/// Sau một thao tác ghi: `ref.read(dataChangesProvider.notifier).bump(DataArea.cart)`.
@Riverpod(keepAlive: true)
class DataChanges extends _$DataChanges {
  @override
  Map<String, int> build() => const {};

  void bump(String area) {
    if (area == 'all') {
      state = {
        for (final k in state.keys) k: state[k]! + 1,
        '*': (state['*'] ?? 0) + 1,
      };
      return;
    }
    state = {...state, area: (state[area] ?? 0) + 1};
  }
}

extension DataChangesRef on Ref {
  /// Theo dõi một vùng; provider gọi hàm này sẽ build lại khi vùng đổi.
  void watchArea(String area) {
    watch(dataChangesProvider.select((v) => (v[area] ?? 0) + (v['*'] ?? 0)));
  }
}
