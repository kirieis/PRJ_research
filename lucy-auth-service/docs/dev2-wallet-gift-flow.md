# Dev 2 Wallet And Gift Flow

Scope tai lieu nay cover phan Dev 2 tuan 6-10.

## Database

Script `database/003_wallet_gift_contract.sql` tao them:

- `wallets`: so du hien tai theo user.
- `wallet_transactions`: transaction cap cao, co `idempotency_key`.
- `wallet_ledger`: debit/credit ledger, ghi `balance_before` va `balance_after`.

Khong thay the API wallet cua Dev 6. Dev 6 van phu trach khoi tao wallet khi register, `GET /api/wallet/balance`, va deposit.

## Gift API

`POST /api/wallet/gift`

Authorization: `Bearer <accessToken>`

Request:

```json
{
  "receiverId": 2,
  "amount": 10,
  "giftType": "rose",
  "roomId": 42,
  "idempotencyKey": "mobile-request-uuid-001",
  "message": "Great speaking practice"
}
```

Response:

```json
{
  "transactionId": 1001,
  "senderLedgerId": 5001,
  "receiverLedgerId": 5002,
  "senderId": 1,
  "receiverId": 2,
  "roomId": 42,
  "giftType": "rose",
  "amount": 10,
  "senderBalanceBefore": 100,
  "senderBalanceAfter": 90,
  "receiverBalanceBefore": 20,
  "receiverBalanceAfter": 30,
  "status": "COMPLETED",
  "isIdempotentReplay": false,
  "createdAt": "2026-05-28T08:00:00+00:00"
}
```

## Safety Rules

- Idempotency key unique theo `(sender_id, idempotency_key)`.
- Transfer chay trong SQL transaction `Serializable`.
- Sender va receiver wallet duoc lock theo thu tu `user_id` voi `UPDLOCK, HOLDLOCK`.
- Ledger ghi debit va credit trong cung transaction voi balance update.
- `roomId` neu gui len se duoc validate ton tai truoc khi ghi transaction.
- API tra ve `transactionId` de Node/Mobile hien thi realtime.

## Week 10 Audit

- Exception khong log PII nhu email hay password.
- Gift success/replay/insufficient balance duoc log bang ids va amount.
- `database/004_wallet_gift_concurrency_test.sql` la script test manual lock behavior khi DB san sang.
