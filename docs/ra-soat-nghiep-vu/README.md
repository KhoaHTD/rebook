# Rà soát nghiệp vụ backend (2026-11-05 đến 2026-11-06)

Thư mục này gom các tài liệu của đợt rà soát luật nghiệp vụ (tiền, mua bán, đấu giá, ký gửi), tách khỏi tài liệu gốc của nhóm ở `docs/` (SRS `.docx`, sơ đồ `.drawio`, `DEMO.md`, `DEMO_ONLINE.md`, `TEST_GUIDE.md`).

| Cần gì | Đọc file |
|---|---|
| **Hệ thống chạy thế nào, luật cũ và hiện tại** (đọc đầu tiên) | [NGHIEP_VU.md](NGHIEP_VU.md): luồng từng bước của ví, sách và tin đăng (ISBN, mốc 1970), mua bán và giao hàng, ký gửi, đấu giá và giao lô; bảng luật cũ / hiện tại; mọi thời hạn và cấu hình |
| Đã thay đổi gì so với code cũ (chi tiết kỹ thuật) | [THAY_DOI_SO_VOI_CODE_CU.md](THAY_DOI_SO_VOI_CODE_CU.md): trước / sau, luồng tiền đấu giá, luật bổ sung SRS (BR-x.y), thiết kế log, nhật ký từng đợt sửa |
| Đánh giá và việc còn phải sửa | [DANH_GIA_BA_TESTER.md](DANH_GIA_BA_TESTER.md): đánh giá P0 → P3, audit backend (BE-xx), audit frontend (FE-xx), việc để sau |
| Luồng test và kịch bản demo | [TEST_PLAN_TOAN_DIEN.md](TEST_PLAN_TOAN_DIEN.md): kế hoạch test happy case đến hell case, câu chuyện S1–S8, kịch bản demo V2 |
| Thiết kế gửi mail (P0 mục 2, 3, 4), đã code (V17), test 199/200 | [THIET_KE_GUI_MAIL.md](THIET_KE_GUI_MAIL.md): outbox, OTP bằng email, luật "mail không tới thì không phạt", luật ví cho shop mới |
| Dữ liệu mẫu để test | [`apps/backend/testdata/e2e_personas.sql`](../../apps/backend/testdata/e2e_personas.sql) (để cạnh backend vì script test chạy trong `apps/backend`) |
| Script chạy test | [`e2e_flows.sh`](../../apps/backend/testdata/e2e_flows.sh) (133 ca), [`e2e_restart.sh`](../../apps/backend/testdata/e2e_restart.sh) (khởi động lại backend giữa phiên) |

Chú thích trong code backend trỏ về các file ở đây theo dạng `docs/ra-soat-nghiep-vu/<file>.md phần X`. Riêng 4 migration đã chạy (V9, V10, V13, V15) vẫn ghi tên file cũ (`AUCTION_MONEY_FLOW.md`, `SRS_BO_SUNG_NGHIEP_VU.md`...) vì sửa migration sẽ làm lệch checksum; bảng đầu mỗi file cho biết tên cũ nằm ở phần nào.
