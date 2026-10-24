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
- Hooks trong `.claude/settings.json` chỉ tác động lên file trong `apps/frontend/`.

## Giai đoạn hiện tại: frontend ĐÃ XONG theo SRS (GĐ0–7) — tiếp theo là thêm thắt theo yêu cầu người dùng (đọc `HANDOFF.md`, `apps/frontend/docs/PROGRESS.md`)

- Người dùng đã duyệt kế hoạch 8 giai đoạn (2026-10-22); cả 8 giai đoạn đã xong. Giao diện đã đổi sang **Liquid Glass + chữ SF** (người dùng duyệt bản vẽ `design-preview/png/lg-*.png`). Thay đổi mới: hỏi người dùng trước, giữ đúng style.
- Lấy logic (OpenAPI, entity, FakeStore, provider, test) từ tag `backup/srs-frontend-2026-10-22`; **giao diện làm mới** (nay là style Liquid Glass, xem `apps/frontend/CLAUDE.md`).
- Mỗi giai đoạn: `dart analyze --fatal-infos` + `dart run tool/arch_check.dart` + `flutter test` sạch → commit local → cập nhật PROGRESS.md.
- Không push, không force-push, không xoá branch/tag `backup/*`, không reset Git. Không tự suy diễn ngoài SRS; chỗ SRS thiếu → ghi vào `apps/frontend/docs/DECISIONS.md`.
- Commit không thêm dòng `Co-Authored-By` hay ghi tên Claude.

## Làm việc nhóm (Admin / Staff do hai người khác nhau đảm nhận)

- **Đọc `apps/frontend/docs/TEAM_GUIDE.md` trước khi sửa bất cứ thứ gì** nếu bạn là Claude của một thành viên nhóm.
- Vai của người dùng nằm ở `~/.rebook-role` (`owner` / `admin` / `staff`; đặt bằng `dart run tool/set_role.dart <vai>` trong `apps/frontend`).
  Ranh giới vùng làm việc: `apps/frontend/tool/zones.txt`. Hook (`.claude/settings.json`) chặn sửa ngoài vùng của vai.
- Bị chặn "vùng khoá" → **dừng, báo người dùng cần gì và vì sao**. Không lách (đổi tên file, sửa qua shell, copy widget lõi ra feature).
- Nhánh làm việc đặt tên `admin/<việc>` hoặc `staff/<việc>`. CI "Frontend Guard" kiểm tra.
- Web và app là một sản phẩm: mọi thay đổi giao diện phải đúng ở điện thoại (375px / app Android) **và** desktop (≥ 1400px).
