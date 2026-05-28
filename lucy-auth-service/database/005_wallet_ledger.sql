-- =========================================
-- Migration 005: Wallet Ledger
-- Dev 2 — Week 6-7: Financial Module
-- Mục đích: Sổ cái bất biến ghi vết mọi biến
--           động số dư trước và sau giao dịch.
-- =========================================
USE LucyDB;
GO

IF OBJECT_ID('dbo.wallet_ledger', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.wallet_ledger (
        id              BIGINT        PRIMARY KEY IDENTITY(1,1),
        wallet_id       INT           NOT NULL,
        transaction_id  BIGINT        NOT NULL,
        entry_type      VARCHAR(10)   NOT NULL,
        amount          DECIMAL(18,2) NOT NULL,
        balance_before  DECIMAL(18,2) NOT NULL,
        balance_after   DECIMAL(18,2) NOT NULL,
        description     NVARCHAR(500) NULL,
        created_at      DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_ledger_wallets FOREIGN KEY (wallet_id)
            REFERENCES dbo.wallets(id),
        CONSTRAINT FK_ledger_transactions FOREIGN KEY (transaction_id)
            REFERENCES dbo.wallet_transactions(id),
        CONSTRAINT CK_ledger_entry_type CHECK (entry_type IN ('DEBIT', 'CREDIT')),
        CONSTRAINT CK_ledger_amount_positive CHECK (amount > 0)
    );
END;
GO

-- Index: tra cứu ledger theo wallet (lịch sử biến động số dư)
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ledger_wallet_time'
      AND object_id = OBJECT_ID('dbo.wallet_ledger')
)
BEGIN
    CREATE INDEX IX_ledger_wallet_time
        ON dbo.wallet_ledger(wallet_id, created_at DESC)
        INCLUDE (entry_type, amount, balance_before, balance_after);
END;
GO

-- Index: tra cứu ledger theo transaction
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ledger_transaction'
      AND object_id = OBJECT_ID('dbo.wallet_ledger')
)
BEGIN
    CREATE INDEX IX_ledger_transaction
        ON dbo.wallet_ledger(transaction_id);
END;
GO
