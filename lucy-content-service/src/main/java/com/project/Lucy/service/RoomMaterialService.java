package com.project.Lucy.service;

import com.project.Lucy.dto.response.RoomMaterialResponse;
import com.project.Lucy.entity.Room;
import com.project.Lucy.entity.RoomMaterial;
import com.project.Lucy.repository.RoomMaterialRepository;
import com.project.Lucy.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomMaterialService {

    private final RoomMaterialRepository roomMaterialRepository;
    private final RoomRepository roomRepository;
    private final FileStorageService fileStorageService;

    // GET /api/rooms/{roomId}/materials
    public List<RoomMaterialResponse> getMaterialsByRoom(Long roomId) {
        // Kiểm tra phòng tồn tại
        if (!roomRepository.existsById(roomId)) {
            throw new RuntimeException("Room not found: " + roomId);
        }
        return roomMaterialRepository.findByRoomIdOrderByCreatedAtDesc(roomId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // POST /api/rooms/{roomId}/materials — TODO: chỉ PRO user mới được ghim tài
    // liệu
    @Transactional
    public RoomMaterialResponse pinMaterial(Long roomId, MultipartFile file, Long pinnedBy) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found: " + roomId));

        // Upload file → lấy URL + detect type
        String fileUrl = fileStorageService.store(file);
        RoomMaterial.FileType fileType = fileStorageService.detectFileType(file);

        RoomMaterial material = new RoomMaterial();
        material.setRoom(room);
        material.setFileUrl(fileUrl);
        material.setFileType(fileType);
        material.setPinnedBy(pinnedBy);
        material.setCreatedAt(LocalDateTime.now());

        return toResponse(roomMaterialRepository.save(material));
    }

    // DELETE /api/rooms/{roomId}/materials/{matId}
    // TODO: chỉ PRO user đã ghim hoặc SUPER mới được xóa
    @Transactional
    public void deleteMaterial(Long roomId, Long matId) {
        // Kiểm tra material có thuộc phòng này không
        if (!roomMaterialRepository.existsByIdAndRoomId(matId, roomId)) {
            throw new RuntimeException("Material not found: " + matId + " in room: " + roomId);
        }

        RoomMaterial material = roomMaterialRepository.findById(matId)
                .orElseThrow(() -> new RuntimeException("Material not found: " + matId));

        // Xóa file khỏi storage trước, rồi xóa DB record
        fileStorageService.delete(material.getFileUrl());
        roomMaterialRepository.deleteById(matId);
    }

    // ── Mapper ──────────────────────────────────────────────────────────────
    private RoomMaterialResponse toResponse(RoomMaterial material) {
        return RoomMaterialResponse.builder()
                .id(material.getId())
                .roomId(material.getRoom().getId())
                .fileUrl(material.getFileUrl())
                .fileType(material.getFileType())
                .pinnedBy(material.getPinnedBy())
                .createdAt(material.getCreatedAt())
                .build();
    }
}