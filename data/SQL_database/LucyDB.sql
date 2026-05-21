CREATE DATABASE LucyDB;
GO
USE LucyDB;
GO

-- languages
CREATE TABLE languages (
    id   INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    code VARCHAR(10)   NOT NULL
);
GO

-- users
CREATE TABLE users (
    id            INT PRIMARY KEY IDENTITY(1,1),
    email         VARCHAR(255)    NOT NULL UNIQUE,
    password_hash VARCHAR(255)    NOT NULL,
    role          VARCHAR(50)     NOT NULL,           -- LUCY|PRO|SUPER|ADMIN
    language_id   INT,
    display_name  NVARCHAR(100),
    avatar_url    VARCHAR(500),
    is_anonymous  BIT             DEFAULT 1,          -- ✅ sửa: mặc định ẩn danh
    bio           NVARCHAR(1000),
    balance       DECIMAL(18,2)   DEFAULT 0,
    is_active     BIT             DEFAULT 1,
    created_at    DATETIME2       DEFAULT GETDATE(),  -- ✅ sửa: TIMESTAMP → DATETIME2

    CONSTRAINT FK_users_languages FOREIGN KEY (language_id) REFERENCES languages(id)
);
GO

-- levels
CREATE TABLE levels (
    id             INT PRIMARY KEY IDENTITY(1,1),
    language_id    INT           NOT NULL,
    stage_number   INT           NOT NULL,
    level_number   INT           NOT NULL,
    topic_name     NVARCHAR(255),
    target_outcome NVARCHAR(1000),
    is_published   BIT           DEFAULT 0,

    CONSTRAINT FK_levels_languages FOREIGN KEY (language_id) REFERENCES languages(id)
);
GO

-- sub_levels
CREATE TABLE sub_levels (
    id               INT PRIMARY KEY IDENTITY(1,1),
    level_id         INT          NOT NULL,
    order_index      INT          NOT NULL,
    title            NVARCHAR(255),
    phonetic         VARCHAR(255),
    duration_minutes INT,
    content_type     VARCHAR(50)  NOT NULL,           -- ✅ thêm NOT NULL

    CONSTRAINT FK_sublevels_levels FOREIGN KEY (level_id) REFERENCES levels(id)
);
GO

-- content_items
CREATE TABLE content_items (
    id           INT PRIMARY KEY IDENTITY(1,1),
    sub_level_id INT           NOT NULL,
    item_type    VARCHAR(50)   NOT NULL,              -- ✅ thêm NOT NULL
    order_index  INT           NOT NULL,
    content_text NVARCHAR(MAX),
    phonetic     VARCHAR(255),

    CONSTRAINT FK_contentitems_sublevels FOREIGN KEY (sub_level_id) REFERENCES sub_levels(id)
);
GO

-- rooms
CREATE TABLE rooms (
    id                   INT PRIMARY KEY IDENTITY(1,1),
    host_id              INT          NOT NULL,
    level_id             INT          NOT NULL,
    current_sub_level_id INT,
    status               VARCHAR(50)  NOT NULL,       -- ✅ thêm NOT NULL
    agora_channel_name   VARCHAR(255),
    max_participants     INT          DEFAULT 50,     -- ✅ thêm DEFAULT 50
    created_at           DATETIME2    DEFAULT GETDATE(), -- ✅ sửa TIMESTAMP
    ended_at             DATETIME2    NULL,           -- ✅ sửa TIMESTAMP

    CONSTRAINT FK_rooms_users     FOREIGN KEY (host_id)              REFERENCES users(id),
    CONSTRAINT FK_rooms_levels    FOREIGN KEY (level_id)             REFERENCES levels(id),
    CONSTRAINT FK_rooms_sublevels FOREIGN KEY (current_sub_level_id) REFERENCES sub_levels(id)
);
GO

-- podcasts
CREATE TABLE podcasts (
    id               INT PRIMARY KEY IDENTITY(1,1),
    creator_id       INT           NOT NULL,
    level_id         INT           NOT NULL,
    audio_url        VARCHAR(500),
    title            NVARCHAR(255),
    description      NVARCHAR(1000),
    duration_seconds INT,
    is_public        BIT           DEFAULT 1,
    created_at       DATETIME2     DEFAULT GETDATE(), -- ✅ sửa TIMESTAMP

    CONSTRAINT FK_podcasts_users  FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT FK_podcasts_levels FOREIGN KEY (level_id)   REFERENCES levels(id)
);
GO

-- transactions
CREATE TABLE transactions (
    id          INT PRIMARY KEY IDENTITY(1,1),
    user_id     INT           NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    type        VARCHAR(50)   NOT NULL,               -- ✅ thêm NOT NULL
    status      VARCHAR(50)   NOT NULL,               -- ✅ thêm NOT NULL
    description NVARCHAR(1000),
    sender_id   INT,
    receiver_id INT,
    room_id     INT,
    gift_type   VARCHAR(100),
    created_at  DATETIME2     DEFAULT GETDATE(),      -- ✅ sửa TIMESTAMP

    CONSTRAINT FK_transactions_users    FOREIGN KEY (user_id)     REFERENCES users(id),
    CONSTRAINT FK_transactions_sender   FOREIGN KEY (sender_id)   REFERENCES users(id),
    CONSTRAINT FK_transactions_receiver FOREIGN KEY (receiver_id) REFERENCES users(id),
    CONSTRAINT FK_transactions_rooms    FOREIGN KEY (room_id)     REFERENCES rooms(id)
);
GO

-- =========================================
-- INDEXES
-- =========================================
CREATE INDEX IX_levels_lang_stage     ON levels       (language_id, stage_number, level_number);
CREATE INDEX IX_sublevels_level       ON sub_levels   (level_id, order_index);
CREATE INDEX IX_contentitems_sub      ON content_items(sub_level_id, order_index);
CREATE INDEX IX_rooms_status          ON rooms        (status);
CREATE INDEX IX_rooms_host            ON rooms        (host_id);
CREATE INDEX IX_transactions_user     ON transactions (user_id, type);
CREATE INDEX IX_transactions_receiver ON transactions (receiver_id);
GO

-- =========================================
-- AI SUPPORT QUESTIONS
-- Mục đích : Câu gợi ý thảo luận hiển thị lên màn hình
--            Moderator/Pro đúng theo mốc thời gian trong phòng.
-- Dùng bởi : Dev 3 — API GET /api/rooms/{id}/moderator-hints
--            Dev 2 — Stored Procedure sp_GetAISupportByMinute
-- Tuần     : 3-5 (tạo bảng) → 6-7 (thêm Stored Procedure)
-- =========================================
CREATE TABLE ai_support_questions (
    id             INT PRIMARY KEY IDENTITY(1,1),
    sub_level_id   INT           NOT NULL,           -- Thuộc Sub-level nào
    question_text  NVARCHAR(MAX) NOT NULL,           -- Câu gợi ý hiển thị cho Moderator
    trigger_minute INT           NOT NULL,           -- Phút thứ mấy trong Sub-level thì hiện
    language_id    INT,                              -- Ngôn ngữ của gợi ý (khớp với level)
    order_index    INT           NOT NULL DEFAULT 1, -- Thứ tự nếu cùng trigger_minute

    CONSTRAINT FK_aisupport_sublevels FOREIGN KEY (sub_level_id) REFERENCES sub_levels(id),
    CONSTRAINT FK_aisupport_languages FOREIGN KEY (language_id)  REFERENCES languages(id)
);
GO

-- Index: truy vấn nhanh theo phút — dùng bởi Stored Procedure bên dưới
CREATE INDEX IX_aisupport_sub_minute ON ai_support_questions (sub_level_id, trigger_minute);
GO

-- =========================================
-- STORED PROCEDURE: sp_GetAISupportByMinute
-- Mục đích : Lấy tối đa 3 câu gợi ý gần nhất với phút hiện tại.
--            Gọi mỗi khi Timer Module của Node.js tick sang phút mới.
-- Input    : @sub_level_id   — Sub-level đang chạy trong phòng
--            @current_minute — Phút hiện tại (từ Timer Module Node.js)
-- Output   : Tối đa 3 câu gợi ý đã đến giờ hiển thị
-- =========================================
CREATE PROCEDURE sp_GetAISupportByMinute
    @sub_level_id   INT,
    @current_minute INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 3
        id,
        question_text,
        trigger_minute
    FROM ai_support_questions
    WHERE sub_level_id   = @sub_level_id
      AND trigger_minute <= @current_minute  -- Chỉ lấy gợi ý đã đến giờ
    ORDER BY trigger_minute DESC,            -- Ưu tiên gợi ý gần phút hiện tại nhất
             order_index   ASC;
END;
GO