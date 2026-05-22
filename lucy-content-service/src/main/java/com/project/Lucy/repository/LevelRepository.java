package com.project.Lucy.repository;

import com.project.Lucy.entity.Level;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LevelRepository extends JpaRepository<Level, Long> {
    Level findByLanguageIdAndStageNumberAndLevelNumber(Long languageId, Integer stageNumber, Integer levelNumber);
    List<Level> findByLanguageId(Long languageId);
}
