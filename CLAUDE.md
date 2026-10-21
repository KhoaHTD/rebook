# ReBook — monorepo

Chợ sách cũ: bán giá cố định + đấu giá.

| Thư mục | Nội dung |
|---|---|
| `apps/frontend/` | Flutter app (web + Android + iOS). Luật và quy ước: [apps/frontend/CLAUDE.md](apps/frontend/CLAUDE.md) |
| `apps/backend/` | REST API + WebSocket (chưa dựng) |
| `docs/` | SRS, use case, workflow, context diagram |

- Làm việc với frontend: đọc `apps/frontend/CLAUDE.md` trước, chạy lệnh Flutter/Dart **trong `apps/frontend`**.
- Hợp đồng API giữa frontend và backend là `apps/frontend/openapi/openapi.yaml` (hiện là placeholder).
  Backend cập nhật spec thì frontend chạy `/sync-api`.
- Workflow CI nằm ở `.github/workflows/` (gốc repo), mỗi app một file `<app>-*.yml`, lọc theo `paths`.
- Hooks trong `.claude/settings.json` chỉ tác động lên file trong `apps/frontend/`.
