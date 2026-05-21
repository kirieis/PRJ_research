package com.project.Lucy.repository;

import com.project.Lucy.entity.SubLevel;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SubLevelRepository extends JpaRepository<SubLevel, Long> {
    List<SubLevel> findByLevel_IdOrderByOrderIndex(Long levelId);
}