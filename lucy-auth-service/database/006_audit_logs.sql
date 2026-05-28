-- =========================================
-- Migration 006: Audit Logs
-- Dev 2 — Week 10: Audit & Exception Logging
-- Mục đích: Bảng nhật ký kiểm toán ghi lại mọi
--           sự kiện tài chính, ngoại lệ và thay đổi
--           hệ thống phục vụ truy vết và compliance.
-- =========================================
USE LucyDB;
GO

IF OBJECT_ID('dbo.audit_logs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.audit_logs (
        id              BIGINT         PRIMARY KEY IDENTITY(1,1),
        event_type      VARCHAR(50)    NOT NULL,
        user_id         INT            NULL,
        transaction_id  BIGINT         NULL,
        severity        VARCHAR(10)    NOT NULL DEFAULT 'INFO',
        message         NVARCHAR(2000) NOT NULL,
        details_json    NVARCHAR(MAX)  NULL,
        ip_address      VARCHAR(45)    NULL,
        user_agent      NVARCHAR(500)  NULL,
        created_at      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT CK_audit_severity CHECK (severity IN ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'))
    );
END;
GO

-- Index: tra cứu audit theo event_type + thời gian
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_audit_event_time'
      AND object_id = OBJECT_ID('dbo.audit_logs')
)
BEGIN
    CREATE INDEX IX_audit_event_time
        ON dbo.audit_logs(event_type, created_at DESC)
        INCLUDE (severity, user_id);
END;
GO

-- Index: tra cứu audit theo user_id
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_audit_user'
      AND object_id = OBJECT_ID('dbo.audit_logs')
)
BEGIN
    CREATE INDEX IX_audit_user
        ON dbo.audit_logs(user_id, created_at DESC)
        WHERE user_id IS NOT NULL;
END;
GO

-- Index: tra cứu audit theo severity (lọc ERROR/CRITICAL)
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_audit_severity'
      AND object_id = OBJECT_ID('dbo.audit_logs')
)
BEGIN
    CREATE INDEX IX_audit_severity
        ON dbo.audit_logs(severity, created_at DESC)
        WHERE severity IN ('ERROR', 'CRITICAL');
END;
GO
