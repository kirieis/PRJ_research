# Lucy Auth Service

.NET 8 Web API cho Dev 6: dang nhap bang bang `users` trong `LucyDB`, verify mat khau BCrypt va cap JWT Bearer token.

## Endpoint

`POST /api/auth/login`

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

JWT co claim `Role` va `ClaimTypes.Role`, gia tri hop le cho login la `LUCY`, `PRO`, `SUPER`.

## Wallet endpoints

All wallet endpoints require `Authorization: Bearer <accessToken>`.

- `GET /api/wallet/balance`
- `POST /api/wallet/deposit`
- `POST /api/wallet/gift`

Gift request:

```json
{
  "receiverUserId": 2,
  "amount": 10,
  "giftType": "heart",
  "roomId": 1,
  "idempotencyKey": "gift-unique-client-key"
}
```

Deposit request:

```json
{
  "amount": 100,
  "idempotencyKey": "deposit-unique-client-key",
  "description": "local test top-up"
}
```

Both flows run inside a SQL `SERIALIZABLE` transaction, lock wallet rows with `UPDLOCK/HOLDLOCK`, write immutable ledger entries, and return the committed `transactionId`.

## Chay service

1. Cai .NET SDK 8.
2. Cap nhat `ConnectionStrings:LucyDb` va `Jwt:Secret` trong `appsettings.json` hoac environment variables.
3. Chay:

```powershell
dotnet restore
dotnet run --project Lucy.AuthService.csproj
```

## Database

Schema goc da co bang `users` voi `is_anonymous BIT DEFAULT 1`, `password_hash`, `role`.
File `database/001_users_auth_contract.sql` la script bo tro rieng cho auth service, khong thay doi file SQL goc.

Run wallet/audit migrations in order:

```text
database/003_wallets.sql
database/004_wallet_transactions.sql
database/005_wallet_ledger.sql
database/006_audit_logs.sql
../data/SQL_database/002_week10_completion_schema.sql
../data/SQL_database/003_seed_sample_levels.sql
```

Tao hash BCrypt mau:

```csharp
var hasher = new BCryptPasswordHasher();
var hash = hasher.Hash("your-password");
```
