# Kế hoạch chi tiết theo tuần (10 tuần)

## Tuần 1-2: Thiết lập nền tảng & Định hình Dữ liệu

### Dev 1 (Apache POI)
- Tạo class `DocxParserService` sử dụng thư viện `org.apache.poi.xwpf.usermodel`.
- Viết logic đọc bảng (Table) và cấu trúc Paragraph để bóc tách text từ 8 file `.docx` mẫu.
- Xây dựng thuật toán gom cụm dữ liệu theo phân cấp hệ thống: tách bộ từ vựng, câu hỏi gợi ý (`AISupportQuestions`) và bài tập (`QuizQuestions`).

### Dev 2 (Database)
- Cài đặt MS SQL Server 2019, tạo Database `LucyDB`.
- Tạo Script tạo bảng (DDL) với khóa ngoại ràng buộc: `Languages` -> `Stages` -> `Levels` -> `SubLevels`.
- Thiết lập Index trên các cột tìm kiếm thường xuyên: `LanguageCode`, `LevelNumber`, `SubLevelID`.

### Dev 3 (Spring APIs)
- Khởi tạo cấu trúc dự án Spring Boot, khai báo dependency: `Spring Web`, `Spring Data JPA`, `SQL Server Driver`.
- Cấu hình file `application.properties` kết nối tới `LucyDB`.
- Map các lớp `@Entity` (`Language`, `Stage`, `Level`, `SubLevel`) tương ứng với Database của Dev 2.

### Dev 4 (Node.js Realtime)
- Khởi tạo Project Node.js với TypeScript, cài đặt `express`, `socket.io`, và `agora-access-token`.
- Cấu hình Server Socket.io lắng nghe trên port `5000`.
- Viết module `AgoraTokenService` sinh `RTC Token` dựa trên `AppID` và `AppCertificate`.

### Dev 5 (Mobile, Test & Swagger)
- Khởi tạo project Flutter, cài đặt BLoC/Provider, `dio`, và `socket_io_client`.
- Xây dựng Base UI: Màn hình Splash, Walkthrough, và bộ Component Core (Button, Input, Theme màu).
- Viết file Swagger `api-docs.yaml` mô tả cấu trúc API GET `/api/levels` và POST `/api/import/docx`.

### Dev 6 (.NET Auth)
- Khởi tạo giải pháp .NET Core 8 Web API, cài đặt `Microsoft.AspNetCore.Authentication.JwtBearer`.
- Thiết kế bảng `Users` với trường `IsAnonymous` (Boolean) và cơ chế mã hóa mật khẩu BCrypt.
- Viết Endpoint `POST /api/auth/login` cấp Token JWT chứa `Role` (LUCY, Pro, Super).

---

## Tuần 3-5: Hoàn thiện MVP Real-time Audio

### Dev 1 (Apache POI)
- Viết hàm Validation check định dạng file Word trước khi import (bắt lỗi lệch cấu trúc sub-level).
- Tích hợp hàm Parser vào Service để chuyển đổi dữ liệu thành các List Object trong Java.
- Xây dựng logic đẩy toàn bộ dữ liệu 100 levels đã bóc tách từ file Word vào Database thông qua EntityManager.

### Dev 2 (Database)
- Bổ sung bảng `QuizQuestions` (chứa mảng câu hỏi lựa chọn) và `AISupportQuestions` (câu gợi ý thảo luận theo phút).
- Tạo bảng `Rooms` để lưu vết trạng thái phòng: `RoomID`, `HostID`, `CurrentLevelID`, `AgoraChannelName`, `Status` (Active/Ended).

### Dev 3 (Spring APIs)
- Viết Endpoint `POST /api/import/docx` nhận file từ MultipartFile, gọi Service của Dev 1 để thực thi.
- Viết cụm REST API: `GET /api/levels`, `GET /api/levels/{id}/sublevels` và `GET /api/sublevels/{id}/questions` để trả về cấu trúc 6 phần học của mỗi Level.

### Dev 4 (Node.js Realtime)
- Viết các sự kiện Socket.io: `join_room`, `leave_room`, `raise_hand` (giơ tay), `toggle_mic`.
- Xây dựng mảng quản lý Memory State trên server để lưu danh sách User đang trong Channel âm thanh của Agora.

### Dev 5 (Mobile, Test & Swagger)
- Tích hợp SDK `agora_rtc_engine` vào Flutter.
- Xây dựng giao diện phòng học Audio ẩn danh (Hiển thị các Avatar Persona ảo, hiệu ứng sóng âm khi nói).
- Kết nối Client Socket.io vào Server Dev 4 để xử lý sự kiện bật tắt mic và hiển thị danh sách hàng đợi phát biểu.

### Dev 6 (.NET Auth)
- Xây dựng Middleware xác thực JWT trên Node.js (Dev 4 sẽ gọi qua .NET hoặc giải mã trực tiếp bằng Key chung).
- Viết logic xử lý Profile ẩn danh: Tự động gán DisplayName ngẫu nhiên (ví dụ: "Anonymous Fox") nếu user chọn chế độ ẩn danh khi vào phòng.

---

## Tuần 6-7: Hệ thống Quản lý LMS & Luồng Tự động

### Dev 1 & Dev 2 (Data & DB)
- Thiết kế bảng `RoomResources` hỗ trợ lưu URL slide hoặc tài liệu hình ảnh mà Host ghim lên.
- Tạo Stored Procedure tối ưu việc quét và lấy nhanh bộ câu hỏi gợi ý theo mốc thời gian (`TriggerMinute`).

### Dev 3 (Spring APIs)
- Viết API `POST /api/rooms/{id}/pin-resource` cho phép Mentor ghim tài liệu trực tiếp vào phòng.
- Viết API `GET /api/rooms/{id}/moderator-hints` lấy danh sách câu hỏi hỗ trợ AI gợi ý hiển thị lên màn hình Moderator theo tiến độ phòng.

### Dev 4 (Node.js Realtime)
- Xây dựng bộ đếm thời gian (Timer Module): Sau mỗi 10 phút (Stage 1&2) hoặc 20 phút (Stage 3), server tự động phát sự kiện `next_sublevel` tới toàn bộ Client.
- Tích hợp luồng ghi âm phòng học (Agora Cloud Recording), gọi REST API của Agora để bắt đầu/dừng ghi âm.

### Dev 5 (Mobile, Test & Swagger)
- Xây dựng giao diện "Dashboard dành cho Pro" (Nút chuyển Sub-level thủ công, danh sách duyệt người nói, khu vực ghim tài liệu).
- Viết BLoC quản lý trạng thái đếm ngược thời gian của Sub-level trên App.
- Cập nhật Swagger cho toàn bộ các API phòng học và ghim tài liệu mới.

### Dev 6 (.NET Auth)
- Khởi tạo cấu trúc DB cho Module tài chính: bảng `Wallets` (Ví) và `Transactions` (Giao dịch).
- Viết các API nội bộ kiểm tra số dư và khởi tạo ví khi User mới đăng ký thành công.

---

## Tuần 8-9: Tích hợp Ví, Quà tặng & Tối ưu Redis

### Dev 1, Dev 2, Dev 3 (Java Team)
- Hỗ trợ rà soát, viết các hàm Query tối ưu bằng Native Query thay vì JPA thuần cho các màn hình danh sách Level lớn để tránh n+1 query.
- Đóng gói hoàn thiện Module LMS chuyển giao mã nguồn sạch cho việc cấu hình hệ thống.

### Dev 4 (Node.js Realtime)
- Cài đặt Redis Client trên Node.js. Chuyển toàn bộ dữ liệu State Room lưu trong RAM ở tuần trước sang cấu trúc `Hash` và `Sorted Set` của Redis.
- Xử lý lưu trữ thông tin phòng active, hàng đợi giơ tay (`speaking_queue`) lên Redis để tránh mất dữ liệu khi Node server restart.
- Xây dựng Endpoint xử lý file ghi âm hoàn thiện, đồng bộ link file `.mp3`/`.m3u8` (Podcast) lưu về DB cho tài khoản Super.

### Dev 5 (Mobile, Test & Swagger)
- Xây dựng màn hình "Tủ sách Podcast": Danh sách các file ghi âm của tài khoản Super, tích hợp trình phát Audio phát trực tuyến.
- Xây dựng giao diện nạp tiền và nút "Tặng quà" (Animation hiệu ứng bay lên khi bấm tặng hoa/quà cho Host).
- Viết Automation Test Script kiểm thử luồng Socket khi có 50 kết nối ảo gửi sự kiện cùng lúc.

### Dev 6 (.NET Payment)
- Viết API giao dịch: `POST /api/wallet/deposit` (Nạp tiền mô phỏng) và `POST /api/wallet/gift` (Trừ tiền người tặng, cộng tiền người nhận).
- Xử lý tính toàn vẹn giao dịch bằng `Acid Transaction` trong .NET để không bị lỗi đồng thì (Race Condition) khi nhiều người tặng quà cùng giây.

---

## Tuần 10: Tối ưu hóa, Stress Test & Đóng gói

### Dev 5 (Lead Test & Swagger)
- Sử dụng công cụ JMeter hoặc Locust viết kịch bản Stress Test giả lập luồng tải từ 500-1000 người dùng đồng thời gọi vào cụm API Backend và kết nối Socket.
- Xuất báo cáo Performance (Latency, CPU, RAM) và tổng hợp lỗi Crash trên Mobile.

### Dev 1, 2, 3 (Java Backend)
- Dựa trên kết quả Stress Test, tối ưu hồ chứa kết nối (HikariCP Connection Pool). Fix các lỗi deadlock CSDL nếu có.

### Dev 4 (Node.js Realtime)
- Điều chỉnh cấu hình Event Listener của Socket.io, tối ưu hóa các hàm pub/sub qua Redis để tăng tốc độ phản hồi lệnh Realtime dưới 200ms.

### Dev 6 (.NET)
- Rà soát bảo mật mã hóa JWT, kiểm tra lỗi rò rỉ token và đóng gói Service sẵn sàng deploy Docker.