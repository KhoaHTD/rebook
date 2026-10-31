# ReBook online — chạy trên PC ở nhà, bạn bè ở xa vào xem

PC nhà chạy cả **PostgreSQL + backend + web**, rồi mở ra Internet bằng **một link duy nhất** (Cloudflare Tunnel).
Bạn bè chỉ cần mở link bằng trình duyệt (điện thoại hay máy tính), **không cài gì**.

```
Bạn bè ──https──▶ Cloudflare ──▶ cloudflared (PC nhà) ──▶ demo_server :8000 ─┬─ /      file web
                                                                              ├─ /api   ──▶ backend :8080 ──▶ PostgreSQL
                                                                              └─ /ws    ──▶ backend :8080 (đấu giá realtime)
```

---

## A. Dành cho BẠN (chủ PC) — trên PC nhà

### A1. Cài một lần (PC này ĐÃ cài xong, chỉ đọc để biết)
- Flutter ở `D:\flutter` (đã thêm vào PATH).
- `cloudflared.exe` ở `D:\Tools\cloudflared\` (tải từ GitHub chính thức của Cloudflare, chạy được ngay, không cần tài khoản).
- Nếu sau này mất: tải `cloudflared-windows-amd64.exe` từ <https://github.com/cloudflare/cloudflared/releases/latest>, đổi tên thành `cloudflared.exe`, đặt vào `D:\Tools\cloudflared\`.

### A2. Mỗi lần muốn mở cho bạn bè vào (làm theo đúng thứ tự)

1. **Bật PostgreSQL** (thường tự chạy cùng Windows).
2. **Bật backend**: mở IntelliJ, chạy `ReBookApplication`, đợi dòng `Started ReBookApplication`.
   Nếu báo *"Port 8080 was already in use"* nghĩa là backend **đã chạy sẵn** rồi, bỏ qua.
   Kiểm tra nhanh: mở `http://localhost:8080/categories` ra chữ JSON là ổn.
3. **Nhấp đúp** file `demo\start-demo.cmd` trong thư mục dự án.
   - Lần đầu (hoặc sau khi sửa code) nó **tự build web**, mất 1–2 phút. Các lần sau chạy ngay.
   - Muốn ép build lại web: mở CMD trong thư mục `demo` và gõ `start-demo.cmd -Rebuild`.
4. Đợi tới khi hiện khung màu xanh có dòng **link dạng `https://xxxx-xxxx-xxxx.trycloudflare.com`**.
   Link đã được **copy sẵn vào clipboard**, dán (Ctrl+V) gửi cho bạn bè. Link cũng lưu ở `demo\LINK.txt`.
5. **Giữ cửa sổ đó mở** suốt buổi demo. Cửa sổ tự báo đỏ nếu backend hoặc tunnel chết.

### A3. Tắt
- Nhấn **phím bất kỳ** trong cửa sổ `start-demo` → tự tắt máy chủ demo và tunnel. Link cũ lập tức chết.
- Lỡ đóng cửa sổ bằng nút X: chạy `powershell -File demo\stop-demo.ps1` để tắt phần còn sót (hoặc lần chạy `start-demo` sau cũng tự dọn).

### A4. Quan trọng nếu bạn KHÔNG ở nhà
- **Link đổi mỗi lần bật** (đây là bản miễn phí). Hãy bật xong, lấy link, gửi bạn bè **trước khi rời nhà**. Tunnel tự nối lại khi mạng chập chờn mà **giữ nguyên link**, miễn là cửa sổ `start-demo` còn mở và PC còn chạy.
- **PC không được ngủ / tắt / mất mạng / mất điện.** Script đã chặn Windows tự ngủ khi nó đang chạy, nhưng vẫn nên vào *Settings → System → Power* đặt *Screen* và *Sleep* về **Never** cho chắc, và **đừng để Windows tự cập nhật rồi khởi động lại** trong lúc demo.
- Đừng đóng IntelliJ (backend chạy trong đó). Đừng bấm Stop.
- **Nên cài sẵn một app điều khiển từ xa** (Chrome Remote Desktop, AnyDesk…) để nếu có sự cố thì bạn khởi động lại từ xa được.
- Phải chạy thử đầy đủ **ít nhất một lần tối nay**, gồm cả việc bạn bè thử vào từ mạng 4G (tắt Wi-Fi điện thoại để chắc là đi qua Internet).

### A5. Chuẩn bị dữ liệu cho buổi demo
- **Làm sạch dữ liệu** (lệnh ở `docs/DEMO.md`, mục 2). Sau đó dữ liệu mẫu có sẵn **phiên đấu giá số 1** (3 lô, hẹn bắt đầu sau 2 ngày), **buyer1, buyer2, buyer3 đã đăng ký + đặt cọc sẵn**.
- **Đấu giá khi bạn không có mặt ở PC**: phiên **tự bắt đầu đúng giờ** nếu đủ người đăng ký (đã kiểm chứng). Cách làm:
  1. Đăng nhập `admin@rebook.vn` trên web → **Phiên đấu giá** → tạo phiên mới (giờ bắt đầu cách hiện tại vài phút, hạn đăng ký sớm hơn giờ bắt đầu, người tối thiểu 1) → xếp lô → công bố.
  2. Bạn bè đăng nhập và **đăng ký + đặt cọc trước hạn đăng ký**. Sau hạn đó, hoặc sau khi phiên bắt đầu, **không đăng ký được nữa**.
  3. Đến giờ phiên tự mở và chạy.
- **Bạn ở nhà, muốn bắt đầu NGAY**: chạy `powershell -File demo\start-auction.ps1 -Session 1` (số 1 là mã phiên).
- Mỗi **lô chỉ được đưa vào đấu giá tối đa 2 lần**; phiên số 1 trong dữ liệu mẫu chỉ dùng được **một lần** (sau đó phải làm sạch dữ liệu, hoặc tạo phiên mới với lô "sẵn sàng").

### A6. Chạy app Android (máy ảo) trên laptop, nối vào PC nhà
PC nhà đang chạy `start-demo` thì laptop ở trường cũng chạy được **app Android thật** trên máy ảo, dùng chung dữ liệu với web. Laptop cần có repo, Flutter và Android Studio (đã tạo ít nhất một máy ảo).

1. Copy link `https://….trycloudflare.com` (lấy từ cửa sổ `start-demo` hoặc `demo\LINK.txt` ở nhà).
2. Trên laptop, **nhấp đúp** `demo\run-android.cmd` trong File Explorer.
3. Script tự thấy link trong clipboard, bạn chỉ cần nhấn **Enter** (hoặc dán link khác). Sau đó nó tự:
   kiểm tra link còn sống → ghi `apps/frontend/env/android.tunnel.json` → bật máy ảo nếu chưa bật → `flutter run`.
4. Lần đầu build mất vài phút. Trong cửa sổ: `r` = hot reload, `R` = hot restart, `q` = thoát.

- Chạy nhanh khỏi dán: `demo\run-android.cmd -Link https://xxxx.trycloudflare.com`. Chọn thiết bị khác: thêm `-Device emulator-5556`.
- **Link đổi mỗi lần PC nhà bật lại `start-demo`**, lúc đó chạy lại `run-android.cmd` với link mới.
- File `env/android.tunnel.json` không được commit (đã có trong `.gitignore`).

### A7. Nếu có lỗi
| Hiện tượng | Cách xử lý |
|---|---|
| `Backend chua chay o http://localhost:8080` | Chưa bật backend ở IntelliJ (bước A2.2). |
| `Khong tim thay flutter` | Thêm `D:\flutter\bin` vào PATH rồi mở lại cửa sổ. |
| `Khong tim thay cloudflared.exe` | Xem A1, đặt file vào `D:\Tools\cloudflared\`. |
| `Cong 8000 dang bi chiem` | Chương trình khác dùng cổng 8000. Tắt nó, hoặc chạy `start-demo.cmd -Port 8001`. |
| Link mở ra trang báo lỗi **1033 / 502** | Tunnel hoặc máy chủ demo đã chết. Chạy lại `start-demo.cmd` rồi gửi **link mới**. |
| Web trắng / không tải | Chạy `start-demo.cmd -Rebuild`. |
| `run-android`: `Khong goi duoc .../api/categories` | PC nhà đã tắt demo, mất mạng, hoặc link đã đổi. Lấy link mới rồi chạy lại. |
| `run-android`: `Khong co may ao nao` | Laptop chưa có máy ảo: Android Studio → Device Manager → Create Virtual Device. Hoặc bấm nút ▶ bật sẵn máy ảo trong Android Studio rồi chạy lại script. |
| Bạn bè báo "Lỗi kết nối" | Xem cửa sổ `start-demo` có dòng đỏ "backend khong tra loi" không, và xem `demo\logs\proxy.log`, `demo\logs\tunnel.log`. |

---

## B. Dành cho BẠN BÈ (ở nơi khác) — gửi nguyên mục này

**Bạn cần:** một trình duyệt (Chrome / Safari / Edge) trên điện thoại hoặc máy tính, và **link do Khoa gửi**. Không cần cài app.

1. Mở link `https://….trycloudflare.com`. Lần đầu tải hơi chậm (vài giây tới ~20 giây) vì web khá nặng, đợi tới khi hiện trang **ReBook**.
2. Bấm **Đăng nhập** và dùng **một trong các tài khoản sau** (mật khẩu chung `Rebook@123`):

   | Tài khoản | Vai trò |
   |---|---|
   | `buyer1@rebook.vn`, `buyer2@rebook.vn`, `buyer3@rebook.vn` | Người mua (đã có ví, đã đăng ký phiên đấu giá mẫu) |
   | `seller1@rebook.vn` | Người bán (có shop) |

   Khoa sẽ cho biết **mỗi người dùng tài khoản nào** để không đạp lên nhau.
3. Gợi ý thử:
   - **Mua sách**: chọn sách → Thêm vào giỏ → Thanh toán bằng **Ví ReBook**.
   - **Đấu giá**: vào mục **Đấu giá** → chọn phiên → **Đăng ký + đặt cọc** (làm trước giờ bắt đầu!) → đến giờ vào **phòng đấu giá** → bấm **Trả giá**, hoặc **Trả giá tự động**.
   - **Thông báo**: chuông ở thanh bên (hoặc tab Thông báo trên điện thoại).
4. **Lưu ý:**
   - Đây là bản demo, dữ liệu có thể bị Khoa xóa làm lại bất cứ lúc nào.
   - **Đừng tự đăng ký tài khoản mới**: mã xác thực OTP chưa gửi qua email thật nên bạn sẽ không nhận được mã.
   - **Đừng đổi mật khẩu** các tài khoản chung.
   - Điện thoại: dùng **chế độ dọc**, đừng mở link trong trình duyệt nhúng của Zalo/Messenger (nếu trang trắng, bấm "Mở bằng trình duyệt").
   - Link **hết hạn** khi Khoa tắt máy chủ; lần sau Khoa gửi link mới.
5. **Gặp lỗi**: chụp màn hình gửi Khoa, kèm giờ và bạn đang làm gì. Thử tải lại trang (kéo xuống hoặc F5) trước tiên.

---

## C. Ghi chú kỹ thuật (nếu cần giải thích)

- `apps/frontend/tool/demo_server.dart`: máy chủ Dart thuần, phục vụ `build/web` + chuyển tiếp `/api` → backend (bỏ tiền tố) và `/ws` → backend WebSocket. Bỏ header `Origin` khi chuyển tiếp để khỏi vướng CORS.
- Web build bằng `env/tunnel.json` (`API_BASE_URL=/api`, `WS_BASE_URL=/ws`, đường dẫn **tương đối**), nên đổi link tunnel **không cần build lại**.
- `RealtimeClient` tự dựng `wss://<host>/ws/...` từ địa chỉ trang đang mở khi `WS_BASE_URL` là đường dẫn tương đối. Máy chủ demo ping 25 giây một lần để Cloudflare không cắt kết nối đấu giá lúc im lặng.
- Backend **không phải sửa gì**, vẫn chạy profile `dev` như cũ. Vì là profile dev nên có nút giả lập thanh toán và OTP trả thẳng trong phản hồi API; chỉ chia sẻ link cho người quen, và tắt khi xong.
