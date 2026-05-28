package com.project.Lucy.repository;

import com.project.Lucy.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RoomRepository extends JpaRepository<Room, Long> {
    List<Room> findByStatus(String status);

    List<Room> findByLevel_Id(Long levelId);
}