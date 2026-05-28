package com.project.Lucy.repository;

import com.project.Lucy.entity.Level;
import com.project.Lucy.repository.projection.LevelListView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

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

    @Query("SELECT l FROM Level l JOIN FETCH l.language WHERE l.language.id = :languageId")
    List<Level> findByLanguageIdFetch(@Param("languageId") Long languageId);

    @Query("SELECT l FROM Level l JOIN FETCH l.language WHERE l.language.id = :languageId AND l.stageNumber = :stageNumber ORDER BY l.levelNumber ASC")
    List<Level> findByLanguageIdAndStageNumberFetch(@Param("languageId") Long languageId,
                                                    @Param("stageNumber") Integer stageNumber);

    @Query("SELECT l FROM Level l JOIN FETCH l.language WHERE l.isPublished = true ORDER BY l.stageNumber ASC, l.levelNumber ASC")
    List<Level> findAllPublishedFetch();

    @Query("SELECT l FROM Level l JOIN FETCH l.language WHERE l.id = :id")
    Optional<Level> findByIdFetch(@Param("id") Long id);
}
