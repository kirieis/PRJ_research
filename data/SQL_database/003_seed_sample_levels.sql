USE LucyDB;
GO

-- Small seed set for API smoke tests. Safe to re-run.
IF NOT EXISTS (SELECT 1 FROM dbo.languages WHERE code = 'EN')
BEGIN
    INSERT INTO dbo.languages (name, code)
    VALUES (N'English', 'EN');
END;
GO

DECLARE @englishId INT = (SELECT TOP (1) id FROM dbo.languages WHERE code = 'EN');

IF OBJECT_ID('dbo.stages', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM dbo.stages
       WHERE language_id = @englishId
         AND stage_number = 1
   )
BEGIN
    INSERT INTO dbo.stages (language_id, stage_number, name)
    VALUES (@englishId, 1, N'Stage 1');
END;

DECLARE @stageId INT = NULL;
IF OBJECT_ID('dbo.stages', 'U') IS NOT NULL
BEGIN
    SELECT TOP (1) @stageId = id
    FROM dbo.stages
    WHERE language_id = @englishId
      AND stage_number = 1;
END;

IF NOT EXISTS (
    SELECT 1
    FROM dbo.levels
    WHERE language_id = @englishId
      AND stage_number = 1
      AND level_number = 1
)
BEGIN
    IF COL_LENGTH('dbo.levels', 'stage_id') IS NOT NULL
    BEGIN
        INSERT INTO dbo.levels (
            language_id,
            stage_id,
            stage_number,
            level_number,
            topic_name,
            target_outcome,
            is_published
        )
        VALUES (
            @englishId,
            @stageId,
            1,
            1,
            N'Greetings and introductions',
            N'Learners can greet others and introduce themselves in simple English.',
            1
        );
    END
    ELSE
    BEGIN
        INSERT INTO dbo.levels (
            language_id,
            stage_number,
            level_number,
            topic_name,
            target_outcome,
            is_published
        )
        VALUES (
            @englishId,
            1,
            1,
            N'Greetings and introductions',
            N'Learners can greet others and introduce themselves in simple English.',
            1
        );
    END
END;

IF NOT EXISTS (
    SELECT 1
    FROM dbo.levels
    WHERE language_id = @englishId
      AND stage_number = 1
      AND level_number = 2
)
BEGIN
    IF COL_LENGTH('dbo.levels', 'stage_id') IS NOT NULL
    BEGIN
        INSERT INTO dbo.levels (
            language_id,
            stage_id,
            stage_number,
            level_number,
            topic_name,
            target_outcome,
            is_published
        )
        VALUES (
            @englishId,
            @stageId,
            1,
            2,
            N'Daily routines',
            N'Learners can describe basic daily activities and time expressions.',
            1
        );
    END
    ELSE
    BEGIN
        INSERT INTO dbo.levels (
            language_id,
            stage_number,
            level_number,
            topic_name,
            target_outcome,
            is_published
        )
        VALUES (
            @englishId,
            1,
            2,
            N'Daily routines',
            N'Learners can describe basic daily activities and time expressions.',
            1
        );
    END
END;
GO

DECLARE @level1Id INT = (
    SELECT TOP (1) id
    FROM dbo.levels
    WHERE language_id = (SELECT TOP (1) id FROM dbo.languages WHERE code = 'EN')
      AND stage_number = 1
      AND level_number = 1
);

IF NOT EXISTS (
    SELECT 1
    FROM dbo.sub_levels
    WHERE level_id = @level1Id
      AND order_index = 1
)
BEGIN
    INSERT INTO dbo.sub_levels (level_id, order_index, title, phonetic, duration_minutes, content_type)
    VALUES (@level1Id, 1, N'Say hello', NULL, 10, 'DIALOGUE');
END;

DECLARE @subLevelId INT = (
    SELECT TOP (1) id
    FROM dbo.sub_levels
    WHERE level_id = @level1Id
      AND order_index = 1
);

IF NOT EXISTS (
    SELECT 1
    FROM dbo.content_items
    WHERE sub_level_id = @subLevelId
      AND order_index = 1
)
BEGIN
    INSERT INTO dbo.content_items (sub_level_id, item_type, order_index, content_text, phonetic)
    VALUES
        (@subLevelId, 'PROMPT', 1, N'Hello, my name is Lucy.', NULL),
        (@subLevelId, 'PROMPT', 2, N'Nice to meet you.', NULL);
END;

IF OBJECT_ID('dbo.ai_support_questions', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM dbo.ai_support_questions
       WHERE sub_level_id = @subLevelId
         AND trigger_minute = 1
   )
BEGIN
    INSERT INTO dbo.ai_support_questions (sub_level_id, question_text, trigger_minute, language_id, order_index)
    VALUES (
        @subLevelId,
        N'Ask each learner to introduce their name and one hobby.',
        1,
        (SELECT TOP (1) id FROM dbo.languages WHERE code = 'EN'),
        1
    );
END;
GO
