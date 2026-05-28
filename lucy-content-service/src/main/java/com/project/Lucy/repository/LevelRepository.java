package com.project.Lucy.repository;

import com.project.Lucy.entity.Level;
import com.project.Lucy.repository.projection.LevelListView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface LevelRepository extends JpaRepository<Level, Long> {
    Level findByLanguageIdAndStageNumberAndLevelNumber(Long languageId, Integer stageNumber, Integer levelNumber);
    List<Level> findByLanguageId(Long languageId);
    List<Level> findByLanguageIdAndStageNumber(Long languageId, Integer stageNumber);
    List<Level> findByIsPublishedTrue();

    @Query(value = """
            SELECT
                l.id AS id,
                l.language_id AS languageId,
                lang.name AS languageName,
                l.stage_number AS stageNumber,
                l.level_number AS levelNumber,
                l.topic_name AS topicName,
                l.target_outcome AS targetOutcome,
                l.is_published AS isPublished
            FROM dbo.levels l
            INNER JOIN dbo.languages lang ON lang.id = l.language_id
            WHERE l.language_id = :languageId
            ORDER BY l.stage_number, l.level_number
            """, nativeQuery = true)
    List<LevelListView> findLevelListByLanguageNative(@Param("languageId") Long languageId);

    @Query(value = """
            SELECT
                l.id AS id,
                l.language_id AS languageId,
                lang.name AS languageName,
                l.stage_number AS stageNumber,
                l.level_number AS levelNumber,
                l.topic_name AS topicName,
                l.target_outcome AS targetOutcome,
                l.is_published AS isPublished
            FROM dbo.levels l
            INNER JOIN dbo.languages lang ON lang.id = l.language_id
            WHERE l.language_id = :languageId
              AND l.stage_number = :stageNumber
            ORDER BY l.level_number
            """, nativeQuery = true)
    List<LevelListView> findLevelListByLanguageAndStageNative(
            @Param("languageId") Long languageId,
            @Param("stageNumber") Integer stageNumber);

    @Query(value = """
            SELECT
                l.id AS id,
                l.language_id AS languageId,
                lang.name AS languageName,
                l.stage_number AS stageNumber,
                l.level_number AS levelNumber,
                l.topic_name AS topicName,
                l.target_outcome AS targetOutcome,
                l.is_published AS isPublished
            FROM dbo.levels l
            INNER JOIN dbo.languages lang ON lang.id = l.language_id
            WHERE l.is_published = 1
            ORDER BY lang.code, l.stage_number, l.level_number
            """, nativeQuery = true)
    List<LevelListView> findPublishedLevelListNative();
}
