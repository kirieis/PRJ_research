USE LucyDB;
GO

IF OBJECT_ID('dbo.wallets', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.wallets (
        id         INT PRIMARY KEY IDENTITY(1,1),
        user_id    INT           NOT NULL UNIQUE,
        balance    DECIMAL(18,2) NOT NULL CONSTRAINT DF_wallets_balance DEFAULT 0,
        currency   VARCHAR(10)   NOT NULL CONSTRAINT DF_wallets_currency DEFAULT 'LUCY',
        created_at DATETIME2     NOT NULL CONSTRAINT DF_wallets_created_at DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2     NULL,

        CONSTRAINT FK_wallets_users FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT CK_wallets_balance_non_negative CHECK (balance >= 0)
    );
END;
GO

IF OBJECT_ID('dbo.wallet_transactions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.wallet_transactions (
        id              BIGINT PRIMARY KEY IDENTITY(1,1),
        user_id         INT           NOT NULL,
        sender_id       INT           NULL,
        receiver_id     INT           NULL,
        amount          DECIMAL(18,2) NOT NULL,
        type            VARCHAR(50)   NOT NULL,
        status          VARCHAR(50)   NOT NULL,
        description     NVARCHAR(1000) NULL,
        room_id         INT           NULL,
        gift_type       VARCHAR(100)  NULL,
        idempotency_key VARCHAR(100)  NOT NULL,
        created_at      DATETIME2     NOT NULL CONSTRAINT DF_wallet_transactions_created_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_wallet_transactions_users FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT FK_wallet_transactions_sender FOREIGN KEY (sender_id) REFERENCES dbo.users(id),
        CONSTRAINT FK_wallet_transactions_receiver FOREIGN KEY (receiver_id) REFERENCES dbo.users(id),
        CONSTRAINT FK_wallet_transactions_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
        CONSTRAINT CK_wallet_transactions_amount_positive CHECK (amount > 0),
        CONSTRAINT CK_wallet_transactions_status CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')),
        CONSTRAINT CK_wallet_transactions_type CHECK (type IN ('GIFT', 'DEPOSIT'))
    );
END;
GO

IF OBJECT_ID('dbo.wallet_ledger', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.wallet_ledger (
        id             BIGINT PRIMARY KEY IDENTITY(1,1),
        transaction_id BIGINT        NOT NULL,
        user_id        INT           NOT NULL,
        direction      VARCHAR(10)   NOT NULL,
        amount         DECIMAL(18,2) NOT NULL,
        balance_before DECIMAL(18,2) NOT NULL,
        balance_after  DECIMAL(18,2) NOT NULL,
        created_at     DATETIME2     NOT NULL CONSTRAINT DF_wallet_ledger_created_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_wallet_ledger_transactions FOREIGN KEY (transaction_id) REFERENCES dbo.wallet_transactions(id),
        CONSTRAINT FK_wallet_ledger_users FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT CK_wallet_ledger_direction CHECK (direction IN ('DEBIT', 'CREDIT')),
        CONSTRAINT CK_wallet_ledger_balance_non_negative CHECK (balance_before >= 0 AND balance_after >= 0)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_wallet_transactions_idempotency'
      AND object_id = OBJECT_ID('dbo.wallet_transactions')
)
BEGIN
    CREATE UNIQUE INDEX UX_wallet_transactions_idempotency
        ON dbo.wallet_transactions(user_id, idempotency_key);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_wallet_ledger_transaction'
      AND object_id = OBJECT_ID('dbo.wallet_ledger')
)
BEGIN
    CREATE INDEX IX_wallet_ledger_transaction
        ON dbo.wallet_ledger(transaction_id);
END;
GO
