import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/token_storage.dart';

part 'intro_state.g.dart';

/// Đã xem màn giới thiệu chưa. `null` = đang đọc từ máy (router giữ màn loading cho tới khi biết).
@Riverpod(keepAlive: true)
class IntroSeen extends _$IntroSeen {
  @override
  bool? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(tokenStorageProvider).readIntroSeen();
    } on Object {
      state = false;
    }
  }

  Future<void> markSeen() async {
    state = true;
    try {
      await ref.read(tokenStorageProvider).writeIntroSeen();
    } on Object {
      // Không lưu được thì lần sau hiện lại intro, không sao.
    }
  }
}

/// Lời mời đăng nhập lúc mở app chỉ hiện một lần mỗi lần chạy (khách chọn "Chỉ xem sách" là thôi).
@Riverpod(keepAlive: true)
class GuestWelcomeShown extends _$GuestWelcomeShown {
  @override
  bool build() => false;

  void mark() => state = true;
}
