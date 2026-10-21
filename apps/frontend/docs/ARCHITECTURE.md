# Kiến trúc frontend

## 1. Tổng quan

```
           ┌────────────────────────── Flutter app (web / Android / iOS) ───────────────────────────┐
           │                                                                                         │
 người dùng│  presentation  ──watch──▶  providers  ──read──▶  repository (interface, domain/)          │
           │   (screens,                (@riverpod)                 ▲                                 │
           │    widgets)                                            │ implements                      │
           │                                         ┌──────────────┴──────────────┐                  │
           │                                         │ Api...Repository  Fake...    │  (data/)        │
           │                                         └──────┬───────────────┬──────┘                  │
           │                                     RestClient │               │ RealtimeClient         │
           │                                   (api/generated)              │ (core/realtime)         │
           └────────────────────────────────────────┼───────────────┼─────────────────────────────────┘
                                                    ▼               ▼
                                             REST API (JWT)    WebSocket (đấu giá)
                                                 └── backend riêng ──┘

 Firebase Hosting: chỉ phục vụ file tĩnh từ build/web.
```

## 2. Các tầng và luật phụ thuộc

| Thư mục | Chứa gì | Được import |
|---|---|---|
| `app/` | MaterialApp, router, theme, l10n, env | mọi thứ |
| `core/` | Dio + interceptor, token, session, realtime, lỗi, settings, tiện ích | `api/`, `app/env.dart`, package |
| `shared/` | Entity dùng chung (`Book`), mapper, fake data, widget và layout chung | `core/`, `app/theme`, `app/l10n`, `api/` (chỉ trong `shared/data`) |
| `api/generated/` | Client + DTO sinh từ OpenAPI | — |
| `features/x/domain/` | Entity riêng, interface repository | `shared/domain`, `core/auth/auth_tokens.dart`, `freezed_annotation` |
| `features/x/data/` | Repository Api/Fake, mapper DTO→entity, provider chọn repo | `domain/`, `core/`, `shared/`, `api/` |
| `features/x/presentation/` | Screen, widget, provider/controller | `domain/`, `data/*_provider.dart`, `core/`, `shared/`, `app/router/routes.dart`, `app/theme`, `app/l10n` |

Cấm: feature → feature khác; `core/`/`shared/` → `features/`; domain → Flutter/IO.
Tất cả luật này được kiểm tra bởi `dart run tool/arch_check.dart` (chạy trong hook và CI).

**Vì sao feature không import nhau?** Mỗi người/nhóm phụ trách một feature, sửa thoải mái mà không làm vỡ feature khác.
Cái gì ≥2 feature cần (ví dụ `Book`, `BookCover`) thì nâng lên `shared/`.

## 3. Luồng dữ liệu mẫu

### Đọc danh sách (catalog)
1. `CatalogScreen` watch `bookListProvider`.
2. `bookListProvider` watch `bookSearchQueryProvider` + gọi `catalogRepositoryProvider.listBooks()`.
3. `catalogRepositoryProvider` trả `FakeCatalogRepository` (mock) hoặc `ApiCatalogRepository`.
4. `ApiCatalogRepository` gọi `RestClient.books.listBooks()` trong `guardApi`, map `BookDto → Book`.
5. UI hiển thị qua `AsyncValueView` (loading / error có nút thử lại / data).

### Realtime + action (auction)
- `auctionRoomProvider(id)` là `Stream<Auction>`: lấy trạng thái qua REST, rồi nghe kênh WebSocket `auctions/<id>`.
  Backend gửi **nguyên `AuctionDto`** mỗi khi có thay đổi.
- `BidControllerProvider(id).placeBid(amount)`: `AsyncLoading` → gọi repo → `AsyncData`/`AsyncError`.
  Backend là nơi duy nhất quyết định bid hợp lệ; client chỉ gợi ý `nextMinBid`.
- Provider là autoDispose: rời màn hình → hủy subscription → đóng socket.

### Đăng nhập
- `LoginController.login()` → `AuthRepository.login()` → `SessionController.signIn(tokens)` lưu vào secure storage.
- Router nghe `sessionControllerProvider` và tự redirect (`/login?from=...` ↔ trang cũ).
- `AuthInterceptor` gắn Bearer token; gặp 401 thì refresh một lần (QueuedInterceptor), thất bại thì `signOut()`.

## 4. Thêm một feature mới (ví dụ `cart`)

Dùng `/new-feature cart` trong Claude Code, hoặc làm tay:

```
lib/features/cart/
  domain/cart_item.dart              # @freezed abstract class CartItem
  domain/cart_repository.dart        # abstract interface class CartRepository
  data/api_cart_repository.dart      # dùng RestClient, bọc guardApi
  data/fake_cart_repository.dart     # dữ liệu giả
  data/cart_repository_provider.dart # Env.useMock ? Fake : Api
  presentation/providers/cart_providers.dart
  presentation/screens/cart_screen.dart
test/features/cart/...
```

Rồi: thêm path vào `Routes` → `GoRoute` trong `app_router.dart` → chuỗi vào 2 file `.arb` → `dart run build_runner build` → `flutter gen-l10n`.

## 5. Làm việc với API

1. Backend cập nhật spec → copy vào `openapi/openapi.yaml` (file hiện tại là PLACEHOLDER).
2. `/sync-api` (hoặc `dart run swagger_parser && dart run build_runner build`).
3. Sửa mapper trong `data/` nếu DTO đổi. Entity và UI thường không phải sửa.

DTO dùng `json_serializable` (swagger_parser chưa sinh được cú pháp freezed 4).

## 6. Theme & responsive

- Màu: `ColorScheme.fromSeed(AppPalette.leather)` + `AppColors` (ThemeExtension) cho màu ngữ nghĩa (đấu giá đang chạy, giá, tình trạng sách).
- Dark mode: chỉnh trong `AppColors.dark` và `AppTheme.dark()`. Người dùng chọn trong màn Tài khoản.
- Kích thước: `AppSpacing`, `AppRadius`, `AppDurations`.
- Breakpoints: compact < 600 ≤ medium < 1024 ≤ expanded. `AppShell` tự đổi NavigationBar ↔ NavigationRail.

## 7. Môi trường & deploy

| File | Dùng khi |
|---|---|
| `env/dev.json` | chạy local, `USE_MOCK=true` |
| `env/prod.json` | build production, trỏ API thật |

CI (`.github/workflows/frontend-ci.yml` ở gốc repo, chỉ chạy khi `apps/frontend/**` đổi): pub get → format check → codegen → dart analyze (kèm riverpod_lint) → arch check → test → build web.
Deploy (`.github/workflows/frontend-deploy.yml`): push lên `main` → build web với `env/prod.json` → Firebase Hosting.
Cần secret `FIREBASE_SERVICE_ACCOUNT` và sửa project id trong `apps/frontend/.firebaserc`. Chưa có secret thì workflow chỉ build, bỏ qua bước deploy.
