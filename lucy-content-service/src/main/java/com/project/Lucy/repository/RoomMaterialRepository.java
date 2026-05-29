package com.project.Lucy.repository;

import com.project.Lucy.entity.RoomMaterial;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomMaterialRepository extends JpaRepository<RoomMaterial, Long> {

    // Lấy tất cả tài liệu của một phòng, mới nhất trước
    List<RoomMaterial> findByRoomIdOrderByCreatedAtDesc(Long roomId);

    // Kiểm tra tài liệu có thuộc phòng không (dùng khi DELETE)
    boolean existsByIdAndRoomId(Long id, Long roomId);
}