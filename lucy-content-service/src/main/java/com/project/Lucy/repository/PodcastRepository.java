package com.project.Lucy.repository;

import com.project.Lucy.entity.Podcast;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PodcastRepository extends JpaRepository<Podcast, Long> {
    List<Podcast> findByIsPublicTrueOrderByCreatedAtDesc();

    List<Podcast> findByCreator_Id(Long creatorId);
}