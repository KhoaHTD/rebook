## Việc đã làm
<!-- 1–3 câu: màn nào, nghiệp vụ nào (trích mục SRS nếu có). -->

## Vai / nhánh
- [ ] Nhánh đặt tên `admin/<việc>` hoặc `staff/<việc>` (đúng vai của mình)
- [ ] Chỉ sửa trong vùng của mình + file dùng chung (xem `apps/frontend/docs/TEAM_GUIDE.md`)

## Ảnh chụp (bắt buộc với thay đổi giao diện)
<!-- App Android (điện thoại) VÀ web desktop (≥1400px) VÀ web mobile (375px). Kéo thả ảnh vào đây. -->
| Android | Web desktop | Web mobile |
|---|---|---|
|  |  |  |

## Checklist trước khi xin duyệt
- [ ] `dart analyze --fatal-infos` sạch
- [ ] `dart run tool/arch_check.dart` sạch
- [ ] `flutter test` sạch (gồm test layout 2 cỡ màn hình)
- [ ] Màn mới dùng `AppPage` + `AdminCard`/`AdminPalette`, không tự vẽ nền / viền / màu
- [ ] Mọi chuỗi qua l10n (key mới có tiền tố `adm` hoặc `stf`), không đổi key cũ
- [ ] Màn đã có route + mục sidebar ở **module của mình** (`<tên>_module.dart`), không sửa router / shell
- [ ] Có Fake repository chạy được khi `USE_MOCK=true`
- [ ] Không chạm `apps/backend`

## Cần chủ repo xem (nếu có)
<!-- Nếu cần sửa vùng khoá (theme, widget lõi, shell, pubspec...): mô tả cần gì và vì sao. Chủ repo sẽ gắn nhãn `core-change` nếu đồng ý. -->
