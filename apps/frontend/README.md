# Chợ Sách Cũ — Book Marketplace

Mua bán sách cũ và đấu giá realtime. Flutter cho **web + Android + iOS**, deploy web lên **Firebase Hosting**.

## Bắt đầu

Cần Flutter **3.47.x** (stable). Mọi lệnh dưới đây chạy trong thư mục `apps/frontend`.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run -d chrome --dart-define-from-file=env/dev.json
```

`env/dev.json` bật `USE_MOCK=true`: app chạy hoàn toàn bằng dữ liệu giả, chưa cần backend.
Ở chế độ mock, đăng nhập bằng email bất kỳ và mật khẩu từ 6 ký tự trở lên.

Code sinh tự động (`*.g.dart`, `*.freezed.dart`, l10n) **không commit**. Sau mỗi lần `git pull`, nếu thấy lỗi thiếu file thì chạy lại 2 lệnh codegen ở trên
(hoặc để `dart run build_runner watch` chạy nền).

## Tài liệu

- [CLAUDE.md](CLAUDE.md): luật và quy ước ngắn gọn (Claude Code tự đọc file này).
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): kiến trúc chi tiết, luồng dữ liệu, cách thêm feature.

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

Gợi ý cách prompt: *"Dùng /new-feature cart: giỏ hàng, thêm sách từ trang chi tiết, xem tổng tiền"*.

## Quy trình team

1. Mỗi người làm trên một nhánh, ưu tiên mỗi người một thư mục `lib/features/<x>`.
2. Trước khi tạo PR: `dart analyze --fatal-infos && dart run tool/arch_check.dart && flutter test`.
3. CI chạy lại toàn bộ kiểm tra. PR được deploy preview lên Firebase (link comment vào PR).
4. Merge vào `main` thì tự deploy live.

**Thêm package mới:** thảo luận với team trước, rồi người duyệt tự sửa `tool/allowed_packages.yaml` (Claude bị chặn sửa file này).

## API

- Spec: `openapi/openapi.yaml`. File hiện tại là **placeholder**, cần thay bằng spec thật của backend.
- Realtime đấu giá: WebSocket `WS_BASE_URL/auctions/<id>?token=<jwt>`, mỗi message là một `AuctionDto` JSON.
  Backend dùng STOMP / SignalR / Socket.IO thì chỉ cần sửa `lib/core/realtime/realtime_client.dart`.

## Deploy

1. Sửa project id trong `apps/frontend/.firebaserc`.
2. Thêm secret `FIREBASE_SERVICE_ACCOUNT` vào GitHub repo.
3. Sửa `env/prod.json` trỏ tới API thật.
