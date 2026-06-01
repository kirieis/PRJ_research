# 📋 Lưu ý cho Dev 4 (Node.js + Agora + Socket.io)
> Tổng hợp các điểm cần chú ý khi tích hợp với API của Dev 3 (Spring Boot)
> Cập nhật: Tuần 6-7

---

## 1. Base URL

Tất cả API của Dev 3 đều dùng prefix `/api/v1/`:

```
http://localhost:8080/api/v1/rooms
http://localhost:8080/api/v1/rooms/1/moderator-hints
```

---

## 2. Các endpoint Dev 4 sẽ gọi thường xuyên

### Khi tạo phòng mới
```
POST /api/v1/rooms
Body: { "levelId": 1 }
```

### Khi user join phòng
```
GET /api/v1/rooms/{id}
```
Trả về thông tin phòng, bao gồm `currentSubLevelId` hiện tại.

### Khi cần danh sách sub-level của level
```
GET /api/v1/levels/{levelId}/sub-levels
```

### Khi chuyển sub-level (mỗi 10/15/20 phút)
```
PATCH /api/v1/rooms/{id}/current-sub-level?subLevelId=3
```
Truyền `subLevelId` qua **query parameter**, không phải request body:
```javascript
// Node.js axios
await axios.patch(`/api/v1/rooms/${roomId}/current-sub-level`, null, {
    params: { subLevelId: 3 }
});
```
Lưu ý truyền `null` cho body vì không có request body — chỉ có query param.

### Khi cần câu hỏi gợi ý cho Moderator
```
GET /api/v1/rooms/{id}/moderator-hints?triggerMinute=5
```
Dev 4 tick timer mỗi phút → gọi endpoint này với `triggerMinute` tương ứng → Stored Procedure của Dev 2 trả về tối đa 3 câu gợi ý → Dev 4 emit qua Socket.io lên màn hình Pro/Moderator.

`triggerMinute` là **optional**:
- Có `triggerMinute` → trả về câu hỏi đúng mốc phút đó (tối đa 3 câu)
- Không có `triggerMinute` → trả về toàn bộ câu hỏi của sub-level hiện tại

### Khi kết thúc phòng
```
PATCH /api/v1/rooms/{id}/status
```

---

## 3. Response format quan trọng

### Room response
```json
{
  "id": 1,
  "levelId": 1,
  "status": "LIVE",
  "currentSubLevelId": 3,
  "createdAt": "2026-05-26T08:00:00.000Z"
}
```
`status` có 3 giá trị: `LIVE` | `ENDED` | `SCHEDULED`

### Moderator hints response
```json
{
  "roomId": 1,
  "currentSubLevelId": 3,
  "subLevelTopicName": "Greeting Strangers",
  "triggerMinute": 5,
  "hints": [
    { "id": 1, "questionText": "How would you greet a stranger?", "triggerMinute": 5, "orderIndex": 1 },
    { "id": 2, "questionText": "Practice introducing yourself.", "triggerMinute": 5, "orderIndex": 2 }
  ]
}
```

---

## 4. Error format thống nhất

Mọi lỗi từ Dev 3 đều trả về format:
```json
{
  "statusCode": 404,
  "error": "Not Found",
  "message": "Room not found: 99",
  "timestamp": "2026-05-26T08:00:00.000Z"
}
```
Handle theo `statusCode`, không phải HTTP status code thuần.

---

## 5. File tĩnh (room_materials)

Khi Moderator ghim tài liệu, `fileUrl` trong response là URL trực tiếp có thể truy cập:
```
http://localhost:8080/files/abc-123.pdf
```
Dev 4 có thể emit URL này qua Socket.io để client hiển thị luôn, không cần gọi thêm API.

---

## 6. Flow tổng thể Dev 3 ↔ Dev 4

```
[Phòng bắt đầu]
Dev 4 → POST /api/v1/rooms                              → Tạo phòng, lấy roomId

[User join]
Dev 4 → GET  /api/v1/rooms/{id}                         → Lấy currentSubLevelId
Dev 4 → GET  /api/v1/levels/{levelId}/sub-levels        → Lấy danh sách sub-level

[Mỗi phút]
Dev 4 timer tick → GET /api/v1/rooms/{id}/moderator-hints?triggerMinute=X
                 → Socket.io emit hints lên màn hình Moderator

[Hết sub-level]
Dev 4 → PATCH /api/v1/rooms/{id}/current-sub-level?subLevelId=X
                                                        → Dev 3 cập nhật DB

[Kết thúc phòng]
Dev 4 → PATCH /api/v1/rooms/{id}/status                → Dev 3 đóng phòng (ENDED)
```

---

## 7. Lưu ý kỹ thuật

- Tất cả ID đều là **Long/Integer**, không phải String — tránh truyền `"1"` thay vì `1`
- `triggerMinute` trong `moderator-hints` là **optional** — không truyền thì nhận toàn bộ câu hỏi của sub-level
- File upload `room_materials` giới hạn **20MB**, chỉ nhận `PDF` / `DOCX` / `IMAGE`
- Swagger đầy đủ tại `http://localhost:8080/swagger-ui.html` — có thể test trực tiếp trên đó

---

*File này do Dev 3 tổng hợp — cập nhật khi có thay đổi API*
