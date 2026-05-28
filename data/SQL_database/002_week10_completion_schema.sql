USE LucyDB;
GO

-- Week 1-2 completion: explicit Languages -> Stages -> Levels -> SubLevels chain.
-- This is additive: existing levels.language_id and stage_number stay intact for current Java code.
IF OBJECT_ID('dbo.stages', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.stages (
        id           INT           PRIMARY KEY IDENTITY(1,1),
        language_id  INT           NOT NULL,
        stage_number INT           NOT NULL,
        name         NVARCHAR(100) NULL,
        created_at   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_stages_languages FOREIGN KEY (language_id) REFERENCES dbo.languages(id),
        CONSTRAINT UQ_stages_language_number UNIQUE (language_id, stage_number)
    );
END;
GO

IF COL_LENGTH('dbo.levels', 'stage_id') IS NULL
BEGIN
    ALTER TABLE dbo.levels
    ADD stage_id INT NULL;
END;
GO

INSERT INTO dbo.stages (language_id, stage_number, name)
SELECT DISTINCT l.language_id, l.stage_number, CONCAT(N'Stage ', l.stage_number)
FROM dbo.levels l
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.stages s
    WHERE s.language_id = l.language_id
      AND s.stage_number = l.stage_number
);
GO

UPDATE l
SET stage_id = s.id
FROM dbo.levels l
JOIN dbo.stages s
  ON s.language_id = l.language_id
 AND s.stage_number = l.stage_number
WHERE l.stage_id IS NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_levels_stages'
      AND parent_object_id = OBJECT_ID('dbo.levels')
)
BEGIN
    ALTER TABLE dbo.levels WITH CHECK
    ADD CONSTRAINT FK_levels_stages FOREIGN KEY (stage_id) REFERENCES dbo.stages(id);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_levels_stage_level'
      AND object_id = OBJECT_ID('dbo.levels')
)
BEGIN
    CREATE INDEX IX_levels_stage_level
        ON dbo.levels(stage_id, level_number)
        INCLUDE (language_id, stage_number, topic_name, is_published);
END;
GO

-- Week 3-5 completion: room participation history.
IF OBJECT_ID('dbo.room_participants', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.room_participants (
        id                     BIGINT        PRIMARY KEY IDENTITY(1,1),
        room_id                INT           NOT NULL,
        user_id                INT           NULL,
        persona_public_subject VARCHAR(64)   NULL,
        display_name           NVARCHAR(100) NULL,
        participant_role       VARCHAR(20)   NOT NULL DEFAULT 'AUDIENCE',
        is_anonymous           BIT           NOT NULL DEFAULT 1,
        connection_id          VARCHAR(128)  NULL,
        joined_at              DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
        left_at                DATETIME2     NULL,

        CONSTRAINT FK_room_participants_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
        CONSTRAINT FK_room_participants_users FOREIGN KEY (user_id) REFERENCES dbo.users(id),
        CONSTRAINT CK_room_participants_role CHECK (participant_role IN ('HOST', 'MODERATOR', 'AUDIENCE'))
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_room_participants_room_time'
      AND object_id = OBJECT_ID('dbo.room_participants')
)
BEGIN
    CREATE INDEX IX_room_participants_room_time
        ON dbo.room_participants(room_id, joined_at DESC)
        INCLUDE (user_id, persona_public_subject, left_at);
END;
GO

-- Week 6-7 completion: host-pinned slide/image/document resources.
IF OBJECT_ID('dbo.room_resources', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.room_resources (
        id            BIGINT         PRIMARY KEY IDENTITY(1,1),
        room_id       INT            NOT NULL,
        host_id       INT            NOT NULL,
        resource_type VARCHAR(30)    NOT NULL,
        title         NVARCHAR(255)  NULL,
        resource_url  NVARCHAR(1000) NOT NULL,
        sort_order    INT            NOT NULL DEFAULT 0,
        is_active     BIT            NOT NULL DEFAULT 1,
        pinned_at     DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
        unpinned_at   DATETIME2      NULL,

        CONSTRAINT FK_room_resources_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),
        CONSTRAINT FK_room_resources_hosts FOREIGN KEY (host_id) REFERENCES dbo.users(id),
        CONSTRAINT CK_room_resources_type CHECK (resource_type IN ('SLIDE_URL', 'IMAGE_URL', 'DOCUMENT_URL', 'OTHER'))
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_room_resources_active'
      AND object_id = OBJECT_ID('dbo.room_resources')
)
BEGIN
    CREATE INDEX IX_room_resources_active
        ON dbo.room_resources(room_id, is_active, sort_order)
        INCLUDE (resource_type, title, resource_url, pinned_at);
END;
GO

-- Week 8-10 financial integrity hardening: explicit FK links for wallet transactions.
IF OBJECT_ID('dbo.wallet_transactions', 'U') IS NOT NULL
   AND OBJECT_ID('dbo.wallets', 'U') IS NOT NULL
   AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_wt_sender_wallet'
      AND parent_object_id = OBJECT_ID('dbo.wallet_transactions')
)
BEGIN
    ALTER TABLE dbo.wallet_transactions WITH CHECK
    ADD CONSTRAINT FK_wt_sender_wallet FOREIGN KEY (sender_wallet_id) REFERENCES dbo.wallets(id);
END;
GO

IF OBJECT_ID('dbo.wallet_transactions', 'U') IS NOT NULL
   AND OBJECT_ID('dbo.wallets', 'U') IS NOT NULL
   AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_wt_receiver_wallet'
      AND parent_object_id = OBJECT_ID('dbo.wallet_transactions')
)
BEGIN
    ALTER TABLE dbo.wallet_transactions WITH CHECK
    ADD CONSTRAINT FK_wt_receiver_wallet FOREIGN KEY (receiver_wallet_id) REFERENCES dbo.wallets(id);
END;
GO

IF OBJECT_ID('dbo.rooms', 'U') IS NOT NULL
   AND OBJECT_ID('dbo.wallet_transactions', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = 'FK_wt_rooms'
         AND parent_object_id = OBJECT_ID('dbo.wallet_transactions')
   )
BEGIN
    ALTER TABLE dbo.wallet_transactions WITH CHECK
    ADD CONSTRAINT FK_wt_rooms FOREIGN KEY (room_id) REFERENCES dbo.rooms(id);
END;
GO
