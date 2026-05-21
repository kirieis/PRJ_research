package com.project.Lucy.repository;

import com.project.Lucy.entity.Level;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LevelRepository extends JpaRepository<Level, Long> {
    List<Level> findByLanguage_Id(Long languageId);

    List<Level> findByLanguage_IdAndStageNumber(Long languageId, int stageNumber);

    List<Level> findByIsPublishedTrue();
}