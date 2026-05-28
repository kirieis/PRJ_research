package com.project.Lucy.repository;

import com.project.Lucy.entity.SubLevel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface SubLevelRepository extends JpaRepository<SubLevel, Long> {
    SubLevel findByLevelIdAndOrderIndex(Long levelId, Integer orderIndex);
    List<SubLevel> findByLevelId(Long levelId);
    List<SubLevel> findByLevelIdOrderByOrderIndex(Long levelId);

    // ─── Dev 1 Tuần 8-9: JOIN FETCH 2 tầng (SubLevel → Level → Language) ────
    @Query("SELECT s FROM SubLevel s JOIN FETCH s.level l JOIN FETCH l.language WHERE s.level.id = :levelId ORDER BY s.orderIndex ASC")
    List<SubLevel> findByLevelIdFetch(@Param("levelId") Long levelId);

    @Query("SELECT s FROM SubLevel s JOIN FETCH s.level l JOIN FETCH l.language WHERE s.level.id = :levelId ORDER BY s.orderIndex ASC")
    List<SubLevel> findByLevelIdOrderByOrderIndexFetch(@Param("levelId") Long levelId);
}

