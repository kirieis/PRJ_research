USE LucyDB;
GO

-- Dev 2 week 10 manual concurrency test:
-- 1. Run session A to hold the sender wallet lock for 10 seconds.
-- 2. Immediately run session B with the same sender and a different idempotency key.
-- 3. Session B must wait or fail with insufficient balance; final wallet balance must never go negative.

DECLARE @sender_id INT = 1;
DECLARE @receiver_id INT = 2;
DECLARE @amount DECIMAL(18,2) = 10.00;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM dbo.wallets WITH (UPDLOCK, HOLDLOCK) WHERE user_id = @sender_id)
BEGIN
    INSERT INTO dbo.wallets (user_id, balance) VALUES (@sender_id, 0);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.wallets WITH (UPDLOCK, HOLDLOCK) WHERE user_id = @receiver_id)
BEGIN
    INSERT INTO dbo.wallets (user_id, balance) VALUES (@receiver_id, 0);
END;

SELECT balance
FROM dbo.wallets WITH (UPDLOCK, HOLDLOCK)
WHERE user_id = @sender_id;

WAITFOR DELAY '00:00:10';

ROLLBACK TRANSACTION;
GO

SELECT user_id, balance
FROM dbo.wallets
WHERE user_id IN (1, 2);
GO
