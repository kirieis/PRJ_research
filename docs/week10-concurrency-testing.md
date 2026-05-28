# Week 10 Concurrency Testing

This checklist covers the two sensitive wallet flows: gift and deposit.

## Preconditions

- Run database scripts in order:
  - `lucy-auth-service/database/003_wallets.sql`
  - `lucy-auth-service/database/004_wallet_transactions.sql`
  - `lucy-auth-service/database/005_wallet_ledger.sql`
  - `lucy-auth-service/database/006_audit_logs.sql`
  - `data/SQL_database/002_week10_completion_schema.sql`
- Start `lucy-auth-service`.
- Create two active users and obtain a JWT access token for the sender.
- Give the sender enough balance, either through `POST /api/wallet/deposit` or direct seed data in a local test database.

## Run

```powershell
.\lucy-auth-service\tests\wallet-concurrency.ps1 `
  -BaseUrl "http://localhost:5000" `
  -SenderAccessToken "<sender-jwt>" `
  -ReceiverUserId 2 `
  -GiftWorkers 100 `
  -DepositWorkers 100 `
  -GiftAmount 1 `
  -DepositAmount 1
```

## Pass Criteria

- No duplicate `wallet_transactions.id` values in the script summary.
- No negative wallet balances.
- `wallet_transactions.idempotency_key` remains unique.
- Every completed gift has exactly one sender `DEBIT` ledger row and one receiver `CREDIT` ledger row.
- Every completed deposit has exactly one receiver `CREDIT` ledger row.
- Any failed request is represented by an application response and an `audit_logs` row; it must not leave partial ledger rows.

## Useful SQL Checks

```sql
SELECT id, user_id, balance
FROM dbo.wallets
WHERE balance < 0;

SELECT idempotency_key, COUNT(*) AS duplicate_count
FROM dbo.wallet_transactions
GROUP BY idempotency_key
HAVING COUNT(*) > 1;

SELECT transaction_id, entry_type, COUNT(*) AS row_count
FROM dbo.wallet_ledger
GROUP BY transaction_id, entry_type
HAVING COUNT(*) > 1;

SELECT TOP 50 event_type, severity, message, created_at
FROM dbo.audit_logs
ORDER BY created_at DESC;
```
