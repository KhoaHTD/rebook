# ReBook — monorepo

Chợ sách cũ: bán giá cố định + đấu giá.

| Thư mục | Nội dung |
|---|---|
| `apps/frontend/` | Flutter app (web + Android + iOS). Luật và quy ước: [apps/frontend/CLAUDE.md](apps/frontend/CLAUDE.md) |
| `apps/backend/` | Spring Boot 3.5 + PostgreSQL: REST API + WebSocket. Cách chạy, tài khoản mẫu: [apps/backend/README.md](apps/backend/README.md) |
| `docs/` | SRS, use case, workflow, context diagram |

- Làm việc với frontend: đọc `apps/frontend/CLAUDE.md` trước, chạy lệnh Flutter/Dart **trong `apps/frontend`**.
- Hợp đồng API giữa frontend và backend là `apps/frontend/openapi/openapi.yaml` (viết từ SRS, bao phủ toàn bộ nghiệp vụ).
  Spec do backend sinh ra nằm ở `apps/backend/openapi.yaml` (xuất từ `/v3/api-docs.yaml`); hai bản có thể lệch nhau —
  backend đổi API thì xuất lại, đối chiếu với bản của frontend rồi chạy `/sync-api`.
- Chạy lệnh Maven **trong `apps/backend`** (`./mvnw ...`). Schema đổi bằng migration Flyway mới, không sửa file đã chạy.
- Workflow CI nằm ở `.github/workflows/` (gốc repo), mỗi app một file `<app>-*.yml`, lọc theo `paths`.
- Hooks trong `.claude/settings.json` chủ yếu tác động lên file trong `apps/frontend/` (chặn package lạ, file sinh tự động, lệnh nguy hiểm).

## Giai đoạn hiện tại: frontend ĐÃ XONG theo SRS (GĐ0–7) — tiếp theo là thêm thắt theo yêu cầu người dùng (đọc `apps/frontend/docs/PROGRESS.md`)

- Người dùng đã duyệt kế hoạch 8 giai đoạn (2026-10-22); cả 8 giai đoạn đã xong. Giao diện đã đổi sang **Liquid Glass + chữ SF** (người dùng duyệt bản vẽ `apps/frontend/docs/design/lg-*.png`). Thay đổi mới: hỏi người dùng trước, giữ đúng style.
- Lấy logic (OpenAPI, entity, FakeStore, provider, test) từ tag `backup/srs-frontend-2026-10-22`; **giao diện làm mới** (nay là style Liquid Glass, xem `apps/frontend/CLAUDE.md`).
- Mỗi giai đoạn: `dart analyze --fatal-infos` + `dart run tool/arch_check.dart` + `flutter test` sạch → commit local → cập nhật PROGRESS.md.
- Không push, không force-push, không xoá branch/tag `backup/*`, không reset Git. Không tự suy diễn ngoài SRS; chỗ SRS thiếu → ghi vào `apps/frontend/docs/DECISIONS.md`.
- Commit không thêm dòng `Co-Authored-By` hay ghi tên Claude.

## Ghép frontend với backend: giao diện nhiều hơn SRS thì backend làm theo giao diện

- Frontend đã làm nhiều thứ ngoài SRS. Phần dư đó nằm trong `apps/frontend/docs/BACKEND_HANDOFF.md` (mô tả từng mục, endpoint, field, luật nghiệp vụ, bảng DB)
  và được đánh dấu `x-origin: frontend` / `x-frontend-change` / `x-frontend-added` trong `apps/frontend/openapi/openapi.yaml`.
- **Phiên làm backend: trước khi code, đọc `BACKEND_HANDOFF.md`, rồi chạy trong `apps/frontend`: `dart run tool/api_gap.dart`** (so spec frontend với `apps/backend/openapi.yaml`,
  in endpoint / field / enum còn thiếu hoặc lệch, mã thoát 1 nếu còn). Làm xong từng mục thì chạy lại và cập nhật cột Tình trạng ở mục D của sổ bàn giao.
- Spec của frontend là hợp đồng cho phần giao diện cần. Backend thấy không hợp lý thì **sửa spec (PR / báo chủ repo) rồi mới làm khác**, không lặng lẽ làm lệch; frontend sẽ chạy `/sync-api`.
- Phiên làm frontend: mỗi lần thêm endpoint / field / hành vi ngoài SRS phải đánh dấu trong `openapi.yaml` và thêm một mục vào `BACKEND_HANDOFF.md` (cùng commit).
- Client API của frontend (`lib/api/generated`) sinh từ **spec thật của backend** (`apps/backend/openapi.yaml`, xuất từ `/v3/api-docs.yaml`);
  `apps/frontend/openapi/openapi.yaml` là hợp đồng / danh sách việc cho backend. Backend đổi API → xuất lại spec, chạy `/sync-api`, sửa mapper.

## Làm việc nhóm (luật nhẹ, tin nhau; chi tiết ở `apps/frontend/docs/TEAM_GUIDE.md`)

- Nhánh `interface` đã merge vào `main` (2026-11-04); luật "không đưa backend lên `interface`" và ba lớp chặn (pre-push, hook Claude, CI "Backend Guard") đã gỡ.
  Làm frontend hay backend đều cắt nhánh từ `main`.
- Đọc `apps/frontend/docs/TEAM_GUIDE.md` nếu bạn là Claude của một thành viên nhóm.
- Không push thẳng `main`: nhánh riêng + PR. Không tự đổi file hạ tầng (`pubspec`, `core/`, `app/`, `api/`, `openapi/`, `env/`, `tool/`, `.github/`, `.claude/`, `android/ios/web`) và không thêm package: hỏi chủ repo.
- Bố cục màn Admin / Staff do người làm tự sáng tạo, chỉ cần hợp gu chung (đọc `apps/frontend/docs/ADMIN_VIBE.md` để hiểu bối cảnh). Giao diện phần người mua sửa thoải mái, miễn đúng style Liquid Glass; mọi thứ qua `arch_check` + test.
- Web và app là một sản phẩm: mọi thay đổi giao diện phải đúng ở điện thoại (375px / app Android) **và** desktop (≥ 1400px).
