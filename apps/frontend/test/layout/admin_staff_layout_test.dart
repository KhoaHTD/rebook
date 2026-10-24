// Chốt chặn vỡ bố cục của web / app quản trị: tự mở MỌI route của các module Admin / Staff
// (xem lib/app/router/admin_module.dart) ở điện thoại, máy tính bảng và desktop, bằng phông thật
// (Inter / Newsreader), rồi báo mọi lỗi dựng hình, kể cả "RenderFlex overflowed".
//
// Màn mới tự được quét nếu đã đăng ký route trong module. Route có `:tham_số` phải khai báo
// `smokePaths` trong module, nếu không test này hỏng (để màn mới không lọt khỏi kiểm tra).
// Thư mục này thuộc vùng khoá (tool/zones.txt): không sửa để làm test "xanh" — hãy sửa màn hình.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/app.dart';
import 'package:book_marketplace/app/router/admin_modules.dart';
import 'package:book_marketplace/app/router/admin_router.dart';
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Token lưu trong bộ nhớ (thay secure storage, vốn không chạy được trong test).
class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage() : super(const FlutterSecureStorage());

  AuthTokens? _tokens;
  AuthUser? _user;

  @override
  Future<AuthTokens?> read() async => _tokens;
  @override
  Future<AuthUser?> readUser() async => _user;
  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;
  @override
  Future<void> writeUser(AuthUser user) async => _user = user;
  @override
  Future<void> clear() async {
    _tokens = null;
    _user = null;
  }
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  await load('Inter', [
    for (final w in [400, 500, 600, 700, 800]) 'Inter-$w.ttf',
  ]);
  await load('Newsreader', [
    for (final w in [500, 600, 700]) 'Newsreader-$w.ttf',
  ]);
}

/// Mọi mẫu đường dẫn đầy đủ trong cây route (vd. `/sessions/:id/monitor`).
Iterable<String> _patterns(List<RouteBase> routes, [String prefix = '']) sync* {
  for (final r in routes) {
    if (r is! GoRoute) continue;
    final full = r.path.startsWith('/')
        ? r.path
        : '${prefix == '/' ? '' : prefix}/${r.path}';
    yield full;
    yield* _patterns(r.routes, full);
  }
}

RegExp _regexOf(String pattern) =>
    RegExp('^${pattern.replaceAll(RegExp(r':\w+'), r'[^/]+')}\$');

const _sizes = <(String, Size)>[
  ('điện thoại', Size(375, 812)),
  ('máy tính bảng', Size(800, 1100)),
  ('desktop', Size(1400, 860)),
];

const _roles = <(String, String)>[
  ('admin', 'admin@rebook.vn'),
  ('staff', 'staff@rebook.vn'),
];

void main() {
  setUpAll(_loadFonts);

  test('mọi route có tham số đều có địa chỉ mẫu (smokePaths)', () async {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(_MemoryTokenStorage()),
      ],
    );
    addTearDown(container.dispose);
    final store = container.read(fakeStoreProvider);
    final user = store.login('admin@rebook.vn', '123456');
    container.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await container
        .read(sessionControllerProvider.notifier)
        .signIn(
          const AuthTokens(accessToken: 'a', refreshToken: 'r'),
          user.toAuthUser(),
        );

    final smoke = <String>[
      for (final m in adminModules)
        if (m.smokePaths != null) ...await m.smokePaths!(container),
    ];
    final missing = [
      for (final p in _patterns([for (final m in adminModules) ...m.routes]))
        if (p.contains(':') && !smoke.any(_regexOf(p).hasMatch)) p,
    ];
    expect(
      missing,
      isEmpty,
      reason:
          'Route có tham số nhưng module chưa khai báo smokePaths cho: $missing',
    );
  });

  for (final (role, email) in _roles) {
    for (final (label, size) in _sizes) {
      testWidgets(
        '$role dựng mọi route không lỗi bố cục — $label ${size.width.toInt()}px',
        (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final container = ProviderContainer(
            overrides: [
              tokenStorageProvider.overrideWithValue(_MemoryTokenStorage()),
            ],
          );
          final store = container.read(fakeStoreProvider);
          final user = store.login(email, '123456');
          container.read(sessionControllerProvider);
          await tester.pump();
          await container
              .read(sessionControllerProvider.notifier)
              .signIn(
                const AuthTokens(accessToken: 'a', refreshToken: 'r'),
                user.toAuthUser(),
              );

          final isAdmin = role == 'admin';
          final paths = <String>[];
          for (final m in adminModules) {
            for (final p in m.ownedPaths) {
              if (isAdmin || m.staffCanOpen(p)) paths.add(p);
            }
            if (m.smokePaths != null) {
              final extra = await tester.runAsync(
                () => m.smokePaths!(container),
              );
              paths.addAll([
                for (final p in extra!)
                  if (isAdmin || m.staffCanOpen(p)) p,
              ]);
            }
          }
          expect(paths, isNotEmpty);

          final errors = <String>[];
          final previous = FlutterError.onError;
          var current = '';
          FlutterError.onError = (d) {
            errors.add('[$current] ${d.exceptionAsString().split('\n').first}');
          };
          try {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: const AdminApp(),
              ),
            );
            await tester.pump(const Duration(milliseconds: 500));
            final router = container.read(adminRouterProvider);
            for (final p in paths) {
              current = p;
              router.go(p);
              for (var i = 0; i < 4; i++) {
                await tester.pump(const Duration(milliseconds: 300));
              }
              // Khung hẹp: ngăn kéo sidebar phải mở được.
              if (size.width < 900) {
                final menu = find.byIcon(Icons.menu_rounded);
                if (menu.evaluate().isNotEmpty) {
                  await tester.tap(menu.first);
                  await tester.pump(const Duration(milliseconds: 400));
                  await tester.tapAt(const Offset(370, 400));
                  await tester.pump(const Duration(milliseconds: 400));
                }
              }
            }
          } finally {
            FlutterError.onError = previous;
            await tester.pumpWidget(const SizedBox.shrink());
            container.dispose();
            await tester.pump();
          }
          expect(errors, isEmpty, reason: errors.take(12).join('\n'));
        },
      );
    }
  }
}
