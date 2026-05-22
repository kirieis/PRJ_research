USE LucyDB;
GO

IF OBJECT_ID('dbo.users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.users (
        id            INT PRIMARY KEY IDENTITY(1,1),
        email         VARCHAR(255)  NOT NULL UNIQUE,
        password_hash VARCHAR(255)  NOT NULL,
        role          VARCHAR(50)   NOT NULL,
        language_id   INT           NULL,
        display_name  NVARCHAR(100) NULL,
        avatar_url    VARCHAR(500)  NULL,
        is_anonymous  BIT           NOT NULL DEFAULT 1,
        bio           NVARCHAR(1000) NULL,
        balance       DECIMAL(18,2) NOT NULL DEFAULT 0,
        is_active     BIT           NOT NULL DEFAULT 1,
        created_at    DATETIME2     NOT NULL DEFAULT GETDATE()
    );
END;
GO

IF COL_LENGTH('dbo.users', 'is_anonymous') IS NULL
BEGIN
    ALTER TABLE dbo.users
    ADD is_anonymous BIT NOT NULL CONSTRAINT DF_users_is_anonymous DEFAULT 1;
END;
GO

IF COL_LENGTH('dbo.users', 'password_hash') IS NULL
BEGIN
    ALTER TABLE dbo.users
    ADD password_hash VARCHAR(255) NOT NULL;
END;
GO

IF COL_LENGTH('dbo.users', 'role') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.check_constraints
       WHERE name = 'CK_users_role_auth'
         AND parent_object_id = OBJECT_ID('dbo.users')
   )
BEGIN
    ALTER TABLE dbo.users
    ADD CONSTRAINT CK_users_role_auth CHECK (UPPER(role) IN ('LUCY', 'PRO', 'SUPER', 'ADMIN'));
END;
GO
