# Book Marketplace — Chợ sách cũ & đấu giá

Flutter app chạy trên **web + Android + iOS**. Backend là REST API riêng (OpenAPI) + WebSocket cho đấu giá.
Firebase chỉ dùng cho **hosting bản web** và **FCM (thông báo đẩy)**: chỉ `firebase_core` + `firebase_messaging`, gọi qua `core/notifications/`. Không dùng Firestore, Auth, Storage hay SDK Firebase nào khác.

Nghiệp vụ: [docs/SRS.txt](docs/SRS.txt) (đặc tả gốc, @Khoa 21/10/2026) + 3 sơ đồ `docs/srs-*.png`. Tiến độ: [docs/PROGRESS.md](docs/PROGRESS.md).

**Giao diện: style Liquid Glass đã duyệt (2026-10-22)** — chuẩn là `../../design-preview/png/lg-desktop.png` và `lg-mobile.png`
(nền màu loang lấy tông từ bìa sách, sidebar / tab bar / thanh đầu trang / thanh mua hàng bằng kính mờ nổi, màu nhấn xanh,
chữ là font hệ thống (`AppFonts` trong `app_tokens.dart` trả `null`: SF / Roboto / Segoe UI; không đóng gói font riêng, tiêu đề cũng dùng font hệ thống), nền sáng xanh sương #EBEFF4 (không trắng toát), sidebar kính tràn hết chiều cao sát mép trái, băng chuyền `HeroCarousel` ở trang chủ, chi tiết sách lấy bìa phóng to + làm mờ làm nền cả trang (`AppPage.background` + `BookBackdrop`) với chữ trong khung kính, poster sách lớn có gáy + bóng,
lưới 4 poster/hàng trên desktop, kệ cuộn ngang + tab bar kính nổi trên mobile). Mọi màn mới theo đúng style này:
dùng `Glass`, `InfoPanel`, `AppPage`, `HeaderAction` trong `shared/widgets/` thay vì tự vẽ nền / viền.

**Khu đấu giá tách riêng khỏi mua sách (2026-10-29):** đấu giá có khung, theme và trang chủ riêng — khung `app/router/auction_shell.dart` (sidebar + tab bar Sàn · Lịch · Của tôi · Kết quả · Tài khoản), theme luôn tối `AppTheme.auction()` (đỏ LIVE + vàng đồng, `AppColors.auction`), màn ở `features/auction/`. Công tắc `ModeSwitch` chuyển qua lại; app mua sách không bán / hiện đấu giá, chỉ còn thẻ mời sang (`AuctionEntryBanner`, slide banner). Màn đấu giá mới dùng màu từ theme (`context.appColors`) nên tự theo khu tối.

Chi tiết kiến trúc, lý do và ví dụ: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Đọc file đó trước khi thêm feature mới.

## Lệnh thường dùng

```bash
flutter pub get
dart run build_runner build          # sau khi sửa @riverpod / @freezed / DTO
dart run build_runner watch          # để chạy nền khi code
flutter gen-l10n                     # sau khi sửa file .arb
flutter run -d chrome --dart-define-from-file=env/dev.json
dart analyze --fatal-infos && dart run tool/arch_check.dart   # dùng dart analyze: có riverpod_lint
flutter test
```

`env/dev.json` có `USE_MOCK=true` → chạy bằng dữ liệu giả, không cần backend.

### Ghép với backend thật (`apps/backend`)

Merge code không tự tắt mock: `USE_MOCK` chỉ do file `--dart-define-from-file` quyết định. **Không sửa `env/dev.json`** (giữ mock để code giao diện).
Muốn nối backend thật thì chạy bằng `env/local.json` (`USE_MOCK=false`, API `http://localhost:8080/api`, WS `ws://localhost:8080/ws`):

```bash
flutter run -d chrome --dart-define-from-file=env/local.json
```

- Khi người dùng nói "chạy nối backend / chạy thật / ghép backend" → dùng `env/local.json`, không phải `dev.json`.
- Máy ảo Android gọi máy host bằng `10.0.2.2`: đổi `localhost` thành `10.0.2.2` trong bản sao của file env (đừng commit bản đã đổi).
- Backend (README ở `apps/backend`): cần Java 21 + PostgreSQL `localhost:5432`, tạo DB bằng `scripts/create-database.sql`, chạy `./mvnw spring-boot:run`. Tài khoản mẫu `buyer1@rebook.vn` / `Rebook@123`. Cổng 8080 bị chiếm → đặt biến môi trường `PORT` và đổi cổng trong file env.
- Gọi API lỗi / sai field → `openapi/openapi.yaml` của frontend có thể lệch với `apps/backend/openapi.yaml`: báo người dùng, rồi chạy `/sync-api`. Không sửa gì trong `apps/backend`.

## Stack đã chốt — KHÔNG thêm công nghệ khác

| Việc | Dùng | KHÔNG dùng |
|---|---|---|
| State / DI | Riverpod 3 + `@riverpod` codegen | Provider, Bloc, GetX, setState cho state chia sẻ |
| Điều hướng | go_router, path trong `app/router/routes.dart` | Navigator.push, auto_route |
| HTTP | Client sinh từ OpenAPI (`lib/api/generated`) trên Dio | http, gọi `dio.get('/...')` thủ công |
| Model | Entity: freezed. DTO: sinh tự động | Tự viết fromJson cho DTO |
| Realtime | `core/realtime/realtime_client.dart` | Mở WebSocket trong feature |
| Lưu token | `core/auth/token_storage.dart` | shared_preferences cho token |
| Text | `context.l10n.<key>` | Chuỗi hardcode trong widget |
| Màu / kích thước | `context.colors`, `context.appColors`, `AppSpacing`, `AppRadius` | `Colors.red`, `Color(0xFF...)`, số đo tuỳ ý |

Package được phép nằm trong `tool/allowed_packages.yaml`. Hook sẽ **chặn** package ngoài danh sách.
Nếu thật sự cần package mới: DỪNG LẠI, giải thích cho người dùng lý do, để họ thống nhất với team rồi tự thêm vào allowlist.

## Cấu trúc

```
lib/
  main.dart
  app/            # wiring: app.dart, env.dart, router/, theme/, l10n/
  core/           # hạ tầng: network/, auth/, realtime/, error/, settings/, utils/
  shared/         # dùng chung ≥2 feature: domain/ (entity), data/ (mapper, fake data), widgets/, layout/
  api/generated/  # SINH TỰ ĐỘNG từ openapi/openapi.yaml — không sửa tay
  features/<tên>/
    domain/       # entity riêng của feature + interface repository (Dart thuần)
    data/         # api_<x>_repository.dart, fake_<x>_repository.dart, <x>_mapper.dart, <x>_repository_provider.dart
    presentation/
      providers/  # @riverpod controllers / providers
      screens/    # màn hình (1 route = 1 screen)
      widgets/    # widget riêng của feature
```

## Luật kiến trúc (được `tool/arch_check.dart` kiểm tra tự động)

1. **Feature không import feature khác.** Cần dùng chung → chuyển vào `shared/`.
2. `core/` và `shared/` không import `features/`.
3. `domain/` là Dart thuần: không Flutter, Dio, Riverpod, `api/`, `data/`, `presentation/`.
4. `presentation/` không dùng Dio / WebSocket / secure storage / DTO. Chỉ import `data/*_provider.dart` của chính feature.
5. Luôn dùng `package:book_marketplace/...`, không import tương đối.
6. Không hardcode màu và chuỗi hiển thị trong `features/` và `shared/`.
7. Mọi lời gọi API trong repository bọc bằng `guardApi(...)` để lỗi thành `AppException`.

## Quy ước code

- Feature mẫu để bắt chước: **`features/catalog`** (CRUD đơn giản), **`features/auction`** (realtime + action), **`features/auth`** (form + controller).
- Provider đọc dữ liệu: hàm `@riverpod Future<T> xxx(Ref ref)`. Action có loading/error: class `@riverpod` với `FutureOr<void> build()` + method dùng `AsyncValue.guard`.
- UI hiển thị AsyncValue bằng `AsyncValueView`; lỗi hiển thị bằng `errorMessage(context, error)`.
- Repository provider chọn `Fake...` khi `Env.useMock`, ngược lại `Api...`. Mọi feature mới phải có cả Fake để chạy được khi chưa có backend.
- Thêm route: thêm path vào `Routes`, rồi thêm `GoRoute` trong `app_router.dart`. Route cần đăng nhập → cập nhật `Routes.requiresAuth`.
- Thêm chuỗi: thêm key vào **cả** `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`.
- Layout responsive: `context.windowSize` (compact / medium / expanded) + `MaxWidthBox` cho nội dung trên web.
- Giá tiền: `int` VND, hiển thị bằng `PriceText` hoặc `formatVnd`.
- Mỗi repository / controller mới phải có test trong `test/` (theo cấu trúc giống `lib/`).
- Bỏ qua lint của riverpod_lint phải ghi kèm tên plugin: `// ignore: riverpod_lint/<rule>` (kèm lý do). Không tắt lint hàng loạt.

## KHÔNG được làm

- Sửa file `*.g.dart`, `*.freezed.dart`, `lib/api/generated/**`, `lib/app/l10n/generated/**` (hook sẽ chặn) — sửa nguồn rồi chạy lại generator.
- Thêm package, đổi state management, đổi router, thêm Firebase SDK ngoài `firebase_core`/`firebase_messaging`.
- Tạo thư mục cấp cao mới trong `lib/` ngoài `app/ core/ shared/ api/ features/`.
- Gọi API bằng đường dẫn tự gõ khi spec chưa có endpoint: báo người dùng cập nhật `openapi/openapi.yaml` rồi chạy `/sync-api`.

## Công cụ Claude Code trong repo

- `/new-feature <tên>` — tạo khung feature đúng chuẩn.
- `/sync-api` — sinh lại client từ OpenAPI.
- Agent `frontend-architecture-reviewer` (ở `.claude/agents/` gốc repo) — review diff theo các luật trên trước khi tạo PR.
- Hooks (`.claude/settings.json`): chặn package lạ + file sinh tự động, tự `dart format`, chạy `dart analyze` + arch check khi kết thúc lượt.

## Làm việc nhóm: Admin & Staff (đọc [docs/TEAM_GUIDE.md](docs/TEAM_GUIDE.md))

- **Luật cứng: không đưa code `apps/backend` lên nhánh `interface` hay nhánh con của nó** (hook push, hook Claude và CI "Backend Guard" cùng chặn). Phần còn lại là luật nhẹ: PR + review, không tự đổi file hạ tầng / thêm package, giao diện sửa thoải mái.
- Phần quản trị chia hai module: `features/admin/**` và `features/staff/**` (+ `test/features/<vai>/`), mỗi vai một file module nên ít đụng nhau.
- **Router và sidebar quản trị do module quyết định**: thêm màn = sửa `features/<vai>/presentation/<vai>_module.dart` (route + mục sidebar + `smokePaths`) + file màn hình. Không sửa `app/router/admin_router.dart`, `admin_shell.dart`, `admin_modules.dart`.
- **Bố cục màn Admin / Staff do người làm tự sáng tạo.** Gu chung (sáng, phẳng, nút đen, tiêu đề serif, dữ liệu là nhân vật chính) và đồ nghề có sẵn (`AppPage`, `AdminCard`, `AdminKpi`, `AdminPalette`) nằm ở [docs/ADMIN_VIBE.md](docs/ADMIN_VIBE.md): đọc để hiểu bối cảnh, không phải luật. Không có máy nào chặn kiểu dáng.
- Chuỗi mới: `node tool/l10n_add.mjs <file.json> --zone adm|stf` (key bắt đầu `adm` / `stf`, không đổi key cũ).
- Responsive: điểm gãy khung quản trị 900px (dưới đó sidebar là ngăn kéo). Mọi màn phải ổn ở 375 / 800 / 1400px. `test/layout/admin_staff_layout_test.dart` quét các route đã khai báo và chỉ hỏng khi có lỗi tràn / dựng hình; đừng sửa test này để "xanh".
- Bị hook chặn (backend trên nhánh bảo vệ, package lạ, file sinh tự động) → dừng và báo người dùng; không lách.
