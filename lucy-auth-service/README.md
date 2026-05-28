# Lucy Auth Service

.NET 8 Web API cho Dev 6: register/login/me bang bang `users` trong `LucyDB`, verify mat khau BCrypt va cap JWT Bearer token.

## Endpoints

- `POST /api/auth/register`: tao user moi, hash password bang BCrypt, tra JWT.
- `POST /api/auth/login`: dang nhap user active, verify BCrypt, tra JWT.
- `GET /api/auth/me`: tra thong tin user hien tai tu Bearer token.
- `POST /api/auth/anonymous-room-access`: Dev 2, cap realtime token va persona an danh.
- `POST /api/wallet/gift`: Dev 2, gui gift co idempotency va wallet ledger.
- `GET /health`: healthcheck chuan cua ASP.NET Core.
- `GET /health/details`: healthcheck JSON cho demo nhanh.
- `GET /swagger`: Swagger UI co nut Authorize Bearer token.

## Register

Request:

```json
{
  "email": "lucy@example.com",
  "password": "Password123",
  "role": "LUCY",
  "languageId": 1,
  "displayName": "Lucy",
  "avatarUrl": null,
  "isAnonymous": true,
  "bio": null
}
```

Role hop le: `LUCY`, `Pro`, `Super`. Service cung chap nhan `PRO` va `SUPER`, sau do normalize ve `Pro` va `Super`.

## Login

Request:

```json
{
  "email": "lucy@example.com",
  "password": "your-password"
}
```

Response:

```json
{
  "accessToken": "<jwt>",
  "tokenType": "Bearer",
  "expiresAt": "2026-05-22T08:00:00+00:00",
  "user": {
    "id": 1,
    "email": "lucy@example.com",
    "role": "LUCY",
    "languageId": 1,
    "displayName": "Lucy",
    "avatarUrl": null,
    "isAnonymous": true,
    "balance": 0,
    "createdAt": "2026-05-22T06:00:00+00:00"
  }
}
```

JWT co claim `Role`, `role` va `ClaimTypes.Role`, gia tri hop le cho login la `LUCY`, `Pro`, `Super`.

## Me

Header:

```text
Authorization: Bearer <accessToken>
```

Response:

```json
{
  "id": 1,
  "email": "lucy@example.com",
  "role": "LUCY",
  "languageId": 1,
  "displayName": "Lucy",
  "avatarUrl": null,
  "isAnonymous": true,
  "balance": 0,
  "createdAt": "2026-05-22T06:00:00+00:00"
}
```

## Error format

Validation va auth errors tra ve ProblemDetails:

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "Validation failed.",
  "status": 400,
  "detail": "One or more request fields are invalid.",
  "errors": {
    "email": ["The Email field is not a valid e-mail address."]
  }
}
```

## Chay service

1. Cai .NET SDK 8.
2. Cap nhat `ConnectionStrings:LucyDb` va `Jwt:Secret` trong `appsettings.json` hoac environment variables.
3. Chay:

```powershell
dotnet restore
dotnet run --project Lucy.AuthService.csproj
```

Mo Swagger:

```text
http://localhost:5086/swagger
```

## Database

Schema goc da co bang `users` voi `is_anonymous BIT DEFAULT 1`, `password_hash`, `role`.
File `database/001_users_auth_contract.sql` la script bo tro rieng cho auth service, khong thay doi file SQL goc.
Dev 2 bo sung `database/002_persona_realtime_contract.sql` va `database/003_wallet_gift_contract.sql`.
Dev 6 van phu trach register wallet, `GET /api/wallet/balance`, va deposit.

Tao hash BCrypt mau:

```csharp
var hasher = new BCryptPasswordHasher();
var hash = hasher.Hash("your-password");
```
