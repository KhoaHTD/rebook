---
name: sync-api
description: Sinh lại REST client và DTO từ spec thật của backend (apps/backend/openapi.yaml) sau khi backend cập nhật, rồi sửa các mapper/repository bị ảnh hưởng.
argument-hint: "[đường dẫn hoặc URL file OpenAPI mới — tuỳ chọn]"
disable-model-invocation: true
---

# Đồng bộ API từ OpenAPI

1. Client sinh từ `../backend/openapi.yaml` (`schema_path` trong `swagger_parser.yaml`). Backend đang chạy thì xuất lại:
   `curl -sf http://localhost:8080/v3/api-docs.yaml -o ../backend/openapi.yaml`. Người dùng đưa file/URL khác (`$ARGUMENTS`) thì chép vào đó.
   `openapi/openapi.yaml` là hợp đồng / danh sách việc cho backend, không dùng để sinh client. Không tự bịa endpoint.
2. Ghi lại danh sách file trong `lib/api/generated/` trước khi sinh (để biết file nào bị bỏ).
3. Chạy:
   ```bash
   dart run swagger_parser
   dart run build_runner build
   ```
4. File trong `lib/api/generated/` không còn được sinh ra nữa (endpoint/model đã bị xoá) → báo người dùng,
   không tự xoá hàng loạt.
5. `dart analyze --fatal-infos` → sửa lỗi ở **mapper và repository** trong `features/*/data/` và `shared/data/`.
   Không sửa file trong `lib/api/generated/`. Hạn chế thay đổi entity và UI; nếu bắt buộc thì nói rõ.
6. Chạy `dart run tool/arch_check.dart` và `flutter test`.
7. Tóm tắt: endpoint/model thêm, đổi, xoá; mapper nào đã sửa; chỗ nào cần backend làm rõ.
