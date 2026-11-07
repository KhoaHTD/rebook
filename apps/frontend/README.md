# Chợ Sách Cũ — Book Marketplace

Mua bán sách cũ và đấu giá realtime. Flutter cho **web + Android + iOS**, deploy web lên **Firebase Hosting**.
Giao diện theo style **Liquid Glass**, chữ hệ thống (xem `docs/design/lg-desktop.png`, `lg-mobile.png` và mục 6 của [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)).

## Bắt đầu

Cần Flutter **3.47.x** (stable). Mọi lệnh dưới đây chạy trong thư mục `apps/frontend`.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run -d chrome --dart-define-from-file=env/dev.json
```

`env/dev.json` bật `USE_MOCK=true`: app chạy hoàn toàn bằng một backend giả trong bộ nhớ
(`lib/shared/data/fake/`), có cả phiên đấu giá chạy thật với người trả giá ảo. Đây là chế độ để code giao diện, **không sửa file này**.

### Nối backend thật

Backend ở `apps/backend` (xem [README backend](../backend/README.md): Java 21, PostgreSQL, `./mvnw spring-boot:run`, hoặc `scripts/reset-demo.ps1` để có đủ dữ liệu demo).

| File env | Trỏ tới |
|---|---|
| `env/dev.json` | không có backend (mock) |
| `env/local.json` | backend `localhost:8080` |
| `env/local.8081.json` | backend `localhost:8081` (khi cổng 8080 bị chương trình khác chiếm) |
| `env/tunnel.json`, `env/android.tunnel.json` | demo online qua Cloudflare Tunnel (xem `docs/DEMO_ONLINE.md`; link trong `android.tunnel.json` đổi mỗi lần bật tunnel) |
| `env/prod.json` | bản deploy (địa chỉ mẫu, thay bằng API thật) |

```bash
flutter run -d chrome --web-port 5199 --dart-define-from-file=env/local.8081.json
```

- Web dùng cổng `5199` để khớp địa chỉ đã khai báo cho đăng nhập Google và trang quay về sau thanh toán ZaloPay.
- Máy ảo Android gọi máy host bằng `10.0.2.2`: sao chép file env, đổi `localhost` thành `10.0.2.2` (đừng commit bản đã đổi). Chạy máy ảo với `emulator -avd <tên> -dns-server 1.1.1.1,8.8.8.8` để máy ảo phân giải được tên miền (ảnh bìa Cloudinary, Google).

### Tài khoản

- **Backend thật** (dữ liệu demo): mật khẩu mọi tài khoản `Rebook@123`: `admin@`, `staff@`, `seller1..4@`, `buyer1..7@`, `locked@` (bị khoá), `banned@` (bị cấm đấu giá), đều `@rebook.vn`.
- **Mock** (`env/dev.json`): mật khẩu và OTP đều `123456`:

| Email | Vai trò |
|---|---|
| `minhanh@rebook.vn` | người dùng có shop, đã đăng ký phiên đang LIVE (số bài #027) |
| `khoa@rebook.vn` | người dùng chưa có shop |
| `staff@rebook.vn` | nhân viên kho (mã lịch hẹn mẫu để nhận sách: `KG-4521`) |
| `admin@rebook.vn` | quản trị |

Ở chế độ mock, ZaloPay được thay bằng màn cổng thanh toán giả lập (chọn giao dịch thành công / thất bại).

### Hai entrypoint

Một địa chỉ web phục vụ tất cả: tài khoản Staff / Admin tự được đưa sang khung quản trị sau khi đăng nhập. Entrypoint riêng cho web quản trị vẫn dùng được:
`flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/dev.json`.

Code sinh tự động (`*.g.dart`, `*.freezed.dart`, l10n) **không commit**. Sau mỗi lần `git pull`, nếu thấy lỗi thiếu file thì chạy lại 2 lệnh codegen ở trên
(hoặc để `dart run build_runner watch` chạy nền).

## Tài liệu

- [CLAUDE.md](CLAUDE.md): luật và quy ước ngắn gọn (Claude Code tự đọc file này).
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): kiến trúc chi tiết, luồng dữ liệu, cách thêm feature, giao diện.
- [docs/SRS.txt](docs/SRS.txt): đặc tả nghiệp vụ gốc. [docs/DECISIONS.md](docs/DECISIONS.md), [docs/DECISIONS_V2.md](docs/DECISIONS_V2.md): các quyết định ở chỗ SRS chưa nói rõ.
- [docs/PROGRESS.md](docs/PROGRESS.md): tiến độ. [docs/BACKEND_HANDOFF.md](docs/BACKEND_HANDOFF.md): phần giao diện làm nhiều hơn SRS mà backend phải theo.
- [docs/TEAM_GUIDE.md](docs/TEAM_GUIDE.md), [docs/ADMIN_VIBE.md](docs/ADMIN_VIBE.md): làm việc nhóm, bối cảnh khu Admin / Staff.

## Vibecode với Claude Code

Repo đã cấu hình sẵn để Claude không phá kiến trúc. Nên mở Claude Code ở **gốc repo** (hooks, agent, MCP nằm ở `.claude/` và `.mcp.json` gốc); mở trong `apps/frontend` cũng có hooks và skills nhưng không có agent:

| Công cụ | Tác dụng |
|---|---|
| `CLAUDE.md` | Stack đã chốt, cấu trúc thư mục, luật phụ thuộc |
| Hook chặn package | Chỉ cho dùng package trong `tool/allowed_packages.yaml` |
| Hook chặn file sinh tự động | Không sửa tay `*.g.dart`, `lib/api/generated/`... |
| Hook format | Tự chạy `dart format` sau mỗi lần sửa; tự `flutter gen-l10n` khi sửa `.arb` |
| Hook khi kết thúc lượt | Chạy `dart analyze` (kèm riverpod_lint) + `tool/arch_check.dart`, còn lỗi thì Claude phải sửa tiếp |
| `/new-feature <tên>` | Tạo khung feature đúng chuẩn |
| `/sync-api` | Sinh lại client khi backend cập nhật OpenAPI |
| Agent `frontend-architecture-reviewer` | Nhờ Claude "review kiến trúc" trước khi tạo PR |
| `.mcp.json` ở gốc repo (Dart MCP) | Claude chạy analyze/test/hot reload, xem widget tree |

## Quy trình team

1. Mỗi người làm trên một nhánh cắt từ `main`, ưu tiên mỗi người một thư mục `lib/features/<x>`; mở PR, không push thẳng `main`.
2. Trước khi tạo PR: `dart analyze --fatal-infos && dart run tool/arch_check.dart && flutter test`.
3. CI chạy lại toàn bộ kiểm tra. PR được deploy preview lên Firebase (link comment vào PR).
4. Merge vào `main` thì tự deploy live.

**Thêm package mới:** thảo luận với team trước, rồi người duyệt tự sửa `tool/allowed_packages.yaml` (Claude bị chặn sửa file này). Gần đây đã thêm `pdf` và `printing` (xuất báo cáo PDF của Admin).

## API

- Client sinh từ **spec thật của backend** (`../backend/openapi.yaml`, xuất từ `/v3/api-docs.yaml`); `openapi/openapi.yaml` là hợp đồng viết từ SRS kèm phần giao diện làm thêm, dùng làm danh sách việc cho backend (`dart run tool/api_gap.dart` so hai bản). Đổi spec thì chạy `/sync-api`.
- Mọi chuyển đổi DTO ↔ entity nằm ở `lib/shared/data/api_mappers.dart`.
- Realtime đấu giá: WebSocket JSON thuần (không phải STOMP) tại `WS_BASE_URL`: `/ws/sessions/{id}` cho phòng đấu giá, `/ws/notifications` cho thông báo; message là `AuctionEventDto`
  (`LOT_OPENED`, `BID_PLACED`, `LOT_CLOSED`, `SESSION_PAUSED`, `SESSION_RESUMED`, `SESSION_ENDED`). Khi vào phòng / kết nối lại, app gọi `GET /sessions/{id}/state`.
- Mã lỗi nghiệp vụ trong body `{code, message}`: xem `ErrorCodes` trong `lib/core/error/app_exception.dart`.

## Deploy

1. Sửa project id trong `apps/frontend/.firebaserc`.
2. Thêm secret `FIREBASE_SERVICE_ACCOUNT` vào GitHub repo.
3. Sửa `env/prod.json` trỏ tới API thật.
4. Web quản trị build riêng (CI có build thử): `flutter build web -t lib/main_admin.dart -o build/web_admin`. Muốn deploy cần thêm một site Firebase Hosting thứ hai (chưa cấu hình).
