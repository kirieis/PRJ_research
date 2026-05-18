-- =========================================
-- TẠO DATABASE
-- =========================================
CREATE DATABASE LucyDB;
GO

USE LucyDB;
GO

-- =========================================
-- BẢNG NGÔN NGỮ (đã có)
-- =========================================
CREATE TABLE languages (
    id   INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    code VARCHAR(10)   NOT NULL
);
GO

-- =========================================
-- BẢNG USER 
-- =========================================
CREATE TABLE users (
    id            INT PRIMARY KEY IDENTITY(1,1),
    email         VARCHAR(255)    NOT NULL UNIQUE,
    password_hash VARCHAR(255)    NOT NULL,
    role          VARCHAR(50)     NOT NULL,           -- LUCY|PRO|SUPER|ADMIN
    language_id   INT,
    display_name  NVARCHAR(100),
    avatar_url    VARCHAR(500),
    is_anonymous  BIT             DEFAULT 1,
    bio           NVARCHAR(1000),
    balance       DECIMAL(18,2)   DEFAULT 0,
    is_active     BIT             DEFAULT 1,
    created_at    DATETIME2       DEFAULT GETDATE(),

    CONSTRAINT FK_users_languages FOREIGN KEY (language_id) REFERENCES languages(id)
);
GO

-- =========================================
-- BẢNG STAGE (BỔ SUNG) – Lưu thông tin giai đoạn: Sơ cấp, Trung cấp, Cao cấp
-- =========================================
CREATE TABLE stages (
    id            INT PRIMARY KEY IDENTITY(1,1),
    language_id   INT           NOT NULL,
    stage_number  INT           NOT NULL,   -- 1,2,3
    name          NVARCHAR(100) NOT NULL,   -- 'Sơ cấp', 'Trung cấp', 'Cao cấp'
    description   NVARCHAR(255) NULL,

    CONSTRAINT FK_stages_languages FOREIGN KEY (language_id) REFERENCES languages(id),
    CONSTRAINT UQ_stages_lang_number UNIQUE (language_id, stage_number)
);
GO

-- =========================================
-- BẢNG LEVEL (điều chỉnh: thêm stage_id, content_text, audio_url)
-- =========================================
CREATE TABLE levels (
    id             INT PRIMARY KEY IDENTITY(1,1),
    stage_id       INT           NOT NULL,          -- thay vì language_id+stage_number
    level_number   INT           NOT NULL,          -- 1..33
    topic_name     NVARCHAR(255),
    target_outcome NVARCHAR(1000),
    content_text   NVARCHAR(MAX) NOT NULL,          -- Nội dung text chính của level (đã parse từ Word)
    audio_url      VARCHAR(500)  NULL,              -- Đường dẫn file audio (nếu có)
    duration_minutes INT         NULL,              -- Tổng thời gian dự kiến của level
    is_published   BIT           DEFAULT 0,

    CONSTRAINT FK_levels_stages FOREIGN KEY (stage_id) REFERENCES stages(id),
    CONSTRAINT UQ_levels_stage_number UNIQUE (stage_id, level_number)
);
GO

-- =========================================
-- BẢNG SUB_LEVELS (giữ nguyên nhưng đã có level_id)
-- =========================================
CREATE TABLE sub_levels (
    id               INT PRIMARY KEY IDENTITY(1,1),
    level_id         INT          NOT NULL,
    order_index      INT          NOT NULL,
    title            NVARCHAR(255),
    phonetic         VARCHAR(255),
    duration_minutes INT,
    content_type     VARCHAR(50)  NOT NULL,   -- 'DIALOGUE', 'VOCAB', 'GRAMMAR', ...

    CONSTRAINT FK_sublevels_levels FOREIGN KEY (level_id) REFERENCES levels(id)
);
GO

-- =========================================
-- BẢNG CONTENT_ITEMS (giữ nguyên)
-- =========================================
CREATE TABLE content_items (
    id           INT PRIMARY KEY IDENTITY(1,1),
    sub_level_id INT           NOT NULL,
    item_type    VARCHAR(50)   NOT NULL,   -- 'TEXT', 'PRONUNCIATION', 'EXAMPLE', ...
    order_index  INT           NOT NULL,
    content_text NVARCHAR(MAX),
    phonetic     VARCHAR(255),

    CONSTRAINT FK_contentitems_sublevels FOREIGN KEY (sub_level_id) REFERENCES sub_levels(id)
);
GO

-- =========================================
-- BẢNG CÂU HỎI (BỔ SUNG – AI Support)
-- =========================================
CREATE TABLE questions (
    id            INT PRIMARY KEY IDENTITY(1,1),
    level_id      INT           NULL,      -- Có thể gắn vào level
    sub_level_id  INT           NULL,      -- Hoặc gắn vào sub_level
    question_text NVARCHAR(500) NOT NULL,
    question_type VARCHAR(20)   NOT NULL DEFAULT 'MULTIPLE_CHOICE', -- MULTIPLE_CHOICE, TRUE_FALSE, TEXT
    explanation   NVARCHAR(500) NULL,
    order_index   INT           NOT NULL DEFAULT 0,

    CONSTRAINT FK_questions_levels FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE CASCADE,
    CONSTRAINT FK_questions_sublevels FOREIGN KEY (sub_level_id) REFERENCES sub_levels(id) ON DELETE CASCADE
);
GO

-- =========================================
-- BẢNG LỰA CHỌN CÂU HỎI (dùng cho trắc nghiệm)
-- =========================================
CREATE TABLE question_options (
    id           INT PRIMARY KEY IDENTITY(1,1),
    question_id  INT           NOT NULL,
    option_text  NVARCHAR(255) NOT NULL,
    is_correct   BIT           NOT NULL DEFAULT 0,
    order_index  INT           NOT NULL DEFAULT 0,

    CONSTRAINT FK_options_questions FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);
GO

-- =========================================
-- BẢNG LOG IMPORT (để theo dõi quá trình số hóa 8 file Word)
-- =========================================
CREATE TABLE import_logs (
    id             INT PRIMARY KEY IDENTITY(1,1),
    file_name      NVARCHAR(200) NOT NULL,
    language_code  VARCHAR(10)   NOT NULL,
    stage_name     NVARCHAR(100) NULL,
    imported_at    DATETIME2     DEFAULT GETDATE(),
    status         VARCHAR(20)   NOT NULL,   -- 'SUCCESS', 'FAILED', 'PARTIAL'
    records_imported INT          NULL,
    error_message  NVARCHAR(MAX) NULL
);
GO

-- =========================================
-- BẢNG ROOMS (giữ nguyên)
-- =========================================
CREATE TABLE rooms (
    id                   INT PRIMARY KEY IDENTITY(1,1),
    host_id              INT          NOT NULL,
    level_id             INT          NOT NULL,
    current_sub_level_id INT,
    status               VARCHAR(50)  NOT NULL,
    agora_channel_name   VARCHAR(255),
    max_participants     INT          DEFAULT 50,
    created_at           DATETIME2    DEFAULT GETDATE(),
    ended_at             DATETIME2    NULL,

    CONSTRAINT FK_rooms_users     FOREIGN KEY (host_id)              REFERENCES users(id),
    CONSTRAINT FK_rooms_levels    FOREIGN KEY (level_id)             REFERENCES levels(id),
    CONSTRAINT FK_rooms_sublevels FOREIGN KEY (current_sub_level_id) REFERENCES sub_levels(id)
);
GO

-- =========================================
-- BẢNG PODCASTS (giữ nguyên)
-- =========================================
CREATE TABLE podcasts (
    id               INT PRIMARY KEY IDENTITY(1,1),
    creator_id       INT           NOT NULL,
    level_id         INT           NOT NULL,
    audio_url        VARCHAR(500),
    title            NVARCHAR(255),
    description      NVARCHAR(1000),
    duration_seconds INT,
    is_public        BIT           DEFAULT 1,
    created_at       DATETIME2     DEFAULT GETDATE(),

    CONSTRAINT FK_podcasts_users  FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT FK_podcasts_levels FOREIGN KEY (level_id)   REFERENCES levels(id)
);
GO

-- =========================================
-- BẢNG TRANSACTIONS (giữ nguyên)
-- =========================================
CREATE TABLE transactions (
    id          INT PRIMARY KEY IDENTITY(1,1),
    user_id     INT           NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    type        VARCHAR(50)   NOT NULL,
    status      VARCHAR(50)   NOT NULL,
    description NVARCHAR(1000),
    sender_id   INT,
    receiver_id INT,
    room_id     INT,
    gift_type   VARCHAR(100),
    created_at  DATETIME2     DEFAULT GETDATE(),

    CONSTRAINT FK_transactions_users    FOREIGN KEY (user_id)     REFERENCES users(id),
    CONSTRAINT FK_transactions_sender   FOREIGN KEY (sender_id)   REFERENCES users(id),
    CONSTRAINT FK_transactions_receiver FOREIGN KEY (receiver_id) REFERENCES users(id),
    CONSTRAINT FK_transactions_rooms    FOREIGN KEY (room_id)     REFERENCES rooms(id)
);
GO

-- =========================================
-- INDEXES (tối ưu truy vấn)
-- =========================================
CREATE INDEX IX_levels_stage          ON levels       (stage_id, level_number);
CREATE INDEX IX_sublevels_level       ON sub_levels   (level_id, order_index);
CREATE INDEX IX_contentitems_sub      ON content_items(sub_level_id, order_index);
CREATE INDEX IX_questions_level       ON questions    (level_id);
CREATE INDEX IX_questions_sublevel    ON questions    (sub_level_id);
CREATE INDEX IX_rooms_status          ON rooms        (status);
CREATE INDEX IX_rooms_host            ON rooms        (host_id);
CREATE INDEX IX_transactions_user     ON transactions (user_id, type);
CREATE INDEX IX_transactions_receiver ON transactions (receiver_id);
GO
