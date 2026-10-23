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
- Hooks trong `.claude/settings.json` chỉ tác động lên file trong `apps/frontend/`.

## Giai đoạn hiện tại: frontend ĐÃ XONG theo SRS (GĐ0–7) — tiếp theo là thêm thắt theo yêu cầu người dùng (đọc `HANDOFF.md`, `apps/frontend/docs/PROGRESS.md`)

- Người dùng đã duyệt kế hoạch 8 giai đoạn (2026-10-22); cả 8 giai đoạn đã xong. Giao diện đã đổi sang **Liquid Glass + chữ SF** (người dùng duyệt bản vẽ `design-preview/png/lg-*.png`). Thay đổi mới: hỏi người dùng trước, giữ đúng style.
- Lấy logic (OpenAPI, entity, FakeStore, provider, test) từ tag `backup/srs-frontend-2026-10-22`; **giao diện làm mới** (nay là style Liquid Glass, xem `apps/frontend/CLAUDE.md`).
- Mỗi giai đoạn: `dart analyze --fatal-infos` + `dart run tool/arch_check.dart` + `flutter test` sạch → commit local → cập nhật PROGRESS.md.
- Không push, không force-push, không xoá branch/tag `backup/*`, không reset Git. Không tự suy diễn ngoài SRS; chỗ SRS thiếu → ghi vào `apps/frontend/docs/DECISIONS.md`.
- Commit không thêm dòng `Co-Authored-By` hay ghi tên Claude.
