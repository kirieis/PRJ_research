package com.project.Lucy.repository;

import com.project.Lucy.entity.RoomResource;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

/**
 * Repository cho bảng room_resources.
 * Dùng bởi API POST /api/rooms/{id}/pin-resource (Dev 3 - Tuần 6-7)
 */
public interface RoomResourceRepository extends JpaRepository<RoomResource, Long> {

    /**
     * Lấy toàn bộ tài nguyên của một phòng, sắp xếp theo thứ tự ghim.
     */
    List<RoomResource> findByRoom_IdOrderByOrderIndexAsc(Long roomId);

    /**
     * Lấy tài nguyên theo loại (IMAGE, SLIDE, DOCUMENT).
     */
    List<RoomResource> findByRoom_IdAndResourceType(Long roomId, String resourceType);
}
