-- =========================================
-- Migration 003: Wallets
-- Dev 2 — Week 6-7: Financial Module
-- Mục đích: Tạo bảng ví điện tử, tách balance
--           ra khỏi users để quản lý riêng biệt.
-- =========================================
USE LucyDB;
GO

IF OBJECT_ID('dbo.wallets', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.wallets (
        id          INT           PRIMARY KEY IDENTITY(1,1),
        user_id     INT           NOT NULL UNIQUE,
        balance     DECIMAL(18,2) NOT NULL DEFAULT 0,
        currency    VARCHAR(10)   NOT NULL DEFAULT 'LUCY_COIN',
        is_locked   BIT           NOT NULL DEFAULT 0,
        created_at  DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at  DATETIME2     NULL,

        CONSTRAINT FK_wallets_users FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT CK_wallets_balance_non_negative CHECK (balance >= 0)
    );
END;
GO

-- Index: truy vấn nhanh theo user_id (đã có UNIQUE ở trên, thêm cover index cho balance)
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_wallets_user_balance'
      AND object_id = OBJECT_ID('dbo.wallets')
)
BEGIN
    CREATE INDEX IX_wallets_user_balance
        ON dbo.wallets(user_id)
        INCLUDE (balance, currency, is_locked);
END;
GO
