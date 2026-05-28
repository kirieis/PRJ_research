-- =========================================
-- Migration 004: Wallet Transactions
-- Dev 2 — Week 6-7: Financial Module
-- Mục đích: Bảng giao dịch tài chính riêng biệt,
--           có idempotency_key chống trùng lặp.
-- Lưu ý : Bảng này TÁCH BIỆT với dbo.transactions
--          (LucyDB.sql) mà Dev 1/3 đang sử dụng.
-- =========================================
USE LucyDB;
GO

IF OBJECT_ID('dbo.wallet_transactions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.wallet_transactions (
        id                 BIGINT        PRIMARY KEY IDENTITY(1,1),
        idempotency_key    VARCHAR(128)  NOT NULL,
        transaction_type   VARCHAR(20)   NOT NULL,
        status             VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
        amount             DECIMAL(18,2) NOT NULL,
        sender_wallet_id   INT           NULL,
        receiver_wallet_id INT           NULL,
        room_id            INT           NULL,
        gift_type          VARCHAR(100)  NULL,
        description        NVARCHAR(500) NULL,
        created_at         DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
        completed_at       DATETIME2     NULL,

        CONSTRAINT UQ_wallet_transactions_idempotency UNIQUE (idempotency_key),
        CONSTRAINT CK_wt_amount_positive CHECK (amount > 0),
        CONSTRAINT CK_wt_type CHECK (transaction_type IN ('DEPOSIT', 'GIFT', 'WITHDRAW')),
        CONSTRAINT CK_wt_status CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'))
    );
END;
GO

-- Index: tra cứu nhanh theo idempotency_key (covered by UNIQUE constraint)
-- Index: tra cứu giao dịch theo sender/receiver wallet
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_wt_sender_wallet'
      AND object_id = OBJECT_ID('dbo.wallet_transactions')
)
BEGIN
    CREATE INDEX IX_wt_sender_wallet
        ON dbo.wallet_transactions(sender_wallet_id, created_at DESC)
        WHERE sender_wallet_id IS NOT NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_wt_receiver_wallet'
      AND object_id = OBJECT_ID('dbo.wallet_transactions')
)
BEGIN
    CREATE INDEX IX_wt_receiver_wallet
        ON dbo.wallet_transactions(receiver_wallet_id, created_at DESC)
        WHERE receiver_wallet_id IS NOT NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_wt_status_type'
      AND object_id = OBJECT_ID('dbo.wallet_transactions')
)
BEGIN
    CREATE INDEX IX_wt_status_type
        ON dbo.wallet_transactions(status, transaction_type)
        INCLUDE (amount, created_at);
END;
GO
