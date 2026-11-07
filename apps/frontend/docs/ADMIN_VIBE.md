# Vibe của web / app quản trị (Admin & Staff): bối cảnh cho Claude

Đây là **bối cảnh và gu thẩm mỹ**, không phải luật. Người làm Admin / Staff được **sáng tạo bố cục thoải mái**:
sắp xếp màn, kiểu danh sách, biểu đồ, cách trình bày dữ liệu, cách đi giữa các bước đều do bạn quyết.
Điều cần giữ là *cảm giác chung* bên dưới, để cả sản phẩm trông cùng một nhà, và những thứ ở mục "Giữ để không vỡ".

## Sản phẩm

ReBook: chợ sách cũ, bán giá cố định và đấu giá. Một app Flutter chạy **web + Android + iOS**.
Người mua dùng app kiểu *Liquid Glass* (kính mờ, bìa sách loang màu). Admin / Staff dùng **giao diện quản trị riêng**
(công cụ làm việc cho người vận hành): khi đăng nhập bằng tài khoản Admin / Staff, app tự chuyển sang khung quản trị.

## Cảm giác chung hiện tại (đã duyệt 2026-11-07)

- **Sáng, mềm, gọn.** Nền xám xanh rất nhạt, sidebar là thẻ trắng nổi bo góc, thẻ nội dung bo 20 và có bóng nhẹ, nhiều khoảng thở. Giống một dashboard làm việc nghiêm túc, không phải trang giới thiệu.
- **Màu nhấn xanh dương** (`AdminPalette.accent`, nền chọn `accentSoft`) cho nút chính, mục đang chọn, đường biểu đồ. Màu khác chỉ để *nói nghĩa*: đỏ cho việc cần xử lý / lỗi, xanh lá cho xong / tăng, cam cho cảnh báo.
- **Chữ hệ thống** (không đóng gói font riêng), tiêu đề trang lớn đậm, mô tả phụ ngay dưới.
- **Dữ liệu là nhân vật chính:** KPI to rõ kèm xu hướng (`AdminKpi`), biểu đồ vẽ tay (`admin_charts.dart`: `TrendChart`, `ColumnChart`, `DonutChart`), nhãn trạng thái ngắn (`StatusPill`), hàng việc cần xử lý đứng trên cùng.
- **Web và app là một sản phẩm:** mọi màn phải dùng được và đẹp ở điện thoại (375px) lẫn desktop (≥1400px). Dưới 900px sidebar thành ngăn kéo.
  Đây là điều hay vỡ nhất, hãy thử ở 375 / 800 / 1400px. Dòng danh sách có cụm nút bên phải dùng `AdaptiveTile` (hẹp thì nút xuống dưới thay vì ép chữ).

Ảnh tham chiếu: các màn có sẵn `admin/dashboard_screen.dart`, `admin/reports_screen.dart`, `admin/listing_review_screen.dart` (danh sách – chi tiết), `staff/staff_consignments_screen.dart`, `admin/config_screen.dart`.

## Đồ nghề có sẵn (dùng cho nhanh và đúng gu, không bắt buộc)

`AppPage` (khung trang, thanh đầu, nút ☰ trên điện thoại), `HeaderAction`, `AdminCard`, `AdminKpi`, `AdminPalette.*` (màu),
`AppSpacing` / `AppRadius`, `StatusPill`, `EmptyState`, `AsyncValueView`, `AdaptiveTile`, `BookPoster`, `PriceText` / `formatVnd` / `formatVndCompact`.
Có thể thêm widget mới vào `shared/widgets/` nếu cần. Muốn cách trình bày khác hẳn thì cứ tự dựng, miễn dùng token màu / chữ của app
(`AdminPalette`, `context.textStyles`) thay vì số màu viết tay, và dùng l10n cho chuỗi.

## Giữ để không vỡ (kiến trúc, không phải thẩm mỹ)

- Đăng ký màn trong **file module của vai mình** (`features/admin/presentation/admin_module.dart` hoặc `features/staff/presentation/staff_module.dart`):
  route, mục sidebar, `ownedPaths`. Không sửa router / shell lõi.
- Feature không import feature khác; chuỗi qua l10n (cả `app_vi` và `app_en`); màu qua token; gọi API qua repository có bản Fake.
  `dart run tool/arch_check.dart` kiểm các điều này.
- Test layout (`test/layout`) mở các màn quản trị ở 375 / 800 / 1400px và chỉ hỏng khi có lỗi tràn / lỗi dựng hình.
