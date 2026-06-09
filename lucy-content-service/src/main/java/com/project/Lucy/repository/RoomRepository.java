package com.project.Lucy.repository;

import com.project.Lucy.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface RoomRepository extends JpaRepository<Room, Long> {

    // ─── JOIN FETCH host + level + currentSubLevel — tránh N+1 trong toResponse()
    // ───

    @Query("SELECT r FROM Room r " +
            "JOIN FETCH r.host " +
            "JOIN FETCH r.level " +
            "LEFT JOIN FETCH r.currentSubLevel " +
            "WHERE r.status = :status")
    List<Room> findByStatusFetch(@Param("status") String status);

    @Query("SELECT r FROM Room r " +
            "JOIN FETCH r.host " +
            "JOIN FETCH r.level " +
            "LEFT JOIN FETCH r.currentSubLevel " +
            "WHERE r.level.id = :levelId")
    List<Room> findByLevelIdFetch(@Param("levelId") Long levelId);

    @Query("SELECT r FROM Room r " +
            "JOIN FETCH r.host " +
            "JOIN FETCH r.level " +
            "LEFT JOIN FETCH r.currentSubLevel " +
            "WHERE r.id = :id")
    Optional<Room> findByIdFetch(@Param("id") Long id);

    // Giữ lại các method cũ để DataLoader / các chỗ khác không bị break
    List<Room> findByStatus(String status);

    List<Room> findByLevel_Id(Long levelId);
}