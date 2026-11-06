# Dữ liệu sách mẫu — báo cáo để duyệt

Sinh bởi `tools/books/gen.mjs` từ `tools/books/books.xlsx` (70 sách, ảnh bìa trong `covers.json`). Chạy lại script sau khi sửa Excel.

## Quy tắc đã dùng (sửa ở đầu gen.mjs)

- **Tình trạng** (giả lập trong sheet): Mới, chưa sử dụng → `NEW`; Như mới → `LIKE_NEW`; Đã đọc, còn tốt → `VERY_GOOD`; Đã đọc, gáy hơi nhăn và Đã qua sử dụng, góc bìa hơi mòn → `GOOD`.
- **Khối lượng**: lấy cột "Khối lượng giả lập" của sheet (290 – 1.530 g).
- **Shop**: tiểu thuyết (nhóm "Văn học") → Nhà Sách Cũ Sài Gòn; còn lại → Tiệm Sách Hà Nội Xưa.
- **Giá**: 120.000 – 450.000 đồng theo tình trạng, số trang, bìa cứng; làm tròn 1.000. **Tồn kho**: 3 – 5 cuốn.
- **Tác giả để trống** (STT 40) → "Nhiều tác giả".
- **Ảnh**: mỗi sách một ảnh bìa, URL Cloudinary lưu ở `book_images` (ISBN-13 là tên ảnh `rebook/covers/<isbn>`).

## Từng sách

| STT | Tên sách | ISBN-13 | Thể loại sheet | Thể loại mới | Shop | Tình trạng | Khối lượng | Giá | Tồn | Ảnh |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Atomic Habits | 9780735211292 | Kinh doanh / Tâm lý học / Phát triển bản thân | Kỹ năng sống › Phát triển bản thân | Hà Nội Xưa | Mới, chưa sử dụng | 540 g | 306.000 | 5 | có |
| 2 | The French Illusion | 9780385550543 | Giật gân / Hồi hộp / Tiểu thuyết gián điệp | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Mới, chưa sử dụng | 520 g | 406.000 | 3 | có |
| 3 | Ruthless | 9780593973301 | Tiểu thuyết về phụ nữ / Tình cảm đương đại | Văn học › Ngôn tình – Lãng mạn | Cũ Sài Gòn | Đã đọc, còn tốt | 480 g | 253.000 | 4 | có |
| 4 | Cursed City | 9780593953457 | Kỳ ảo đô thị / Tình cảm | Văn học › Kỳ ảo – Giả tưởng | Cũ Sài Gòn | Đã đọc, còn tốt | 590 g | 295.000 | 3 | có |
| 5 | Dawn of the Cursed Queen: Deluxe Special Edition | 9781496758088 | Kỳ ảo / Tình cảm kỳ ảo | Văn học › Kỳ ảo – Giả tưởng | Cũ Sài Gòn | Như mới, bìa và trang sạch | 850 g | 390.000 | 5 | có |
| 6 | Hollywood, Ending | 9780525426073 | Văn học / Tình cảm đương đại | Văn học › Văn học đương đại | Cũ Sài Gòn | Đã đọc, gáy hơi nhăn | 510 g | 224.000 | 4 | có |
| 7 | Free Falling | 9780593977798 | Tình cảm đương đại / Tình cảm miền Tây / Tiểu thuyết siêu nhiên / Tình cảm kỳ ảo | Văn học › Ngôn tình – Lãng mạn | Cũ Sài Gòn | Mới, chưa sử dụng | 400 g | 304.000 | 5 | có |
| 8 | Exit Party | 9780593321461 | Văn học | Văn học › Văn học đương đại | Cũ Sài Gòn | Mới, chưa sử dụng | 530 g | 401.000 | 5 | có |
| 9 | Hollow Bones | 9780593726259 | Tiểu thuyết về phụ nữ / Văn học | Văn học › Văn học đương đại | Cũ Sài Gòn | Đã qua sử dụng, góc bìa hơi mòn | 650 g | 350.000 | 4 | có |
| 10 | The Pirate Queen | 9780385550345 | Tiểu thuyết lịch sử / Giật gân / Hồi hộp | Văn học › Tiểu thuyết lịch sử | Cũ Sài Gòn | Đã qua sử dụng, góc bìa hơi mòn | 750 g | 332.000 | 5 | có |
| 11 | The Disappearers | 9780593717202 | Văn học | Văn học › Văn học đương đại | Cũ Sài Gòn | Như mới, bìa và trang sạch | 880 g | 364.000 | 5 | có |
| 12 | My Dreadful Darling | 9781638936015 | Tình cảm giật gân / Gothic / Kinh dị / Tình cảm đương đại | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Mới, chưa sử dụng | 680 g | 372.000 | 3 | có |
| 13 | Big Little Truths: Reese's Book Club | 9780593798638 | Tiểu thuyết về phụ nữ / Giật gân / Hồi hộp | Văn học › Văn học đương đại | Cũ Sài Gòn | Đã đọc, còn tốt | 620 g | 293.000 | 3 | có |
| 14 | The Poison Daughter | 9781638935971 | Tình cảm kỳ ảo | Văn học › Kỳ ảo – Giả tưởng | Cũ Sài Gòn | Như mới, bìa và trang sạch | 930 g | 346.000 | 3 | có |
| 15 | The True Meaning of Love | 9780593973141 | Tiểu thuyết về phụ nữ / Tình cảm đương đại | Văn học › Ngôn tình – Lãng mạn | Cũ Sài Gòn | Mới, chưa sử dụng | 430 g | 274.000 | 4 | có |
| 16 | The Butcher Legacy | 9781638933403 | Tiểu thuyết tội phạm / Giật gân / Hồi hộp | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Như mới, bìa và trang sạch | 530 g | 348.000 | 5 | có |
| 17 | Insatiable | 9781638935469 | Tình cảm giật gân / Gothic / Kinh dị / Tình cảm đương đại | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Đã đọc, còn tốt | 460 g | 176.000 | 5 | có |
| 18 | A Trade of Blood | 9780593723852 | Kỳ ảo sử thi / Trinh thám / Giật gân | Văn học › Kỳ ảo – Giả tưởng | Cũ Sài Gòn | Mới, chưa sử dụng | 630 g | 379.000 | 4 | có |
| 19 | The Amateur | 9780385551298 | Văn học / Giật gân / Hồi hộp | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Mới, chưa sử dụng | 490 g | 423.000 | 4 | có |
| 20 | Getting Away with Murder | 9780593832479 | Giật gân / Hồi hộp / Tiểu thuyết về phụ nữ | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Đã đọc, còn tốt | 580 g | 254.000 | 4 | có |
| 21 | Simply Ina | 9780593234174 | Sách nấu ăn | Ẩm thực – Nấu ăn › Nấu ăn gia đình | Hà Nội Xưa | Mới, chưa sử dụng | 760 g | 302.000 | 5 | có |
| 22 | Mediterranean All the Way | 9780593799901 | Ẩm thực quốc tế | Ẩm thực – Nấu ăn › Ẩm thực quốc tế | Hà Nội Xưa | Đã qua sử dụng, góc bìa hơi mòn | 860 g | 214.000 | 3 | có |
| 23 | Love and Lemons Pop of Flavor | 9780593853146 | Nấu ăn theo chế độ / Phương pháp nấu ăn | Ẩm thực – Nấu ăn › Ăn chay – Dinh dưỡng | Hà Nội Xưa | Đã qua sử dụng, góc bìa hơi mòn | 880 g | 302.000 | 3 | có |
| 24 | Why Am I Like This? | 9780593994849 | Phát triển bản thân / Tâm lý học | Kỹ năng sống › Tâm lý học | Hà Nội Xưa | Mới, chưa sử dụng | 480 g | 276.000 | 4 | có |
| 25 | The Rush | 9780525562238 | Lịch sử Mỹ thế kỷ XIX / Lịch sử thế giới | Lịch sử – Chính trị › Lịch sử thế giới | Hà Nội Xưa | Mới, chưa sử dụng | 670 g | 380.000 | 4 | có |
| 26 | Ottolenghi Simple Too | 9781984860088 | Ẩm thực quốc tế | Ẩm thực – Nấu ăn › Ẩm thực quốc tế | Hà Nội Xưa | Như mới, bìa và trang sạch | 840 g | 327.000 | 3 | có |
| 27 | Into the quiet | 9780593193808 | Đời sống tinh thần / Tôn giáo / Phát triển bản thân | Triết học – Tôn giáo › Tôn giáo – Tâm linh | Hà Nội Xưa | Như mới, bìa và trang sạch | 490 g | 293.000 | 4 | có |
| 28 | Sleeping Beauties | 9780593655276 | Khoa học / Công nghệ / Phát triển bản thân | Khoa học – Công nghệ › Khoa học tự nhiên | Hà Nội Xưa | Mới, chưa sử dụng | 630 g | 329.000 | 3 | có |
| 29 | How to Win at Chess, Next Level | 9780593837818 | Phi hư cấu / Trò chơi / Giải đố | Sở thích – Giải trí › Trò chơi – Giải đố | Hà Nội Xưa | Như mới, bìa và trang sạch | 410 g | 267.000 | 5 | có |
| 30 | What Could Possibly Go Right? | 9780593731772 | Lãnh đạo / Tiểu sử / Hồi ký / Hồi ký ẩm thực / Du lịch | Tiểu sử – Hồi ký › Hồi ký – Tự truyện | Hà Nội Xưa | Đã đọc, còn tốt | 930 g | 295.000 | 4 | có |
| 31 | Man in the Mirror | 9780593802014 | Lịch sử Mỹ thế kỷ XXI | Lịch sử – Chính trị › Lịch sử thế giới | Hà Nội Xưa | Đã qua sử dụng, góc bìa hơi mòn | 650 g | 300.000 | 3 | có |
| 32 | A Fabulous Debt | 9780593719183 | Kinh tế học / Lịch sử thế giới | Kinh tế – Kinh doanh › Kinh tế học | Hà Nội Xưa | Như mới, bìa và trang sạch | 570 g | 411.000 | 5 | có |
| 33 | Work in Progress | 9780593734483 | Hồi ký nghệ thuật / Giải trí / Phát triển bản thân / Nuôi dạy con | Tiểu sử – Hồi ký › Hồi ký – Tự truyện | Hà Nội Xưa | Mới, chưa sử dụng | 540 g | 359.000 | 5 | có |
| 34 | The Cauldron | 9780593805053 | Lịch sử Trung Đông / Chính trị thế giới | Lịch sử – Chính trị › Lịch sử thế giới | Hà Nội Xưa | Như mới, bìa và trang sạch | 680 g | 450.000 | 4 | có |
| 35 | An Unexpected Life | 9780593978177 | Tiểu sử nhân vật chính trị | Tiểu sử – Hồi ký › Chân dung nhân vật | Hà Nội Xưa | Mới, chưa sử dụng | 410 g | 280.000 | 5 | có |
| 36 | Meals You Can't Mess Up | 9780593968710 | Ẩm thực vùng miền Mỹ / Phương pháp nấu ăn | Ẩm thực – Nấu ăn › Nấu ăn gia đình | Hà Nội Xưa | Mới, chưa sử dụng | 730 g | 308.000 | 4 | có |
| 37 | Saved by the Pack | 9781426224706 | Thú cưng / Tiểu sử / Hồi ký / Khoa học / Công nghệ | Sở thích – Giải trí › Thú cưng – Thiên nhiên | Hà Nội Xưa | Đã qua sử dụng, góc bìa hơi mòn | 510 g | 194.000 | 5 | có |
| 38 | Redwood | 9780593728123 | Lịch sử quân sự / Lịch sử thế giới / Tiểu sử / Hồi ký | Lịch sử – Chính trị › Lịch sử thế giới | Hà Nội Xưa | Đã đọc, còn tốt | 590 g | 337.000 | 5 | có |
| 39 | Veg Everything | 9780593836620 | Nấu ăn theo chế độ | Ẩm thực – Nấu ăn › Ăn chay – Dinh dưỡng | Hà Nội Xưa | Mới, chưa sử dụng | 730 g | 375.000 | 3 | có |
| 40 | The Portable Feminist Reader | 9780143110392 | Phi hư cấu / Phi hư cấu kinh điển | Hài hước – Tiểu luận › Tiểu luận – Tuyển tập | Hà Nội Xưa | Đã qua sử dụng, góc bìa hơi mòn | 760 g | 269.000 | 3 | có |
| 41 | Dark Tales | 9780143132004 | Gothic / Kinh dị / Văn học kinh điển / Tiểu thuyết siêu nhiên / Giật gân / Hồi hộp | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Mới, chưa sử dụng | 290 g | 186.000 | 4 | có |
| 42 | It Can't Happen Here | 9780451216588 | Văn học | Văn học › Văn học kinh điển | Cũ Sài Gòn | Mới, chưa sử dụng | 470 g | 255.000 | 5 | có |
| 43 | Twelve Years a Slave | 9780143106708 | Tiểu sử / Hồi ký / Phi hư cấu kinh điển / Lịch sử Mỹ thế kỷ XIX | Tiểu sử – Hồi ký › Hồi ký – Tự truyện | Hà Nội Xưa | Như mới, bìa và trang sạch | 380 g | 209.000 | 3 | có |
| 44 | The Collected Autobiographies of Maya Angelou | 9780679643258 | Hồi ký nghệ thuật / Giải trí / Tiểu sử nhà văn / Phi hư cấu kinh điển / Tiểu sử nhân vật lịch sử | Tiểu sử – Hồi ký › Hồi ký – Tự truyện | Hà Nội Xưa | Như mới, bìa và trang sạch | 1530 g | 395.000 | 3 | có |
| 45 | Vera | 9780375755347 | Hồi ký nghệ thuật / Giải trí / Tiểu sử nhà văn / Phi hư cấu kinh điển | Tiểu sử – Hồi ký › Chân dung nhân vật | Hà Nội Xưa | Đã đọc, còn tốt | 600 g | 217.000 | 4 | có |
| 46 | The Rise of Theodore Roosevelt | 9781400069651 | Tiểu sử nhân vật chính trị / Lịch sử quân sự / Chính trị trong nước | Tiểu sử – Hồi ký › Chân dung nhân vật | Hà Nội Xưa | Đã đọc, còn tốt | 1150 g | 383.000 | 3 | có |
| 47 | The Diary of a Young Girl | 9780307594006 | Lịch sử châu Âu / Phi hư cấu kinh điển / Tiểu sử nhân vật lịch sử | Tiểu sử – Hồi ký › Hồi ký – Tự truyện | Hà Nội Xưa | Như mới, bìa và trang sạch | 470 g | 246.000 | 4 | có |
| 48 | The Short Novels of John Steinbeck | 9780143105770 | Văn học / Văn học kinh điển / Truyện ngắn | Văn học › Văn học kinh điển | Cũ Sài Gòn | Đã đọc, còn tốt | 720 g | 353.000 | 4 | có |
| 49 | Shadow Country | 9780812980622 | Văn học / Văn học kinh điển | Văn học › Văn học kinh điển | Cũ Sài Gòn | Đã qua sử dụng, góc bìa hơi mòn | 1040 g | 335.000 | 3 | có |
| 50 | The Stone Diaries | 9780143105503 | Văn học / Văn học kinh điển / Tiểu thuyết lịch sử | Văn học › Văn học kinh điển | Cũ Sài Gòn | Mới, chưa sử dụng | 400 g | 238.000 | 4 | có |
| 51 | A Death in the Family | 9780143105718 | Văn học / Văn học kinh điển | Văn học › Văn học kinh điển | Cũ Sài Gòn | Mới, chưa sử dụng | 370 g | 267.000 | 3 | có |
| 52 | The Winter of Our Discontent | 9780143039488 | Văn học / Văn học kinh điển | Văn học › Văn học kinh điển | Cũ Sài Gòn | Mới, chưa sử dụng | 380 g | 252.000 | 5 | có |
| 53 | Excellent Women | 9780143104872 | Văn học kinh điển / Văn học | Văn học › Văn học kinh điển | Cũ Sài Gòn | Đã đọc, còn tốt | 330 g | 156.000 | 4 | có |
| 54 | The Haunting of Hill House | 9780143129370 | Gothic / Kinh dị / Văn học kinh điển | Văn học › Trinh thám – Kinh dị | Cũ Sài Gòn | Như mới, bìa và trang sạch | 320 g | 276.000 | 5 | có |
| 55 | We Have Always Lived in the Castle | 9780143134831 | Văn học / Văn học kinh điển / Gothic / Kinh dị | Văn học › Văn học kinh điển | Cũ Sài Gòn | Đã qua sử dụng, góc bìa hơi mòn | 330 g | 236.000 | 3 | có |
| 56 | Beloved (Pulitzer Prize Winner) | 9780525659273 | Văn học | Văn học › Văn học đương đại | Cũ Sài Gòn | Như mới, bìa và trang sạch | 440 g | 315.000 | 5 | có |
| 57 | The Grapes of Wrath | 9780143039433 | Văn học kinh điển / Văn học / Tiểu thuyết lịch sử | Văn học › Văn học kinh điển | Cũ Sài Gòn | Đã đọc, còn tốt | 650 g | 288.000 | 3 | có |
| 58 | Kristin Lavransdatter | 9780143039167 | Tiểu thuyết lịch sử / Văn học kinh điển | Văn học › Tiểu thuyết lịch sử | Cũ Sài Gòn | Như mới, bìa và trang sạch | 1180 g | 384.000 | 5 | có |
| 59 | How to Be Okay When Nothing Is Okay | 9780593833216 | Phát triển bản thân / Hài hước / Tiểu sử / Hồi ký | Hài hước – Tiểu luận › Hài hước | Hà Nội Xưa | Đã qua sử dụng, góc bìa hơi mòn | 450 g | 274.000 | 5 | có |
| 60 | I'll Have What She's Having | 9780593596579 | Tiểu sử / Hồi ký / Hài hước | Hài hước – Tiểu luận › Hài hước | Hà Nội Xưa | Mới, chưa sử dụng | 510 g | 315.000 | 5 | có |
| 61 | What in the World?! | 9780593594414 | Hài hước / Tiểu sử / Hồi ký | Hài hước – Tiểu luận › Hài hước | Hà Nội Xưa | Đã đọc, còn tốt | 300 g | 120.000 | 5 | có |
| 62 | Democracy or Else | 9781638931430 | Chính trị trong nước / Hài hước | Lịch sử – Chính trị › Chính trị | Hà Nội Xưa | Mới, chưa sử dụng | 380 g | 237.000 | 3 | có |
| 63 | A City on Mars | 9781984881748 | Khoa học / Công nghệ / Chính trị / Hài hước | Khoa học – Công nghệ › Khoa học tự nhiên | Hà Nội Xưa | Mới, chưa sử dụng | 490 g | 375.000 | 4 | có |
| 64 | Where the Deer and the Antelope Play | 9781101984703 | Hài hước / Khoa học / Công nghệ / Lịch sử Mỹ | Hài hước – Tiểu luận › Hài hước | Hà Nội Xưa | Đã đọc, còn tốt | 440 g | 290.000 | 4 | có |
| 65 | Quietly Hostile | 9780593315699 | Hài hước / Tiểu luận / Tuyển tập / Tiểu sử / Hồi ký | Hài hước – Tiểu luận › Tiểu luận – Tuyển tập | Hà Nội Xưa | Như mới, bìa và trang sạch | 400 g | 193.000 | 3 | có |
| 66 | What If? 2 | 9780525537113 | Hài hước / Khoa học / Công nghệ | Khoa học – Công nghệ › Khoa học tự nhiên | Hà Nội Xưa | Như mới, bìa và trang sạch | 550 g | 258.000 | 3 | có |
| 67 | Yearbook | 9781984825421 | Tiểu sử / Hồi ký / Hài hước | Hài hước – Tiểu luận › Hài hước | Hà Nội Xưa | Mới, chưa sử dụng | 360 g | 230.000 | 3 | có |
| 68 | Leaving Isn't the Hardest Thing | 9780593080764 | Tiểu sử / Hồi ký / Hài hước | Tiểu sử – Hồi ký › Hồi ký – Tự truyện | Hà Nội Xưa | Mới, chưa sử dụng | 390 g | 235.000 | 4 | có |
| 69 | Humor, Seriously | 9780593135280 | Kinh doanh / Phát triển bản thân / Hài hước | Kỹ năng sống › Phát triển bản thân | Hà Nội Xưa | Mới, chưa sử dụng | 470 g | 297.000 | 3 | có |
| 70 | Wow, No Thank You. | 9780525563488 | Hài hước / Tiểu sử / Hồi ký | Hài hước – Tiểu luận › Hài hước | Hà Nội Xưa | Như mới, bìa và trang sạch | 390 g | 301.000 | 4 | có |
