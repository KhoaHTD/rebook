# ReBook — monorepo

Chợ sách cũ: bán giá cố định + đấu giá.

| Thư mục | Nội dung |
|---|---|
| `apps/frontend/` | Flutter app (web + Android + iOS). Luật và quy ước: [apps/frontend/CLAUDE.md](apps/frontend/CLAUDE.md) |
| `apps/backend/` | REST API + WebSocket (chưa dựng) |
| `docs/` | SRS, use case, workflow, context diagram |

- Làm việc với frontend: đọc `apps/frontend/CLAUDE.md` trước, chạy lệnh Flutter/Dart **trong `apps/frontend`**.
- Hợp đồng API giữa frontend và backend là `apps/frontend/openapi/openapi.yaml` (viết từ SRS, bao phủ toàn bộ nghiệp vụ).
  Backend cập nhật spec thì frontend chạy `/sync-api`.
- Workflow CI nằm ở `.github/workflows/` (gốc repo), mỗi app một file `<app>-*.yml`, lọc theo `paths`.
- Hooks trong `.claude/settings.json` chủ yếu tác động lên file trong `apps/frontend/`; riêng luật "không có code `apps/backend` trên `design/liquid-glass-ui`" áp cho cả repo.

## Giai đoạn hiện tại: frontend ĐÃ XONG theo SRS (GĐ0–7) — tiếp theo là thêm thắt theo yêu cầu người dùng (đọc `HANDOFF.md`, `apps/frontend/docs/PROGRESS.md`)

- Người dùng đã duyệt kế hoạch 8 giai đoạn (2026-10-22); cả 8 giai đoạn đã xong. Giao diện đã đổi sang **Liquid Glass + chữ SF** (người dùng duyệt bản vẽ `design-preview/png/lg-*.png`). Thay đổi mới: hỏi người dùng trước, giữ đúng style.
- Lấy logic (OpenAPI, entity, FakeStore, provider, test) từ tag `backup/srs-frontend-2026-10-22`; **giao diện làm mới** (nay là style Liquid Glass, xem `apps/frontend/CLAUDE.md`).
- Mỗi giai đoạn: `dart analyze --fatal-infos` + `dart run tool/arch_check.dart` + `flutter test` sạch → commit local → cập nhật PROGRESS.md.
- Không push, không force-push, không xoá branch/tag `backup/*`, không reset Git. Không tự suy diễn ngoài SRS; chỗ SRS thiếu → ghi vào `apps/frontend/docs/DECISIONS.md`.
- Commit không thêm dòng `Co-Authored-By` hay ghi tên Claude.

## Làm việc nhóm (luật nhẹ, tin nhau; chi tiết ở `apps/frontend/docs/TEAM_GUIDE.md`)

- **LUẬT CỨNG, KHÔNG NGOẠI LỆ: không đưa code `apps/backend` lên nhánh `design/liquid-glass-ui` hay bất kỳ nhánh con nào của nó** (các nhánh này chỉ chứa frontend; backend ở `main`).
  Không sửa / commit / push file backend trên các nhánh này, không merge `main` vào chúng. Hook push (`.githooks/pre-push`, bật bằng
  `git config core.hooksPath .githooks`), hook Claude và CI "Backend Guard" cùng chặn. Bị chặn → dừng, báo người dùng; không lách.
- Đọc `apps/frontend/docs/TEAM_GUIDE.md` nếu bạn là Claude của một thành viên nhóm.
- Không push thẳng `main` / `design/liquid-glass-ui`: nhánh riêng + PR. Không tự đổi file hạ tầng (`pubspec`, `core/`, `app/`, `api/`, `openapi/`, `env/`, `tool/`, `.github/`, `.claude/`, `android/ios/web`) và không thêm package: hỏi chủ repo.
- Bố cục màn Admin / Staff do người làm tự sáng tạo, chỉ cần hợp gu chung (đọc `apps/frontend/docs/ADMIN_VIBE.md` để hiểu bối cảnh). Giao diện phần người mua sửa thoải mái, miễn đúng style Liquid Glass; mọi thứ qua `arch_check` + test.
- Web và app là một sản phẩm: mọi thay đổi giao diện phải đúng ở điện thoại (375px / app Android) **và** desktop (≥ 1400px).
