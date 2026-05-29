package com.project.Lucy.controller;

import com.project.Lucy.dto.response.RoomMaterialResponse;
import com.project.Lucy.service.RoomMaterialService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/rooms/{roomId}/materials")
@RequiredArgsConstructor
@Tag(name = "Room Materials", description = "APIs for pinning and managing room materials (LMS Pro)")
public class RoomMaterialController {

    private final RoomMaterialService roomMaterialService;

    @GetMapping
    @Operation(summary = "Lấy tất cả tài liệu của phòng")
    public ResponseEntity<List<RoomMaterialResponse>> getMaterials(@PathVariable Long roomId) {
        return ResponseEntity.ok(roomMaterialService.getMaterialsByRoom(roomId));
    }

    // TODO: Restrict to PRO user only — add @PreAuthorize("hasRole('PRO')") khi có
    // Spring Security
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Ghim tài liệu vào phòng (chỉ PRO user) — hỗ trợ PDF, DOCX, Image (max 20MB)")
    public ResponseEntity<RoomMaterialResponse> pinMaterial(
            @PathVariable Long roomId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("pinnedBy") Long pinnedBy) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(roomMaterialService.pinMaterial(roomId, file, pinnedBy));
    }

    // TODO: Restrict to PRO user (owner) or SUPER only
    @DeleteMapping("/{matId}")
    @Operation(summary = "Xóa tài liệu khỏi phòng")
    public ResponseEntity<Void> deleteMaterial(
            @PathVariable Long roomId,
            @PathVariable Long matId) {
        roomMaterialService.deleteMaterial(roomId, matId);
        return ResponseEntity.noContent().build();
    }
}