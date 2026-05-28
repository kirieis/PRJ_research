USE LucyDB;
GO

IF OBJECT_ID('dbo.user_personas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.user_personas (
        id             INT PRIMARY KEY IDENTITY(1,1),
        user_id        INT           NOT NULL UNIQUE,
        public_subject VARCHAR(64)   NOT NULL UNIQUE,
        display_name   NVARCHAR(100) NOT NULL,
        avatar_code    VARCHAR(50)   NOT NULL,
        avatar_url     VARCHAR(500)  NULL,
        created_at     DATETIME2     NOT NULL CONSTRAINT DF_user_personas_created_at DEFAULT SYSUTCDATETIME(),
        updated_at     DATETIME2     NULL,

        CONSTRAINT FK_user_personas_users FOREIGN KEY (user_id) REFERENCES dbo.users(id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_user_personas_public_subject'
      AND object_id = OBJECT_ID('dbo.user_personas')
)
BEGIN
    CREATE UNIQUE INDEX IX_user_personas_public_subject
        ON dbo.user_personas(public_subject);
END;
GO
