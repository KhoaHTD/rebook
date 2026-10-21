import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// Phát thời gian hiện tại mỗi giây — dùng cho đồng hồ đếm ngược.
/// Override trong test để cố định thời gian.
@riverpod
Stream<DateTime> clock(Ref ref) => Stream<DateTime>.periodic(
  const Duration(seconds: 1),
  (_) => DateTime.now(),
);
