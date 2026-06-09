package com.project.Lucy.repository;

import com.project.Lucy.entity.Podcast;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PodcastRepository extends JpaRepository<Podcast, Long> {

    // ─── JOIN FETCH creator + level — tránh N+1 trong toResponse() ─────────

    @Query("SELECT p FROM Podcast p " +
            "JOIN FETCH p.creator " +
            "JOIN FETCH p.level " +
            "WHERE p.isPublic = true " +
            "ORDER BY p.createdAt DESC")
    List<Podcast> findPublicPodcastsFetch();

    @Query("SELECT p FROM Podcast p " +
            "JOIN FETCH p.creator " +
            "JOIN FETCH p.level " +
            "WHERE p.creator.id = :creatorId " +
            "ORDER BY p.createdAt DESC")
    List<Podcast> findByCreatorIdFetch(@Param("creatorId") Long creatorId);

    @Query("SELECT p FROM Podcast p " +
            "JOIN FETCH p.creator " +
            "JOIN FETCH p.level " +
            "WHERE p.level.id = :levelId AND p.isPublic = true")
    List<Podcast> findByLevelIdFetch(@Param("levelId") Long levelId);

    @Query("SELECT p FROM Podcast p " +
            "JOIN FETCH p.creator " +
            "JOIN FETCH p.level " +
            "WHERE p.id = :id")
    Optional<Podcast> findByIdFetch(@Param("id") Long id);

    // Giữ lại các method cũ để không break chỗ khác
    List<Podcast> findByIsPublicTrueOrderByCreatedAtDesc();

    List<Podcast> findByCreatorIdOrderByCreatedAtDesc(Long creatorId);

    List<Podcast> findByLevelIdAndIsPublicTrue(Long levelId);
}