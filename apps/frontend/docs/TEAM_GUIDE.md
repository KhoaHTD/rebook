# Hướng dẫn làm việc nhóm — web / app quản trị (Admin & Staff)

Tài liệu này dành cho hai người nhận phần **Admin** và **Staff**, và cho Claude của họ.
Đọc hết trước khi code. Mục tiêu: hai bạn làm song song, không giẫm chân nhau, không phá kiến trúc,
và giao diện vẫn đúng vibe đã duyệt.

> Chủ repo (owner) giữ: giao diện chủ đạo, khung ứng dụng, cấu hình, feature của người mua, backend.
> Hai bạn giữ: một feature mỗi người (xem bảng bên dưới).

## 1. Hai điều không thương lượng

1. **Web và app là MỘT sản phẩm.** Mỗi màn bạn làm phải đẹp và dùng được ở cả điện thoại (app Android / iOS,
   web 375px) lẫn desktop (web ≥ 1400px). Một màn chỉ đẹp trên desktop là chưa xong.
2. **Giao diện quản trị = dashboard sáng, phẳng, nút đen.** Nền xám nhạt, thẻ trắng viền mảnh, chữ đen,
   nút chính đen, huy hiệu đỏ cho việc cần xử lý, chữ tiêu đề serif (Newsreader). Không kính, không gradient,
   không đổ bóng, không màu xanh dương làm màu nhấn. App của người mua mới là Liquid Glass.

## 2. Ai làm gì: vùng làm việc

Nguồn sự thật là [`tool/zones.txt`](../tool/zones.txt) (hook, CI và tài liệu này cùng đọc file đó).

| Vùng | Gồm | Quy tắc |
|---|---|---|
| **Admin** | `lib/features/admin/**`, `test/features/admin/**` | Chỉ người làm Admin sửa |
| **Staff** | `lib/features/staff/**`, `test/features/staff/**` | Chỉ người làm Staff sửa |
| **Dùng chung** | `lib/app/router/routes.dart` (hằng số đường dẫn), `lib/app/l10n/arb/*.arb`, `lib/shared/domain/**`, `lib/shared/data/**`, `test/shared/**` | Ai cũng sửa được nhưng chỉ **THÊM**; không đổi / xoá cái đã có |
| **Thêm file mới được** | `lib/shared/widgets/` | Được thêm widget mới; widget đã có thì khoá |
| **Khoá** | Mọi thứ còn lại: theme, `shared/widgets` cũ, `lib/app/**` (shell, sidebar, router), `lib/core/**`, feature của người mua, `pubspec`, `tool/`, `.github/`, `.claude/`, `apps/backend` | Không sửa. Cần thay đổi → mục 9 |

Màn dùng chung hai vai (ký gửi, kho, lịch hẹn, giao lô đấu giá) thuộc **Staff**. Admin chỉ được liên kết tới
chúng bằng `AdminRoutes.<tên>`, không import feature Staff (luật cross-feature trong `arch_check`).

## 3. Thiết lập máy (làm một lần)

```bash
cd apps/frontend
flutter pub get
dart run build_runner build
dart run tool/set_role.dart admin      # hoặc: staff   (ghi ~/.rebook-role)
```

`set_role` quyết định hook Claude cho bạn sửa vùng nào. Chưa đặt vai thì hook chặn mọi sửa đổi.
Chạy thử (dữ liệu giả, không cần backend):

```bash
flutter run -d chrome --dart-define-from-file=env/dev.json            # web
flutter run -d <id-máy-ảo-android> --dart-define-from-file=env/dev.json   # app Android
```

Tài khoản mẫu (mật khẩu và OTP đều `123456`): `admin@rebook.vn`, `staff@rebook.vn`, `minhanh@rebook.vn` (người mua).
Đăng nhập Staff / Admin trên app thường sẽ tự chuyển sang giao diện quản trị.
Không sửa `env/dev.json`; không nối backend thật khi chưa được chủ repo bảo.

## 4. Git

- Nhánh tích hợp hiện tại: `design/apple-books` (chủ repo sẽ báo khi đổi). Tạo nhánh từ đó.
- **Tên nhánh bắt buộc theo vai:** `admin/<việc>` hoặc `staff/<việc>` (vd. `admin/users-filter`, `staff/inspection-form`).
  CI dựa vào tiền tố này để kiểm tra bạn có sửa lạc sang vùng người khác không.
- Commit nhỏ, thông điệp rõ (`feat(admin): ...`, `fix(staff): ...`). Không thêm dòng `Co-Authored-By`.
- Một PR = một việc. Rebase từ nhánh tích hợp thường xuyên (mỗi ngày). Không force-push nhánh người khác.
- **Không** dùng `--no-verify`, không `reset --hard` lên nhánh chung. Không push thẳng nhánh tích hợp / `main`.
- Hai bạn duyệt chéo PR cho nhau; thay đổi vùng khoá cần chủ repo (mục 9).

## 5. Thêm một màn mới — 6 bước

Ví dụ: Admin thêm màn "Báo cáo".

1. **Đường dẫn:** thêm hằng vào `AdminRoutes` trong `routes.dart`, trong phần của vai mình (đừng chen vào phần người kia):
   `static const reports = '/reports';`
2. **Chuỗi:** `node tool/l10n_add.mjs chuoi.json --zone adm` (Staff: `--zone stf`). Key bắt buộc bắt đầu `adm` / `stf`.
   Tool chèn key vào đúng chỗ của vai để hai bạn không xung đột file `.arb`. Không sửa tay key cũ.
3. **Repository:** thêm vào `domain/<x>_repository.dart` + `fake_<x>_repository.dart` (+ `api_<x>_repository.dart`).
   Luôn có bản Fake chạy được khi `USE_MOCK=true`. Mọi lời gọi API bọc `guardApi(...)`.
4. **Màn hình** `presentation/screens/reports_screen.dart` (khung mẫu ở mục 6).
5. **Đăng ký vào module của mình** (`presentation/admin_module.dart` hoặc `staff_module.dart`): thêm
   `adminPage(AdminRoutes.reports, (_) => const ReportsScreen())` vào `routes`, một `AdminNavItem` vào `nav`,
   và đường dẫn vào `ownedPaths`. Router và sidebar tự nhận, **không sửa `admin_router.dart` / `admin_shell.dart`**.
   Route có `:tham_số` phải thêm địa chỉ mẫu vào `smokePaths` (xem mục 7).
6. **Test:** test repository trong `test/features/<vai>/`. Test layout (mục 7) tự quét màn mới.

## 6. Khung màn hình chuẩn

```dart
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(reportsProvider);
    return AppPage(
      title: l10n.admReportsTitle,
      showBack: false,                       // màn gốc trong sidebar
      onRefresh: () => ref.refresh(reportsProvider.future),
      actions: [HeaderAction(icon: Icons.add_rounded, label: l10n.admNew, onPressed: () {})],
      children: [
        AsyncValueView(
          value: data,
          onRetry: () => ref.invalidate(reportsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(icon: Icons.inbox_outlined, title: l10n.nothingToDo)
              : AdminCard(child: /* nội dung */),
        ),
      ],
    );
  }
}
```

**Bộ dựng sẵn — dùng, đừng tự vẽ:**

| Cần | Dùng | Ở đâu |
|---|---|---|
| Khung trang (thanh đầu, nút ☰ trên điện thoại, nền xám) | `AppPage` | `shared/widgets/ui.dart` |
| Nút ở thanh đầu (đen, tròn trên điện thoại) | `HeaderAction` | `ui.dart` |
| Thẻ trắng viền mảnh | `AdminCard` | `shared/widgets/admin_kit.dart` |
| Ô số liệu | `AdminKpi` | `admin_kit.dart` |
| Màu | `AdminPalette.*` (`ink`, `muted`, `faint`, `line`, `ok/warn/bad/info` + `…Soft`) | `app/theme/app_tokens.dart` |
| Cỡ chữ | `context.textStyles.<cỡ>?.copyWith(...)` (không `TextStyle(...)`) | |
| Khoảng cách / bo góc | `AppSpacing.*`, `AppRadius.*` | |
| Nhãn trạng thái | `StatusPill`, `<enum>.label(l10n)` / `.tone` | `status_labels.dart` |
| Trạng thái rỗng / lỗi / tải | `EmptyState`, `AsyncValueView`, `errorMessage(...)` | |
| Hộp chọn / lý do | `showCancelSheet`, các `sheets.dart` | |
| Bìa sách | `BookPoster` (đừng `Image.network` thẳng) | `book_poster.dart` |
| Giá tiền | `PriceText` / `formatVnd` | |

**Màn mẫu để bắt chước** (đã đạt chuẩn cả điện thoại và desktop):
`admin/dashboard_screen.dart` (số liệu + việc cần xử lý), `admin/listing_review_screen.dart` (danh sách – chi tiết),
`admin/monitor_screen.dart` (realtime), `staff/staff_consignments_screen.dart` (lọc + hành động trên dòng),
`admin/config_screen.dart` (biểu mẫu).

### Quy tắc bố cục responsive (bắt buộc)

- Điểm gãy của khung quản trị là **900px**: dưới đó sidebar thành ngăn kéo, `AppPage` có nút ☰. Màn của bạn
  còn phải tự co ở 375px (điện thoại). Dùng `LayoutBuilder` theo bề rộng thật của vùng nội dung,
  không đoán theo thiết bị.
- **Không** đặt bề rộng cố định lớn (`width: 360`) cho khối nội dung; dùng `Expanded` / `Flexible` / `Wrap`.
- Bảng nhiều cột → trên hẹp bỏ bớt cột phụ, dồn thông tin xuống dòng dưới (xem `_ListingTable`).
- Hàng có nhiều nút → trên hẹp cho nút xuống hàng riêng (xem `ConsignmentRow`).
- Hai cột (danh sách + chi tiết) → trên hẹp xếp dọc (xem `listing_review_screen.dart`).
- Số tiền / mã dài: `FittedBox(scaleDown)` hoặc `maxLines` + `ellipsis`, đừng để gãy giữa chữ số.
- Tên người, tên sách, email: luôn `maxLines` + `TextOverflow.ellipsis` nếu nằm trong hàng ngang.
- Thử ở **3 cỡ**: 375 (điện thoại), 800 (tablet), 1400 (desktop), trên cả **app Android và web**.

## 7. Chốt chặn tự động (chạy ở máy bạn và CI)

```bash
dart analyze --fatal-infos
dart run tool/arch_check.dart
flutter test
```

- `arch_check` giữ kiến trúc **và** vibe: feature không import feature khác; không hardcode màu / chuỗi;
  trong `features/admin|staff` cấm `Scaffold`/`AppBar`/`Card`/`ElevatedButton`/`FloatingActionButton`/
  `AlertDialog`/`showDialog`/`TextStyle(...)`/`BoxShadow`/gradient/`Theme(...)`; mọi `*_screen.dart` phải dùng `AppPage`.
  Cần ngoại lệ có lý do: `// arch-ignore: <lý do>` (chủ repo sẽ thấy ở PR).
- `test/layout/admin_staff_layout_test.dart` mở **mọi route** của module Admin và Staff, ở 375 / 800 / 1400px,
  bằng phông thật, và hỏng nếu có lỗi dựng hình, `RenderFlex overflowed`, hoặc mở ngăn kéo lỗi.
  Route có tham số mà thiếu `smokePaths` cũng hỏng. Test **không** bắt được chữ bị bóp xấu mà không tràn,
  nên vẫn phải xem ảnh thật (PR template yêu cầu ảnh ở 3 nơi).
- `tool/locked_check.dart` (CI "Frontend Guard") từ chối PR sửa vùng khoá / vùng của vai kia / đổi key `.arb` cũ.

## 8. Hook của Claude

Mở Claude trong repo là hook tự bật (`.claude/settings.json`): chặn sửa vùng khoá, chặn file sinh tự động,
chặn package lạ, tự `dart format`, và khi kết thúc lượt chạy `dart analyze` + `arch_check`.

Khi Claude báo **BLOCKED (vùng khoá)**: đó là chủ đích. Claude **phải dừng và hỏi bạn**, không được lách
(đổi tên file, sửa bằng shell, copy sang chỗ khác để né). Hãy làm theo mục 9.

## 9. Cần thay đổi vùng khoá thì làm sao

Ví dụ: cần thêm một biến thể `AdminCard`, đổi cột sidebar, thêm field vào theme, đổi pubspec.

1. Dừng. Ghi rõ **cần gì, vì sao, đã thử cách nào trong vùng của mình**.
2. Nhắn chủ repo (hoặc mở PR nháp chỉ chứa thay đổi đó). Chủ repo sửa, hoặc đồng ý rồi gắn nhãn **`core-change`**
   để CI cho qua.
3. Tuyệt đối không âm thầm copy widget lõi ra feature của mình rồi chỉnh — sẽ lệch vibe và bị `arch_check` / review từ chối.

Package mới: không tự thêm. Giải thích cho chủ repo (`tool/allowed_packages.yaml` chỉ chủ repo sửa).

## 10. Chuỗi (l10n) và dữ liệu giả

- Mọi chuỗi hiển thị qua `context.l10n.<key>`. Key mới: `--zone adm|stf` (mục 5). Khi `git rebase` bị xung đột
  ở `.arb`: giữ **cả hai** phía, đảm bảo JSON hợp lệ (dấu phẩy), rồi `flutter gen-l10n`.
- Dữ liệu giả nằm ở `shared/data/fake/**` (dùng chung → chỉ thêm). Cần thêm dữ liệu / hàm: thêm ở **cuối**
  hoặc trong file mới, đừng sắp xếp lại hay đổi cái cũ.
- Không sửa `lib/api/generated/**`, `*.g.dart`, `*.freezed.dart`: sửa nguồn rồi chạy `dart run build_runner build`.
- Giao tiếp backend: chỉ qua `openapi/openapi.yaml` (do chủ repo giữ). Thiếu endpoint → báo chủ repo.

## 11. Dành cho chủ repo (owner)

- Bật **branch protection** cho nhánh tích hợp và `main` (GitHub → Settings → Branches): bắt buộc PR,
  bắt buộc status check `Frontend CI` và `Frontend Guard`, bắt buộc review của Code Owners, chặn force-push.
  (Các file `.github/CODEOWNERS` và workflow đã có sẵn; bật chế độ bắt buộc là thao tác trên GitHub.)
- Thêm nhãn `core-change` trong repo; chỉ bạn gắn nhãn này. Sửa `tool/zones.txt` để đổi ranh giới.
- Vai `owner`: `dart run tool/set_role.dart owner` (đã đặt trên máy của bạn).
- Khi có người thứ ba / đổi người phụ trách: thêm dòng `role <tên> <đường dẫn>` trong `zones.txt`.
- Hook là lớp đầu, dễ bị lách bằng cách tắt hook cục bộ — **CI mới là chốt chặn thật**, nên hãy bật branch protection.

## 12. Hỏi nhanh

- *Hook chặn tôi sửa file X nhưng đó là bug thật ở vùng khoá?* → mục 9.
- *Cần widget dùng chung mới?* → thêm **file mới** trong `lib/shared/widgets/` (được phép), dùng `AdminPalette`/`AppSpacing`,
  rồi mở PR; chủ repo duyệt vì thư mục này có Code Owner.
- *Màn của tôi cần dữ liệu của feature kia?* → đưa entity vào `shared/domain`, repository riêng cho feature của bạn;
  không import feature kia.
- *Chạy thế nào để xem giống bản demo?* → `flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/dev.json`
  (web quản trị riêng) hoặc app thường rồi đăng nhập `admin@rebook.vn` / `staff@rebook.vn`.
