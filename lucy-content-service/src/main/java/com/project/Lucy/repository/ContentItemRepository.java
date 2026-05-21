package com.project.Lucy.repository;

import com.project.Lucy.entity.ContentItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ContentItemRepository extends JpaRepository<ContentItem, Long> {
    List<ContentItem> findBySubLevel_IdOrderByOrderIndex(Long subLevelId);
}