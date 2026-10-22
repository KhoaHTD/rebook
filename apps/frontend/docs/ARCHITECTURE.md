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

 Firebase Hosting: phục vụ file tĩnh từ build/web. FCM: thông báo đẩy qua core/notifications.
 USE_MOCK=true: mọi Fake...Repository gọi vào FakeStore (shared/data/fake) — backend thu nhỏ trong bộ nhớ.
```

Hai entrypoint: `main.dart` (người dùng, router `app/router/app_router.dart`) và `main_admin.dart`
(Staff/Admin, router `app/router/admin_router.dart`). Dùng chung toàn bộ `core/`, `shared/`, `features/`.

Feature hiện có:

| Feature | Nội dung |
|---|---|
| `auth` | đăng nhập, đăng ký + OTP, quên mật khẩu |
| `catalog` | trang Mua sách (kệ poster), tìm kiếm + lọc, chi tiết sách (kèm các bản khác của cùng cuốn), trang shop, thêm giỏ |
| `cart` | giỏ nhiều shop, đặt hàng (COD / ví / VNPay), kết quả thanh toán |
| `orders` | đơn mua + hóa đơn đấu giá: hủy, đã nhận, trả hàng, đánh giá, thanh toán lại |
| `wallet` | số dư, nạp, rút, sổ giao dịch |
| `notifications` | hộp thông báo |
| `account` | trang tài khoản, hồ sơ, sổ địa chỉ, cài đặt |
| `auction` | lịch phiên, danh mục lô, chi tiết lô, đăng ký + cọc, phòng LIVE, kết quả |
| `seller` | mở shop, kênh người bán, tin đăng, đơn của shop |
| `consignment` | ký gửi đấu giá phía người gửi |
| `staff` | (web quản trị) sơ duyệt, nhận sách, kiểm định, kho, giao lô |
| `admin` | (web quản trị) tổng quan, phiên, duyệt tin, người dùng, danh mục, cấu hình, rút tiền, khiếu nại |

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
Cái gì ≥2 feature cần (ví dụ `Book`, `BookPoster`, `BookForm`) thì nâng lên `shared/`.

## 3. Luồng dữ liệu mẫu

### Đọc danh sách (catalog)
1. `HomeScreen` watch `homeFeedProvider`; `SearchScreen` watch `searchResultsProvider` (phân trang, `loadMore`).
2. Provider gọi `catalogRepositoryProvider` → `FakeCatalogRepository` (mock) hoặc `ApiCatalogRepository`.
3. `ApiCatalogRepository` gọi `RestClient.listings...` trong `guardApi`, map DTO → entity bằng `shared/data/api_mappers.dart`.
4. UI hiển thị qua `AsyncValueView` (loading / lỗi có nút thử lại / data).

### Dữ liệu đổi ở feature khác
Feature không import nhau, nên dùng tín hiệu chung `core/utils/data_changes.dart`:
provider đọc gọi `ref.watchArea(DataArea.cart)`, thao tác ghi gọi `ref.read(dataChangesProvider.notifier).bump(DataArea.cart)`.
Ví dụ: thêm giỏ ở `catalog` → số trên icon giỏ (`cart`) tự cập nhật. Ở chế độ mock, FakeStore tự phát tín hiệu khi dữ liệu đổi.

### Realtime + action (auction)
- `liveRoomProvider(sessionId)`: lấy ảnh chụp `GET /sessions/{id}/state`, rồi nghe `/topic/sessions/{id}` (STOMP).
  Mỗi sự kiện được áp bằng hàm thuần `applyAuctionEvent` (`features/auction/domain/live_reducer.dart`, có test).
- Kết nối lại → tải lại ảnh chụp. Đồng hồ đếm theo giờ server (`RoomState.serverOffset`).
- `bidActionProvider`: `AsyncLoading` → gọi repo → `AsyncData`/`AsyncError`. Server quyết định bid hợp lệ (409 `PRICE_CHANGED`, `ALREADY_LEADING`, `LIMIT_EXCEEDED`...);
  client chỉ tính sẵn mức trả kế tiếp (`nextBidAmount`) và lý do chưa trả được (`bidBlockFor`).

### Đăng nhập
- `AuthController.login()` → `AuthRepository.login()` → `SessionController.signIn(tokens, user)` lưu vào secure storage.
- Web quản trị dùng lại `LoginScreen`; tài khoản USER bị đăng xuất và báo không có quyền. Staff chỉ vào được phần kho.
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

1. Backend cập nhật spec → copy vào `openapi/openapi.yaml` (bản hiện tại viết theo SRS).
2. `/sync-api` (hoặc `dart run swagger_parser && dart run build_runner build`).
3. Sửa `lib/shared/data/api_mappers.dart` nếu DTO đổi. Entity và UI thường không phải sửa.

DTO dùng `json_serializable` (swagger_parser chưa sinh được cú pháp freezed 4).

## 6. Giao diện, theme & responsive

Style **Liquid Glass** (chuẩn: `../../design-preview/png/lg-desktop.png`, `lg-mobile.png`):

- **Chữ San Francisco**: `AppFonts.family` = `null` trên iOS / macOS (Flutter dùng SF của hệ thống) và `Inter` trên web / Android
  (`assets/fonts/Inter-*.ttf`). Giấy phép Apple không cho đóng gói SF vào app, nên **không thêm file SF vào assets**.
- **Nền màu loang** (`AmbientBackground`, `shared/widgets/glass.dart`): các vệt màu lấy tông từ bìa sách (`AmbientPalette`), tính theo
  toạ độ màn hình. Vẽ ở `MaterialApp.builder` (sau sidebar) **và** trong mỗi `AppPage` — hai lớp khớp nhau nên trang vẫn đặc khi chuyển trang.
- **Kính** (`Glass`): làm mờ + tăng bão hoà phía sau, dải trắng trong, viền sáng, vệt phản chiếu, bóng mềm.
  Làm mờ chỉ cho phần nổi: sidebar, tab bar + nút tìm kiếm tròn, thanh đầu trang mobile, nút tròn (quay lại, ···), thanh mua hàng.
  Khối trong danh sách cuộn dùng kính trong không làm mờ (`InfoPanel` = `Glass(blur: false)`) để cuộn mượt.
- **Màu nhấn xanh** `AppColors.tint`: nút chính, mục đang chọn (sidebar: viên kính ánh xanh `tintSoft`; tab bar: "thấu kính" sáng), liên kết.
- Chip MỚI / ĐẤU GIÁ / LIVE là chip kính đặt lên góc bìa (`BookPoster.badge`).
- Màu của chính cuốn sách: `BlurredCover` (bìa phóng to + làm mờ) làm nền thẻ phiên đang diễn ra (`LiveHero`) và đầu trang chi tiết sách.
- Sách là trung tâm: `BookPoster` (tỉ lệ 2:3, có gáy + bóng). Sách chưa có ảnh dùng `DrawnCover` — màu + hình vẽ chọn ổn định theo id (`CoverPalette` trong `app_tokens.dart`).
- Desktop: lưới 4 poster/hàng (`PosterGrid`, 3 ở medium, 2 ở compact); mobile: kệ cuộn ngang (`Shelf`) + tab bar kính nổi ở đáy.
- Mỗi màn dùng `AppPage` (`shared/widgets/ui.dart`): tiêu đề lớn, nút quay lại tròn, hành động bên phải, kéo để tải lại.
  Khối thông tin bằng kính trong: `InfoPanel`; nút chính đầu trang: `HeaderAction`; trạng thái: `StatusPill`; tiền: `PriceText` / `MoneyLine`; bảng trượt: `shared/widgets/sheets.dart`.
- Đổi giao diện toàn app chỉ cần sửa: `app/theme/app_tokens.dart` (token, `AppColors`, `CoverPalette`), `app/theme/app_theme.dart`, và widget trong `shared/widgets/`.
- Theme mặc định **sáng**, ngôn ngữ mặc định **tiếng Việt**; người dùng đổi trong Cài đặt.
- Khung app: `app/router/app_shell.dart` (sidebar 3 nhóm trên desktop, tab bar trên mobile); web quản trị: `app/router/admin_shell.dart`.
- Kích thước: `AppSpacing`, `AppRadius`, `AppDurations`. Breakpoints: compact < 600 ≤ medium < 1024 ≤ expanded.

## 7. Môi trường & deploy

| File | Dùng khi |
|---|---|
| `env/dev.json` | chạy local, `USE_MOCK=true` |
| `env/prod.json` | build production, trỏ API thật |

CI (`.github/workflows/frontend-ci.yml` ở gốc repo, chỉ chạy khi `apps/frontend/**` đổi): pub get → format check → codegen → dart analyze (kèm riverpod_lint) → arch check → test → build web.
Deploy (`.github/workflows/frontend-deploy.yml`): push lên `main` → build web với `env/prod.json` → Firebase Hosting.
Cần secret `FIREBASE_SERVICE_ACCOUNT` và sửa project id trong `apps/frontend/.firebaserc`. Chưa có secret thì workflow chỉ build, bỏ qua bước deploy.
