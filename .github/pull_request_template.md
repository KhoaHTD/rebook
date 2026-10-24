## Việc đã làm
<!-- 1–3 câu: màn nào, nghiệp vụ nào (trích mục SRS nếu có). -->

## Ảnh chụp (bắt buộc với thay đổi giao diện)
<!-- App Android (điện thoại) VÀ web desktop (≥1400px) VÀ web mobile (375px). Kéo thả ảnh vào đây. -->
| Android | Web desktop | Web mobile |
|---|---|---|
|  |  |  |

## Checklist trước khi xin duyệt
- [ ] `dart analyze --fatal-infos` sạch
- [ ] `dart run tool/arch_check.dart` sạch
- [ ] `flutter test` sạch
- [ ] Không chạm `apps/backend` (**nhánh design/apple-books cấm tuyệt đối**)
- [ ] Không thêm package, không đổi stack; chuỗi mới qua l10n, không hardcode màu
- [ ] Có Fake repository chạy được khi `USE_MOCK=true` (nếu thêm tính năng)

## Cần chủ repo xem (nếu có)
<!-- Nếu cần đổi file hạ tầng (core, router, pubspec, CI...): mô tả cần gì và vì sao. -->
