# Vibe của web / app quản trị (Admin & Staff) — bối cảnh cho Claude

Đây là **bối cảnh và gu thẩm mỹ**, không phải luật. Người làm Admin / Staff được **sáng tạo bố cục thoải mái**:
sắp xếp màn, kiểu danh sách, biểu đồ, cách trình bày dữ liệu, cách đi giữa các bước đều do bạn quyết.
Điều duy nhất cần giữ là *cảm giác chung* bên dưới, để cả sản phẩm trông cùng một nhà, và những thứ ở mục "Giữ để không vỡ".

## Sản phẩm

ReBook: chợ sách cũ, bán giá cố định và đấu giá. Một app Flutter chạy **web + Android + iOS**.
Người mua dùng app kiểu *Liquid Glass* (kính mờ, bìa sách loang màu). Admin / Staff dùng **giao diện quản trị riêng**
(công cụ làm việc cho người vận hành): khi đăng nhập bằng tài khoản Admin / Staff, app tự chuyển sang khung quản trị.

## Cảm giác chung (gu mặc định, hãy bám theo nhưng đừng cứng nhắc)

- **Sáng, phẳng, gọn.** Nền xám rất nhạt, thẻ trắng viền mảnh, chữ đen, nhiều khoảng thở. Giống một dashboard làm việc nghiêm túc, không phải trang giới thiệu.
- **Nút chính màu đen**, nút phụ viền mảnh. Màu chỉ dùng để *nói nghĩa*: đỏ cho việc cần xử lý / lỗi, xanh lá cho xong, vàng cho cảnh báo. Không dùng màu để trang trí.
- **Tiêu đề trang dùng chữ serif mềm (Newsreader)**, nội dung dùng Inter. Đó là chữ ký chung với app người mua.
- **Dữ liệu là nhân vật chính:** số liệu to rõ, nhãn trạng thái ngắn (`StatusPill`), hàng việc cần xử lý đứng trên cùng.
- **Ít trang trí:** hạn chế bóng đổ, gradient, kính mờ trong khu quản trị (kính là đặc trưng của app người mua). Có lý do hay thì cứ dùng, miễn nhìn vẫn cùng một gu.
- **Web và app là một sản phẩm:** mọi màn phải dùng được và đẹp ở điện thoại (375px) lẫn desktop (≥1400px). Dưới 900px sidebar thành ngăn kéo.
  Đây là điều hay vỡ nhất, hãy thử ở 375 / 800 / 1400px.

Ảnh tham chiếu: `design-preview/png/` (bản duyệt) và các màn có sẵn: `admin/dashboard_screen.dart`,
`admin/listing_review_screen.dart` (danh sách – chi tiết), `staff/staff_consignments_screen.dart`, `admin/config_screen.dart`.

## Đồ nghề có sẵn (dùng cho nhanh và đúng gu, không bắt buộc)

`AppPage` (khung trang, thanh đầu, nút ☰ trên điện thoại), `HeaderAction`, `AdminCard`, `AdminKpi`, `AdminPalette.*` (màu),
`AppSpacing` / `AppRadius`, `StatusPill`, `EmptyState`, `AsyncValueView`, `BookPoster`, `PriceText` / `formatVnd`.
Có thể thêm widget mới vào `shared/widgets/` nếu cần. Muốn cách trình bày khác hẳn thì cứ tự dựng, miễn dùng token màu / chữ của app
(`AdminPalette`, `context.textStyles`) thay vì số màu viết tay, và dùng l10n cho chuỗi.

## Giữ để không vỡ (kiến trúc, không phải thẩm mỹ)

- Đăng ký màn trong **file module của vai mình** (`features/admin/presentation/admin_module.dart` hoặc `features/staff/presentation/staff_module.dart`):
  route, mục sidebar, `ownedPaths`. Không sửa router / shell lõi.
- Feature không import feature khác; chuỗi qua l10n (cả `app_vi` và `app_en`); màu qua token; gọi API qua repository có bản Fake.
  `dart run tool/arch_check.dart` kiểm các điều này.
- Test layout (`test/layout`) mở các màn quản trị ở 375 / 800 / 1400px và chỉ hỏng khi có lỗi tràn / lỗi dựng hình.
- Không có code `apps/backend` trên nhánh này hay nhánh con của nó.
