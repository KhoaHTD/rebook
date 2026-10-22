# ReBook — monorepo

Chợ sách cũ: bán giá cố định + đấu giá.

| Thư mục | Nội dung |
|---|---|
| `apps/frontend/` | Flutter app (web + Android + iOS). Luật và quy ước: [apps/frontend/CLAUDE.md](apps/frontend/CLAUDE.md) |
| `apps/backend/` | Spring Boot 3.5 + PostgreSQL: REST API + WebSocket. Cách chạy, tài khoản mẫu: [apps/backend/README.md](apps/backend/README.md) |
| `docs/` | SRS, use case, workflow, context diagram |

- Làm việc với frontend: đọc `apps/frontend/CLAUDE.md` trước, chạy lệnh Flutter/Dart **trong `apps/frontend`**.
- Hợp đồng API giữa frontend và backend là `apps/frontend/openapi/openapi.yaml` (hiện là placeholder).
  Spec thật do backend sinh ra: `apps/backend/openapi.yaml` (xuất từ `/v3/api-docs.yaml`).
  Backend cập nhật spec thì frontend chạy `/sync-api`.
- Chạy lệnh Maven **trong `apps/backend`** (`./mvnw ...`). Schema đổi bằng migration Flyway mới, không sửa file đã chạy.
- Workflow CI nằm ở `.github/workflows/` (gốc repo), mỗi app một file `<app>-*.yml`, lọc theo `paths`.
- Hooks trong `.claude/settings.json` chỉ tác động lên file trong `apps/frontend/`.
