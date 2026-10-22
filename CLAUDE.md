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

## Giai đoạn hiện tại: thiết kế (đọc `PROJECT_STATE.md`, `HANDOFF.md`, `DESIGN_DECISIONS.md`)

- Chỉ làm mockup trong `design-preview/`. KHÔNG code website, không làm API/DB/nghiệp vụ, không sửa file ứng dụng
  để thử giao diện. Chỉ code khi người dùng gửi SRS và yêu cầu triển khai (duyệt mockup không phải là cho phép code).
- Không tự suy diễn SRS. Không reset Git lại; không force-push, xoá branch/tag `backup/*`, viết lại lịch sử remote.
- Sách là trung tâm, người bán là nguồn cung. Phân biệt tác phẩm / ấn bản / tin đăng / phiên đấu giá khi cần.
- Dữ liệu trong mockup là dữ liệu mẫu và phải ghi rõ. Artwork tự tạo ghi rõ là concept, không giả làm bìa thật.
- Cập nhật `PROJECT_STATE.md` + `HANDOFF.md` sau mỗi mốc. `TIẾP TỤC`/`RESUME`: đọc file trạng thái, kiểm tra
  git + file thực tế, làm tiếp. `TẠM DỪNG`/`TẮT MÁY`/`DỪNG PHIÊN`: lưu, cập nhật trạng thái, xác minh file, báo rõ.
- Commit không thêm dòng `Co-Authored-By` hay ghi tên Claude.
