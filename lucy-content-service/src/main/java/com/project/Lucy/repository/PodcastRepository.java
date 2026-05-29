package com.project.Lucy.repository;

import com.project.Lucy.entity.Podcast;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PodcastRepository extends JpaRepository<Podcast, Long> {

    // Lấy tất cả podcast công khai, mới nhất trước
    List<Podcast> findByIsPublicTrueOrderByCreatedAtDesc();

    // Lấy podcast theo creator
    List<Podcast> findByCreatorIdOrderByCreatedAtDesc(Long creatorId);

    // Lấy podcast công khai theo level (dùng cho màn học theo lộ trình)
    List<Podcast> findByLevelIdAndIsPublicTrue(Long levelId);
}