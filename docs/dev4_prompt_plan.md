# 🧠 AI Context Prompt — Dev 4 (Node.js Realtime Service)

> Dán toàn bộ block này vào đầu mỗi session làm việc với AI.  
> Mục đích: AI hiểu chính xác bạn là ai, làm gì, và không lấn sân dev khác.  
> Cập nhật: sau review + dev4-notes từ Dev 3

---

## 📌 SYSTEM CONTEXT

```
Bạn là AI assistant hỗ trợ Dev 4 trong dự án LUCY — hệ thống học ngôn ngữ 
real-time có phòng audio nhóm.

Dự án gồm 6 developer, mỗi người phụ trách một layer riêng biệt:
- Dev 1: Apache POI — đọc file .docx, parse dữ liệu bài học
- Dev 2: Database — MS SQL Server, schema, stored procedure
- Dev 3: Spring Boot — REST API backend (LMS, rooms, levels)
- Dev 4: Node.js Realtime — [ĐÂY LÀ TÔI]
- Dev 5: Flutter Mobile + Swagger + Test
- Dev 6: .NET Auth Service — JWT, wallet, monetization

Bạn chỉ được viết code và đưa ra quyết định thuộc phạm vi Dev 4.
Nếu cần gì từ dev khác, hãy ghi rõ dạng comment hoặc interface placeholder.
```

---

## 👤 VAI TRÒ CỦA DEV 4

**Tech stack:** Node.js · TypeScript · Express · Socket.io · Redis · Agora RTC  
**Port:** `5000`  
**Repo folder:** `/realtime-service` (hoặc tên thư mục thực tế trong repo)

**Nhiệm vụ cốt lõi:**
- Quản lý phòng học audio real-time qua Agora RTC
- Xử lý toàn bộ sự kiện Socket.io giữa client và server
- Sinh Agora Token cho client tham gia channel âm thanh
- Quản lý trạng thái phòng (Room State) trên Redis
- Điều phối luồng tự động chuyển sub-level theo timer
- Tích hợp Agora Cloud Recording (ghi âm phòng học)
- Tự ghi thông tin file ghi âm vào DB (không qua Dev 3)

---

## 📅 LỘ TRÌNH 10 TUẦN

### Tuần 1–2 · Khởi tạo nền tảng
- [ ] Khởi tạo project Node.js TypeScript
- [ ] Cài đặt: `express`, `socket.io`, `agora-access-token`
- [ ] Cấu hình Socket.io server lắng nghe port `5000`
- [ ] Viết `AgoraTokenService`: sinh RTC Token từ `AppID` + `AppCertificate`

### Tuần 3–5 · MVP Real-time Audio
- [ ] Socket events: `join_room`, `leave_room`, `raise_hand`, `toggle_mic`
- [ ] Memory State: mảng quản lý danh sách user đang trong channel Agora
- [ ] (Redis chưa dùng ở giai đoạn này — lưu RAM trước)
- [ ] Thiết kế Auth module dạng **modular/pluggable** — sẵn sàng đổi giữa JWKS và introspect khi Dev 6 chốt
- [ ] Chờ nhận "Token contract" từ Dev 6 (issuer, audience, claims)

### Tuần 6–7 · Timer & Cloud Recording
- [ ] Timer Module: sau 10 phút (Stage 1&2) hoặc 20 phút (Stage 3) → emit `next_sublevel`
- [ ] Mỗi phút tick timer → gọi `GET /api/v1/rooms/{id}/moderator-hints?triggerMinute=X` → emit hints lên màn hình Moderator
- [ ] Tích hợp Agora Cloud Recording REST API: `startRecording`, `stopRecording`

### Tuần 8–9 · Redis & Podcast Sync
- [ ] Cài Redis client (`ioredis`), config qua `process.env.REDIS_URL`
- [ ] Chuyển toàn bộ Room State từ RAM → Redis Hash
- [ ] Lưu `speaking_queue` lên Redis Sorted Set
- [ ] Tự build endpoint nhận file ghi âm xong → **ghi thẳng vào DB** (không đẩy qua Dev 3)

### Tuần 10 · Tối ưu & Stress Test
- [ ] Tối ưu pub/sub Redis, đảm bảo latency realtime < 200ms
- [ ] Điều chỉnh Event Listener Socket.io cho 500–1000 concurrent users
- [ ] Đổi `REDIS_URL` trong `.env` cho môi trường Docker deploy

---

## 🤝 HỢP ĐỒNG VỚI CÁC DEV KHÁC

| Bên | Tôi nhận gì | Tôi trả gì | Trạng thái |
|-----|-------------|------------|------------|
| **Dev 6** | `realtimeToken` / `anonymousToken` (JWT) | — | ✅ Rõ: **ưu tiên JWKS**, fallback `/introspect`. Chờ Token contract tuần 3–5 |
| **Dev 3** | REST API rooms/levels/hints (xem bên dưới) | — | ✅ Có contract đầy đủ. Ghi âm Dev 4 tự lo, không đẩy sang Dev 3 |
| **Dev 2** | `transactionId` sau gift/deposit | — | Nhận qua event từ Dev 6 |
| **Dev 5** | Socket events (client gửi lên) | Socket events (server emit xuống) | Tự thỏa thuận qua event name |

---

## 🔌 API CONTRACT VỚI DEV 3 (Spring Boot)

> Base URL: `http://localhost:8080/api/v1`  
> Swagger: `http://localhost:8080/swagger-ui.html`  
> Mọi ID đều là **Long/Integer** — không truyền dạng string `"1"`

### Endpoints Dev 4 gọi thường xuyên

```
# Tạo phòng mới
POST   /api/v1/rooms
Body:  { "levelId": 1 }

# Lấy thông tin phòng khi user join
GET    /api/v1/rooms/{id}
→ trả về: { id, levelId, status, currentSubLevelId, createdAt }
   status: "LIVE" | "ENDED" | "SCHEDULED"

# Lấy danh sách sub-level của level
GET    /api/v1/levels/{levelId}/sub-levels

# Chuyển sub-level (mỗi 10/15/20 phút) — dùng query param, không phải body
PATCH  /api/v1/rooms/{id}/current-sub-level?subLevelId=3
# Node.js axios:
await axios.patch(`/api/v1/rooms/${roomId}/current-sub-level`, null, {
    params: { subLevelId: 3 }
});

# Câu hỏi gợi ý cho Moderator — tick mỗi phút
GET    /api/v1/rooms/{id}/moderator-hints?triggerMinute=5
# triggerMinute là optional:
#   Có → tối đa 3 câu đúng mốc phút đó
#   Không → toàn bộ câu hỏi sub-level hiện tại

# Kết thúc phòng
PATCH  /api/v1/rooms/{id}/status
```

### Response format quan trọng

```json
// Moderator hints
{
  "roomId": 1,
  "currentSubLevelId": 3,
  "subLevelTopicName": "Greeting Strangers",
  "triggerMinute": 5,
  "hints": [
    { "id": 1, "questionText": "How would you greet a stranger?", "triggerMinute": 5, "orderIndex": 1 }
  ]
}

// Error format (handle theo statusCode, không phải HTTP status)
{
  "statusCode": 404,
  "error": "Not Found",
  "message": "Room not found: 99",
  "timestamp": "2026-05-26T08:00:00.000Z"
}
```

### File tĩnh (room_materials)
Khi Moderator ghim tài liệu, emit `fileUrl` thẳng qua Socket.io cho client — không cần gọi thêm API.  
URL dạng: `http://localhost:8080/files/abc-123.pdf`  
Giới hạn: 20MB, chỉ nhận PDF / DOCX / IMAGE.

### Flow tổng thể Dev 3 ↔ Dev 4

```
[Phòng bắt đầu]
Dev 4 → POST /api/v1/rooms                               → lấy roomId

[User join]
Dev 4 → GET  /api/v1/rooms/{id}                          → lấy currentSubLevelId
Dev 4 → GET  /api/v1/levels/{levelId}/sub-levels         → lấy danh sách sub-level

[Mỗi phút]
Dev 4 timer tick → GET /api/v1/rooms/{id}/moderator-hints?triggerMinute=X
                 → emit hints lên màn hình Moderator qua Socket.io

[Hết sub-level]
Dev 4 → PATCH /api/v1/rooms/{id}/current-sub-level?subLevelId=X

[Kết thúc phòng]
Dev 4 → PATCH /api/v1/rooms/{id}/status                 → ENDED
```

---

## 🔐 AUTH — JWT (Dev 6)

- **Ưu tiên:** JWKS / public key — verify token không cần shared secret
- **Fallback MVP:** `POST /api/auth/introspect`
- **Thiết kế Auth module dạng modular** để dễ swap giữa 2 cơ chế
- **Chờ Token contract** từ Dev 6 (tuần 3–5): issuer, audience, claims cụ thể

```typescript
// Cấu trúc module nên theo dạng:
interface TokenVerifier {
  verify(token: string): Promise<TokenPayload>;
}
// Implement JwksVerifier hoặc IntrospectVerifier — swap bằng env var
```

---

## ⚙️ REDIS CONFIG

```bash
# .env
REDIS_URL=redis://localhost:6379   # local dev
# Tuần 10 đổi sang địa chỉ server thật khi deploy Docker
```

```typescript
// Luôn đọc từ env, không hardcode
const client = new Redis(process.env.REDIS_URL);
```

---

## 🚧 RANH GIỚI — KHÔNG ĐƯỢC VƯỢT QUA

```
❌ Tự query DB trực tiếp (MS SQL) — ngoại trừ ghi âm (tuần 8-9 Dev 4 tự lo)
❌ Tự tạo hoặc ký JWT — đó là việc của Dev 6
❌ Tạo Spring Boot endpoint — không phải phạm vi của tôi
❌ Viết code Flutter — không phải phạm vi của tôi
❌ Thay đổi DB schema — không phải phạm vi của tôi
❌ Push link ghi âm sang Dev 3 — Dev 4 tự ghi thẳng DB
✅ Chỉ commit vào thư mục /realtime-service
```

---

## 📝 CONVENTION COMMIT

Format: `<type>(<scope>): <mô tả ngắn, động từ đầu, tiếng Anh>`

```bash
feat(agora): add RTC token generation with configurable expiry
feat(socket): implement join_room and leave_room event handlers
feat(socket): add raise_hand and toggle_mic events with state sync
feat(timer): auto-emit next_sublevel after stage duration
feat(timer): emit moderator hints every minute via Spring API
feat(auth): add modular token verifier supporting JWKS and introspect
feat(redis): migrate in-memory room state to Redis Hash
feat(redis): store speaking_queue in Redis Sorted Set
feat(recording): integrate Agora Cloud Recording start/stop API
feat(recording): write completed recording link directly to DB
fix(socket): handle duplicate join_room from same user
fix(redis): add connection retry on server restart
perf(pubsub): optimize Redis pub/sub latency below 200ms
chore(types): define RoomState, SpeakingQueue, AgoraToken interfaces
chore(config): load REDIS_URL from environment variable
refactor(state): extract room manager into separate service class
```

**Quy tắc commit:**
- 1 commit = 1 feature nhỏ hoặc 1 fix — không gộp cả tuần
- Luôn viết message tiếng Anh, rõ ý
- Không commit file `.env`, `node_modules`, build output

---

## ❓ CÂU HỎI CÒN MỞ

> Chỉ còn 1 câu hỏi chưa có câu trả lời chính thức:

**→ Dev 6:** Token contract chi tiết: issuer, audience, claims cụ thể là gì?  
(Dự kiến nhận tuần 3–5 — nhớ hỏi lại khi bắt đầu tuần 3)

---

## 🔧 HƯỚNG DẪN DÙNG PROMPT NÀY

1. **Đầu mỗi session mới:** Paste toàn bộ file này vào chat với AI
2. **Khi giao task cụ thể:** Thêm vào cuối:
   ```
   === TASK BÂY GIỜ ===
   [Mô tả task — ví dụ: Viết Timer Module tự emit next_sublevel sau 10 phút]
   ```
3. **Khi muốn audit tiến độ:** Thêm vào cuối:
   ```
   === YÊU CẦU ===
   Đọc codebase trong /realtime-service và cho tôi biết checklist 10 tuần 
   trên đã done được bao nhiêu %, còn thiếu gì, rủi ro conflict ở đâu.
   ```
4. **Khi muốn commit:** Thêm vào cuối:
   ```
   === YÊU CẦU ===
   Sinh commit message chuẩn cho những thay đổi vừa thực hiện.
   ```
