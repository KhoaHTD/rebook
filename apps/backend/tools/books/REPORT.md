# Dữ liệu sách mẫu — báo cáo để duyệt

Sinh bởi `tools/books/gen.mjs` từ `tools/books/books.xlsx` (66 sách). Chạy lại script sau khi sửa Excel.

## Sửa lỗi chính tả (theo bảng CORRECTIONS trong gen.mjs)

| STT | Trong sheet | Sau khi sửa |
|---|---|---|
| 10 | Mặt Trận Miền Tây Khôn Có Gì Lạ | Mặt Trận Miền Tây Không Có Gì Lạ |
| 12 | Lược Khảo Lịch sử Thượng Hải | Lược Khảo Lịch Sử Thượng Hải |
| 47 | The T assistant of Jakob von Gunten | Jakob von Gunten |
| 53 | The Rise of Network Society | The Rise of the Network Society |

## Nghi sai nhưng giữ nguyên (bạn quyết)

- STT 5 "Dế Hèn" (Nguyễn Huy Thiệp): không thấy tác phẩm tên này; "Dế Mèn Phiêu Lưu Ký" là của Tô Hoài.
- STT 12 "Lược Khảo Lịch Sử Thượng Hải" (Trần Trọng Kim): tên và tác giả có vẻ không khớp.
- STT 29 "Nền Kinh Tế Chia Sẻ" (Swami Iyer) và STT 28 tác giả "Professor John Vu - Nguyên Phong": giữ như sheet.

## ISBN: cũ → mới (đặt tên file ảnh theo cột ISBN-13 mới, không gạch)

35/66 ISBN bị sai chữ số kiểm tra nên chữ số cuối đã được tính lại.

| STT | Tên sách | ISBN cũ | ISBN-13 mới (tên file ảnh) | Đổi? |
|---|---|---|---|---|
| 1 | Thời Xa Vắng | 9786045301232 | 9786045301234 | có |
| 2 | Mùa Lá Rụng Trong Vườn | 9786043456789 | 9786043456783 | có |
| 3 | Nỗi Buồn Chiến Tranh | 9786045314524 | 9786045314524 |  |
| 4 | Phố | 9786041456123 | 9786041456129 | có |
| 5 | Dế Hèn | 9786041098765 | 9786041098763 | có |
| 6 | Tướng Về Hưu | 9786041011223 | 9786041011229 | có |
| 7 | Giăng Sáng | 9786042033445 | 9786042033442 | có |
| 8 | Sống Mòn | 9786042078901 | 9786042078900 | có |
| 9 | Vỡ Bờ | 9786043123456 | 9786043123456 |  |
| 10 | Mặt Trận Miền Tây Không Có Gì Lạ | 9780449213940 | 9780449213940 |  |
| 11 | Đất Khổ | 9786045356789 | 9786045356784 | có |
| 12 | Lược Khảo Lịch Sử Thượng Hải | 9786043987654 | 9786043987652 | có |
| 13 | Việt Nam Sử Lược | 9786043111112 | 9786043111118 | có |
| 14 | Đại Việt Sử Ký Tiền Biên | 9786046888881 | 9786046888888 | có |
| 15 | Việt Nam Phong Tục | 9786043222223 | 9786043222227 | có |
| 16 | Đường Kách Mệnh | 9786045777772 | 9786045777770 | có |
| 17 | Búp Sen Xanh | 9786042111223 | 9786042111225 | có |
| 18 | Miền Hoang Tưởng | 9786041088991 | 9786041088993 | có |
| 19 | Cơ Sở Lập Trình Hướng Đối Tượng | 9786047354321 | 9786047354320 | có |
| 20 | Kiến Trúc Phần Mềm | 9786048912345 | 9786048912345 |  |
| 21 | Phân Tích Và Thiết Kế Hệ Thống Thông Tin | 9786049112234 | 9786049112232 | có |
| 22 | Nhập Môn Trí Tuệ Nhân Tạo | 9786047345678 | 9786047345670 | có |
| 23 | Cơ Sở Dữ Liệu Nâng Cao | 9786040123987 | 9786040123985 | có |
| 24 | Kinh Tế Vi Mô | 9786049567890 | 9786049567896 | có |
| 25 | Quản Trị Chiến Lược Doanh Nghiệp | 9786047987652 | 9786047987658 | có |
| 26 | Marketing Ngầm | 9786041045673 | 9786041045675 | có |
| 27 | Đường Xưa Mây Trẻ | 9786049223345 | 9786049223341 | có |
| 28 | Muôn Kiếp Nhân Sinh | 9786045899887 | 9786045899885 | có |
| 29 | Nền Kinh Tế Chia Sẻ | 9786047712348 | 9786047712342 | có |
| 30 | Gia Đình Vui Vẻ | 9786042099882 | 9786042099882 |  |
| 31 | The Notebooks of Malte Laurids Brigge | 9780679724940 | 9780679724940 |  |
| 32 | The Street of Crocodiles | 9780141189871 | 9780141189871 |  |
| 33 | The Loser | 9780375703218 | 9780375703218 |  |
| 34 | Ferdydurke | 9780300082408 | 9780300082401 | có |
| 35 | Zeno's Conscience | 9780679728863 | 9780679728863 |  |
| 36 | The Passion According to G.H. | 9780811219197 | 9780811219198 | có |
| 37 | Independent People | 9780375705649 | 9780375705649 |  |
| 38 | The Book of Disquiet | 9780811211153 | 9780811211154 | có |
| 39 | The Emigrants | 9780812227039 | 9780812227031 | có |
| 40 | Solenoid | 9781646050049 | 9781646050048 | có |
| 41 | Warlock | 9781590171547 | 9781590171547 |  |
| 42 | Dictionary of the Khazars | 9780394753171 | 9780394753171 |  |
| 43 | The Man Without Qualities | 9780375705823 | 9780375705823 |  |
| 44 | The Notebook | 9780307269386 | 9780307269386 |  |
| 45 | The Proof | 9780802135681 | 9780802135681 |  |
| 46 | The Third Lie | 9780802135698 | 9780802135698 |  |
| 47 | Jakob von Gunten | 9781590170342 | 9781590170342 |  |
| 48 | Selected Stories | 9780940322035 | 9780940322035 |  |
| 49 | The Arcades Project | 9780679764588 | 9780679764588 |  |
| 50 | Simulacra and Simulation | 9780452011502 | 9780452011502 |  |
| 51 | The Production of Space | 9780631140481 | 9780631140481 |  |
| 52 | Gender Trouble | 9780415389558 | 9780415389556 | có |
| 53 | The Rise of the Network Society | 9781405196864 | 9781405196864 |  |
| 54 | The Information | 9780307387371 | 9780307387370 | có |
| 55 | Chaos | 9780143113256 | 9780143113256 |  |
| 56 | Genius | 9780679747048 | 9780679747048 |  |
| 57 | Near to the Wild Heart | 9780811219326 | 9780811219327 | có |
| 58 | Cosmos | 9780802151254 | 9780802151254 |  |
| 59 | Sanatorium Under the Sign of the Hourglass | 9780141189888 | 9780141189888 |  |
| 60 | The Blue of Noon | 9780714528571 | 9780714528571 |  |
| 61 | The Book of Monelle | 9781878972232 | 9781878972231 | có |
| 62 | The Book of Imaginary Beings | 9780142439166 | 9780142439166 |  |
| 63 | Institute Benjamenta | 9780811214871 | 9780811214872 | có |
| 64 | Introduction to Mathematical Philosophy | 9780486277240 | 9780486277240 |  |
| 65 | Language, Truth and Logic | 9780486200194 | 9780486200194 |  |
| 66 | Camera Lucida | 9780374520342 | 9780374520342 |  |

## Thể loại, shop, giá, tồn kho

| STT | Tên sách | Thể loại sheet | Thể loại mới | Shop | Tình trạng | Giá | Tồn |
|---|---|---|---|---|---|---|---|
| 1 | Thời Xa Vắng | Tiểu thuyết hiện đại Việt Nam | Văn học › Tiểu thuyết Việt Nam | Hà Nội Xưa | Mới | 111.000 | 5 |
| 2 | Mùa Lá Rụng Trong Vườn | Tiểu thuyết hiện thực | Văn học › Tiểu thuyết Việt Nam | Hà Nội Xưa | Như mới | 121.000 | 4 |
| 3 | Nỗi Buồn Chiến Tranh | Tiểu thuyết chiến tranh | Văn học › Tiểu thuyết Việt Nam | Hà Nội Xưa | Tốt | 82.000 | 5 |
| 4 | Phố | Tiểu thuyết hiện thực đô thị | Văn học › Tiểu thuyết Việt Nam | Hà Nội Xưa | Khá | 92.000 | 3 |
| 5 | Dế Hèn | Tuyển tập truyện ngắn | Văn học › Truyện ngắn | Hà Nội Xưa | Mới | 113.000 | 5 |
| 6 | Tướng Về Hưu | Truyện ngắn hiện thực | Văn học › Truyện ngắn | Hà Nội Xưa | Như mới | 91.000 | 3 |
| 7 | Giăng Sáng | Tuyển tập truyện ngắn | Văn học › Truyện ngắn | Hà Nội Xưa | Tốt | 137.000 | 5 |
| 8 | Sống Mòn | Tiểu thuyết tâm lý xã hội | Văn học › Tiểu thuyết Việt Nam | Hà Nội Xưa | Mới | 108.000 | 5 |
| 9 | Vỡ Bờ | Tiểu thuyết lịch sử | Văn học › Tiểu thuyết lịch sử | Hà Nội Xưa | Khá | 104.000 | 4 |
| 10 | Mặt Trận Miền Tây Không Có Gì Lạ | Tiểu thuyết chiến tranh | Văn học › Tiểu thuyết nước ngoài | Hà Nội Xưa | Như mới | 135.000 | 5 |
| 11 | Đất Khổ | Tiểu thuyết hiện thực | Văn học › Tiểu thuyết Việt Nam | Hà Nội Xưa | Mới | 121.000 | 3 |
| 12 | Lược Khảo Lịch Sử Thượng Hải | Lịch sử khảo cứu | Lịch sử – Chính trị › Lịch sử Việt Nam | Hà Nội Xưa | Tốt | 131.000 | 4 |
| 13 | Việt Nam Sử Lược | Lịch sử học | Lịch sử – Chính trị › Lịch sử Việt Nam | Hà Nội Xưa | Như mới | 194.000 | 4 |
| 14 | Đại Việt Sử Ký Tiền Biên | Sử liệu cổ | Lịch sử – Chính trị › Lịch sử Việt Nam | Hà Nội Xưa | Mới | 214.000 | 3 |
| 15 | Việt Nam Phong Tục | Khảo cứu văn hóa | Triết học – Tôn giáo › Văn hóa học | Hà Nội Xưa | Như mới | 149.000 | 4 |
| 16 | Đường Kách Mệnh | Tài liệu chính trị lịch sử | Lịch sử – Chính trị › Lịch sử Việt Nam | Hà Nội Xưa | Tốt | 116.000 | 3 |
| 17 | Búp Sen Xanh | Tiểu sử văn học | Tiểu sử – Hồi ký › Tiểu sử – Hồi ký văn học | Hà Nội Xưa | Mới | 117.000 | 5 |
| 18 | Miền Hoang Tưởng | Tuyển tập truyện ngắn | Văn học › Truyện ngắn | Hà Nội Xưa | Khá | 80.000 | 4 |
| 19 | Cơ Sở Lập Trình Hướng Đối Tượng | Giáo trình Công nghệ thông tin | Giáo trình › Công nghệ thông tin | Hà Nội Xưa | Mới | 109.000 | 3 |
| 20 | Kiến Trúc Phần Mềm | Giáo trình Công nghệ thông tin | Giáo trình › Công nghệ thông tin | Hà Nội Xưa | Như mới | 112.000 | 4 |
| 21 | Phân Tích Và Thiết Kế Hệ Thống Thông Tin | Giáo trình CNTT / Business Analyst | Giáo trình › Công nghệ thông tin | Hà Nội Xưa | Tốt | 88.000 | 4 |
| 22 | Nhập Môn Trí Tuệ Nhân Tạo | Giáo trình Khoa học máy tính | Giáo trình › Công nghệ thông tin | Hà Nội Xưa | Mới | 119.000 | 5 |
| 23 | Cơ Sở Dữ Liệu Nâng Cao | Giáo trình CNTT | Giáo trình › Công nghệ thông tin | Hà Nội Xưa | Khá | 80.000 | 4 |
| 24 | Kinh Tế Vi Mô | Giáo trình Kinh tế học | Giáo trình › Kinh tế – Quản trị | Hà Nội Xưa | Như mới | 110.000 | 3 |
| 25 | Quản Trị Chiến Lược Doanh Nghiệp | Giáo trình Quản trị kinh doanh | Giáo trình › Kinh tế – Quản trị | Hà Nội Xưa | Mới | 109.000 | 5 |
| 26 | Marketing Ngầm | Sách chuyên khảo Truyền thông | Kinh tế – Kinh doanh › Marketing – Bán hàng | Hà Nội Xưa | Tốt | 94.000 | 4 |
| 27 | Đường Xưa Mây Trẻ | Triết học Phật giáo / Tâm linh | Triết học – Tôn giáo › Phật giáo – Tâm linh | Hà Nội Xưa | Mới | 134.000 | 3 |
| 28 | Muôn Kiếp Nhân Sinh | Triết học tâm linh / Huyền bí | Triết học – Tôn giáo › Phật giáo – Tâm linh | Hà Nội Xưa | Như mới | 115.000 | 4 |
| 29 | Nền Kinh Tế Chia Sẻ | Kinh tế học hiện đại | Kinh tế – Kinh doanh › Kinh tế học | Hà Nội Xưa | Khá | 85.000 | 3 |
| 30 | Gia Đình Vui Vẻ | Sách kỹ năng gia đình | Kỹ năng sống › Gia đình – Nuôi dạy con | Hà Nội Xưa | Mới | 113.000 | 4 |
| 31 | The Notebooks of Malte Laurids Brigge | Tiểu thuyết hiện sinh | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Mới | 420.000 | 3 |
| 32 | The Street of Crocodiles | Truyện ngắn siêu thực | Văn học › Truyện ngắn | Cũ Sài Gòn | Như mới | 349.000 | 4 |
| 33 | The Loser | Tiểu thuyết nghệ thuật | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Tốt | 228.000 | 4 |
| 34 | Ferdydurke | Tiểu thuyết châm biếm | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Mới | 413.000 | 4 |
| 35 | Zeno's Conscience | Tiểu thuyết phân tâm học | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Khá | 408.000 | 4 |
| 36 | The Passion According to G.H. | Triết học hiện sinh | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Như mới | 260.000 | 5 |
| 37 | Independent People | Tiểu thuyết hiện thực Iceland | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Mới | 525.000 | 5 |
| 38 | The Book of Disquiet | Văn học thử nghiệm | Văn học › Văn học thử nghiệm – Siêu thực | Cũ Sài Gòn | Tốt | 273.000 | 5 |
| 39 | The Emigrants | Hư cấu tài liệu | Văn học › Văn học thử nghiệm – Siêu thực | Cũ Sài Gòn | Như mới | 239.000 | 3 |
| 40 | Solenoid | Tiểu thuyết siêu thực | Văn học › Văn học thử nghiệm – Siêu thực | Cũ Sài Gòn | Mới | 334.000 | 5 |
| 41 | Warlock | Tiểu thuyết miền Tây u tối | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Khá | 268.000 | 4 |
| 42 | Dictionary of the Khazars | Tiểu thuyết từ điển | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Như mới | 262.000 | 4 |
| 43 | The Man Without Qualities | Tiểu thuyết triết học | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Mới | 561.000 | 3 |
| 44 | The Notebook | Tiểu thuyết tâm lý | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Tốt | 274.000 | 3 |
| 45 | The Proof | Tiểu thuyết tiếp nối | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Như mới | 271.000 | 3 |
| 46 | The Third Lie | Tiểu thuyết kết thúc bộ ba | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Mới | 316.000 | 4 |
| 47 | Jakob von Gunten | Tiểu thuyết nhật ký | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Khá | 387.000 | 3 |
| 48 | Selected Stories | Tuyển tập truyện ngắn | Văn học › Truyện ngắn | Cũ Sài Gòn | Như mới | 216.000 | 5 |
| 49 | The Arcades Project | Văn hóa học / Triết học | Triết học – Tôn giáo › Văn hóa học | Cũ Sài Gòn | Mới | 384.000 | 4 |
| 50 | Simulacra and Simulation | Triết học hậu hiện đại | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Tốt | 231.000 | 3 |
| 51 | The Production of Space | Triết học không gian | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Như mới | 332.000 | 4 |
| 52 | Gender Trouble | Triết học giới | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Mới | 309.000 | 3 |
| 53 | The Rise of the Network Society | Xã hội học công nghệ | Khoa học – Công nghệ › Truyền thông – Xã hội học | Cũ Sài Gòn | Khá | 278.000 | 4 |
| 54 | The Information | Khoa học thông tin | Khoa học – Công nghệ › Khoa học thông tin | Cũ Sài Gòn | Như mới | 345.000 | 4 |
| 55 | Chaos | Khoa học tự nhiên | Khoa học – Công nghệ › Khoa học tự nhiên | Cũ Sài Gòn | Mới | 310.000 | 5 |
| 56 | Genius | Tiểu sử khoa học | Khoa học – Công nghệ › Tiểu sử khoa học | Cũ Sài Gòn | Tốt | 334.000 | 4 |
| 57 | Near to the Wild Heart | Tiểu thuyết tâm lý | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Như mới | 360.000 | 4 |
| 58 | Cosmos | Tiểu thuyết phi lý | Văn học › Văn học thử nghiệm – Siêu thực | Cũ Sài Gòn | Mới | 261.000 | 5 |
| 59 | Sanatorium Under the Sign of the Hourglass | Truyện ngắn giả tưởng | Văn học › Truyện ngắn | Cũ Sài Gòn | Khá | 350.000 | 4 |
| 60 | The Blue of Noon | Tiểu thuyết khiêu khích | Văn học › Văn học thử nghiệm – Siêu thực | Cũ Sài Gòn | Như mới | 434.000 | 5 |
| 61 | The Book of Monelle | Tiểu thuyết tượng trưng | Văn học › Văn học thử nghiệm – Siêu thực | Cũ Sài Gòn | Mới | 380.000 | 5 |
| 62 | The Book of Imaginary Beings | Từ điển sinh vật huyền thoại | Tham khảo › Từ điển – Bách khoa | Cũ Sài Gòn | Tốt | 242.000 | 4 |
| 63 | Institute Benjamenta | Tiểu thuyết | Văn học › Tiểu thuyết nước ngoài | Cũ Sài Gòn | Như mới | 233.000 | 5 |
| 64 | Introduction to Mathematical Philosophy | Triết học toán học | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Mới | 458.000 | 4 |
| 65 | Language, Truth and Logic | Triết học phân tích | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Khá | 307.000 | 5 |
| 66 | Camera Lucida | Nhiếp ảnh học / Triết học | Triết học – Tôn giáo › Triết học phương Tây | Cũ Sài Gòn | Như mới | 251.000 | 5 |
