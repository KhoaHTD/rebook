---
name: new-feature
description: Tạo khung một feature mới đúng kiến trúc của dự án (domain/data/presentation, Fake + Api repository, provider, route, l10n, test). Dùng khi người dùng muốn thêm một màn hình hoặc nghiệp vụ mới như giỏ hàng, đơn hàng, đăng bán sách, chat...
argument-hint: <tên_feature_snake_case> [mô tả ngắn]
---

# Tạo feature mới: $ARGUMENTS

Làm theo đúng thứ tự. Bắt chước code của `lib/features/catalog` (đọc dữ liệu) và
`lib/features/auction` (action + realtime). Đọc 2 feature đó trước nếu chưa đọc trong phiên này.

## 0. Xác định phạm vi

- Tên feature: snake_case, số ít hoặc danh từ nghiệp vụ (`cart`, `orders`, `listing`, `chat`).
- Nếu chưa rõ: feature có những màn hình nào, đọc/ghi dữ liệu gì, cần đăng nhập không? Hỏi người dùng tối đa 1 lần.
- Kiểm tra `openapi/openapi.yaml` đã có endpoint chưa. Chưa có → vẫn làm, nhưng `Api...Repository`
  ném `UnimplementedError('Chờ endpoint ... trong OpenAPI')` và báo người dùng ở cuối.
- Entity đã có trong `lib/shared/domain/` thì dùng lại, không tạo bản sao.
  Entity mà feature khác cũng sẽ cần → đặt vào `lib/shared/domain/`.

## 1. Domain — `lib/features/<f>/domain/`

```dart
// <entity>.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part '<entity>.freezed.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({required String id, required int price}) = _CartItem;
}
```

```dart
// <f>_repository.dart
abstract interface class CartRepository {
  Future<List<CartItem>> list();
}
```

Dart thuần — không import Flutter / Riverpod / Dio / api.

## 2. Data — `lib/features/<f>/data/`

- `api_<f>_repository.dart`: nhận `api.RestClient`, mọi method bọc `guardApi(() async { ... })`, map DTO → entity
  (mapper riêng `<f>_mapper.dart` nếu dài).
- `fake_<f>_repository.dart`: dữ liệu giả hợp lý (tiếng Việt), có `Future.delayed` 300–500ms.
- `<f>_repository_provider.dart`:

```dart
@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) =>
    Env.useMock ? FakeCartRepository() : ApiCartRepository(ref.watch(restClientProvider));
```

## 3. Presentation — `lib/features/<f>/presentation/`

- `providers/<f>_providers.dart`: provider đọc dữ liệu (`@riverpod Future<T> ...`) và controller cho action
  (`@riverpod class XController` với `FutureOr<void> build()` + `AsyncValue.guard`).
- `screens/<name>_screen.dart`: `ConsumerWidget`, dùng `AsyncValueView`, `MaxWidthBox`, `context.windowSize`.
- `widgets/`: widget riêng. Widget mà feature khác cũng cần → `lib/shared/widgets/`.
- Chỉ dùng `context.l10n`, `context.colors`, `context.appColors`, `AppSpacing`, `AppRadius`.

## 4. Nối vào app

1. `lib/app/router/routes.dart`: thêm path (hằng số hoặc hàm có tham số). Cần đăng nhập → cập nhật `requiresAuth`.
2. `lib/app/router/app_router.dart`: thêm `GoRoute`. Là tab chính → thêm `StatefulShellBranch`
   và destination trong `lib/app/router/app_shell.dart`.
3. Thêm chuỗi vào **cả** `lib/app/l10n/arb/app_vi.arb` và `app_en.arb` (hook tự chạy `flutter gen-l10n`).

## 5. Test — `test/features/<f>/`

- Test repository fake hoặc logic entity (Dart thuần).
- Test controller bằng `ProviderContainer` với `overrides: [<f>RepositoryProvider.overrideWithValue(...)]`.
- Mẫu: `test/features/auction/bid_controller_test.dart`.

## 6. Kiểm tra

```bash
dart run build_runner build
dart analyze --fatal-infos
dart run tool/arch_check.dart
flutter test
```

Tất cả phải sạch. Cuối cùng tóm tắt cho người dùng: các file đã tạo, route mới, endpoint còn thiếu (nếu có).
