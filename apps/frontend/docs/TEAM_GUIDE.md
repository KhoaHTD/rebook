# Hướng dẫn làm việc nhóm — frontend ReBook

Dành cho cả nhóm và Claude của từng người. Luật nhẹ như các team vibe code bình thường: **tin nhau, sửa giao diện
thoải mái, chỉ giữ chặt vài thứ làm sập app**. Có hai máy kiểm tra tự động giúp mọi người khỏi phải canh nhau.

## 1. Luật (7 dòng)

1. **TUYỆT ĐỐI không đưa code `apps/backend` lên nhánh `design/apple-books`.** Nhánh này chỉ chứa frontend; backend ở `main`
   do người khác làm. Dù bất cứ lý do gì (kể cả "sửa nhanh một dòng", merge `main` vào) cũng không. Mục 2 nói máy chặn thế nào.
2. **Không push thẳng `main` hay `design/apple-books`.** Làm trên nhánh riêng, mở PR, chủ repo duyệt.
   Đặt tên nhánh `admin/<việc>` hoặc `staff/<việc>` (hoặc `fix/<việc>`, `feat/<việc>`) cho dễ theo dõi.
3. **Không tự ý đổi file hạ tầng:** `pubspec`, `lib/core/`, `lib/app/` (router, shell, theme gốc), `lib/api/`, `openapi/`,
   `env/`, `tool/`, `.github/`, `.githooks/`, `.claude/`, `android/ios/web`. Cần đổi → nhắn chủ repo (mục 6).
4. **Không thêm package, không đổi stack** (Riverpod, go_router, l10n, Dio...). Cần thì hỏi chủ repo.
5. **Giao diện sửa thoải mái, kể cả phần người mua.** Miễn đúng style: dùng `AppPage` / `Glass` / `AdminCard`,
   không hardcode màu và chữ, chuỗi mới vào `.arb` (cả `app_vi` và `app_en`).
6. **Trước khi mở PR** chạy `dart analyze --fatal-infos`, `dart run tool/arch_check.dart`, `flutter test`. CI chạy lại.
7. **PR kèm ảnh** ở điện thoại (375px / Android) **và** desktop (≥1400px): web và app là một sản phẩm.

Không dùng `--no-verify`, không force-push, không `reset --hard` lên nhánh chung.

## 2. Luật cứng về backend: ba lớp chặn

Luật số 1 có ba lớp, cái nào cũng đủ để ngăn. Hai lớp đầu cần bật một lần ở máy bạn:

| Lớp | Chặn ở đâu | Bật |
|---|---|---|
| **Hook push của git** (`.githooks/pre-push`) | `git push` lên `design/apple-books` mà có file `apps/backend` bị từ chối ngay tại máy. | `git config core.hooksPath .githooks` (một lần sau khi clone) |
| **Hook Claude** (`.claude/settings.json`) | Khi đang ở nhánh `design/apple-books`, Claude không sửa / tạo file trong `apps/backend`, không `git commit` / `git push` mang theo file backend, không dùng `--no-verify`. | Tự bật khi mở Claude trong repo |
| **CI "Backend Guard"** (`backend-guard.yml`) | Push / PR vào `design/apple-books` có file `apps/backend` thì đánh hỏng. Không có nhãn hay cách bỏ qua. | Chủ repo đặt làm check bắt buộc (mục 7) |

Nếu bạn lỡ kéo `main` vào nhánh này rồi thấy bị chặn: đó là chủ đích. Muốn lấy thay đổi frontend của `main` thì
`cherry-pick` từng commit frontend, hoặc hỏi chủ repo.

## 3. Thiết lập máy (một lần)

```bash
git config core.hooksPath .githooks
cd apps/frontend
flutter pub get
dart run build_runner build
```

Chạy thử (dữ liệu giả, không cần backend):

```bash
flutter run -d chrome --dart-define-from-file=env/dev.json                 # web
flutter run -d <id-máy-ảo-android> --dart-define-from-file=env/dev.json   # app Android
```

Tài khoản mẫu (mật khẩu và OTP đều `123456`): `admin@rebook.vn`, `staff@rebook.vn`, `minhanh@rebook.vn` (người mua).
Đăng nhập Staff / Admin trên app thường sẽ tự chuyển sang giao diện quản trị. Không sửa `env/dev.json`.

## 4. Hai điều về giao diện

1. **Web và app là MỘT sản phẩm.** Mỗi màn phải đẹp và dùng được ở cả điện thoại (375px, app Android / iOS) lẫn
   desktop (≥1400px). Một màn chỉ đẹp trên desktop là chưa xong.
2. **Hai phong cách, đừng trộn.** App người mua = Liquid Glass (xem `apps/frontend/CLAUDE.md`).
   Giao diện quản trị (Admin / Staff) = dashboard sáng, phẳng, nút đen, chữ tiêu đề serif; không kính, không gradient,
   không đổ bóng. `arch_check` bắt các lỗi này trong `features/admin|staff`.

## 5. Thêm một màn quản trị mới — 5 bước

Ví dụ: Admin thêm màn "Báo cáo". Mỗi vai có một file module, router và sidebar tự nhận.

1. **Đường dẫn:** thêm hằng vào `AdminRoutes` trong `routes.dart`, trong phần của vai mình.
2. **Chuỗi:** `node tool/l10n_add.mjs chuoi.json --zone adm` (Staff: `--zone stf`). `--zone` không bắt buộc, nhưng nên dùng:
   nó chèn key vào chỗ riêng của vai để hai bạn ít xung đột file `.arb`.
3. **Repository:** thêm vào `domain/` + `data/fake_<x>_repository.dart` (+ `api_`). Luôn có bản Fake chạy khi `USE_MOCK=true`;
   mọi lời gọi API bọc `guardApi(...)`.
4. **Màn hình** `presentation/screens/reports_screen.dart`, dựng bằng `AppPage` (khung mẫu bên dưới).
5. **Đăng ký vào module của vai mình** (`features/admin/presentation/admin_module.dart` hoặc `features/staff/presentation/staff_module.dart`):
   route vào `routes`, một `AdminNavItem` vào `nav`, đường dẫn vào `ownedPaths`. Route có `:tham_số` thì thêm địa chỉ mẫu
   vào `smokePaths`. **Không sửa `admin_router.dart` / `admin_shell.dart`.**

```dart
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(reportsProvider);
    return AppPage(
      title: l10n.admReportsTitle,
      showBack: false,
      onRefresh: () => ref.refresh(reportsProvider.future),
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

**Bộ dựng sẵn — dùng, đừng tự vẽ:** `AppPage` (khung trang), `HeaderAction` (nút thanh đầu), `AdminCard`, `AdminKpi`,
`AdminPalette.*` (màu), `AppSpacing` / `AppRadius`, `StatusPill`, `EmptyState`, `AsyncValueView`, `BookPoster`, `PriceText` / `formatVnd`.
Màn mẫu: `admin/dashboard_screen.dart`, `admin/listing_review_screen.dart`, `staff/staff_consignments_screen.dart`, `admin/config_screen.dart`.

### Responsive (bắt buộc)

- Sidebar quản trị thành ngăn kéo dưới **900px**; màn của bạn còn phải co ở 375px. Dùng `LayoutBuilder`, không đoán theo thiết bị.
- Không đặt bề rộng cố định lớn cho khối nội dung; dùng `Expanded` / `Flexible` / `Wrap`.
- Bảng nhiều cột → trên hẹp bỏ cột phụ; hàng nhiều nút → nút xuống hàng; hai cột → xếp dọc.
- Tên, email, tiêu đề dài trong hàng ngang: `maxLines` + `TextOverflow.ellipsis`. Số tiền: `FittedBox(scaleDown)`.
- Thử ở **375 / 800 / 1400px**, trên cả app Android và web.

## 6. Cần đổi file hạ tầng thì làm sao

1. Ghi rõ **cần gì, vì sao, đã thử cách nào**.
2. Nhắn chủ repo, hoặc mở PR chỉ chứa đúng thay đổi đó để chủ repo duyệt (CODEOWNERS tự gọi họ).
3. Đừng âm thầm copy widget lõi ra feature để chỉnh: sẽ lệch style và bị `arch_check` / review từ chối.

Package mới: không tự thêm, giải thích cho chủ repo (`tool/allowed_packages.yaml` chỉ chủ repo sửa).

## 7. Máy tự kiểm tra

```bash
dart analyze --fatal-infos
dart run tool/arch_check.dart
flutter test
```

- `arch_check`: feature không import feature khác; không hardcode màu / chuỗi; trong `features/admin|staff` cấm
  `Scaffold` / `Card` / `TextStyle(...)` / bóng / gradient / `Theme(...)`, mọi `*_screen.dart` dùng `AppPage`.
  Cần ngoại lệ có lý do: `// arch-ignore: <lý do>`.
- `test/layout/admin_staff_layout_test.dart` tự mở mọi route quản trị ở 375 / 800 / 1400px và hỏng nếu có lỗi tràn / dựng hình.
  Đừng sửa test để "xanh", hãy sửa màn hình. Test không bắt được chữ xấu mà không tràn, nên vẫn cần ảnh trong PR.
- Hook Claude cũng chặn sửa file sinh tự động, chặn package lạ, tự `dart format`, và chạy `analyze` + `arch_check` khi kết thúc lượt.

## 8. Chuỗi (l10n) và dữ liệu giả

- Mọi chuỗi qua `context.l10n.<key>`, thêm vào cả `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`.
  Khi `git rebase` xung đột ở `.arb`: giữ **cả hai** phía, đảm bảo JSON hợp lệ (dấu phẩy).
- Dữ liệu giả ở `shared/data/fake/**`: thêm ở cuối hoặc file mới, đừng sắp xếp lại.
- Không sửa `lib/api/generated/**`, `*.g.dart`, `*.freezed.dart`: sửa nguồn rồi `dart run build_runner build`.
- Giao tiếp backend chỉ qua `openapi/openapi.yaml`. Thiếu endpoint → báo chủ repo.

## 9. Dành cho chủ repo

Thao tác trên GitHub (Settings → Branches) để luật có tác dụng thật:

- **`design/apple-books`:** bắt buộc PR, bắt buộc status check **`Backend Guard`** và `Frontend CI`, chặn force-push, chặn xoá nhánh.
- **`main`:** bắt buộc PR, bắt buộc review của Code Owners, chặn force-push.
- Hook máy (git + Claude) chỉ là lớp đầu, có thể bị tắt cục bộ; **CI và branch protection mới là chốt chặn thật**.
- Muốn họ duyệt chéo hoặc thêm người backend vào CODEOWNERS: sửa `.github/CODEOWNERS`.
