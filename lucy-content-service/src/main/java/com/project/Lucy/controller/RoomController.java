package com.project.Lucy.controller;

import com.project.Lucy.dto.request.RoomRequest;
import com.project.Lucy.dto.response.RoomResponse;
import com.project.Lucy.service.RoomService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/rooms")
@RequiredArgsConstructor
@Tag(name = "Rooms", description = "Quản lý phòng học real-time")
public class RoomController {

    private final RoomService roomService;

    @GetMapping("/live")
    @Operation(summary = "Lấy tất cả phòng đang LIVE")
    public List<RoomResponse> getLiveRooms() {
        return roomService.getLiveRooms();
    }

    @GetMapping
    @Operation(summary = "Lấy phòng theo levelId")
    public List<RoomResponse> getRoomsByLevel(@RequestParam Long levelId) {
        return roomService.getRoomsByLevel(levelId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Tạo phòng mới (PRO/SUPER)")
    public RoomResponse createRoom(@Valid @RequestBody RoomRequest request) {
        return roomService.createRoom(request);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Cập nhật trạng thái phòng (WAITING/LIVE/ENDED)")
    public RoomResponse updateStatus(@PathVariable Long id, @RequestParam String status) {
        return roomService.updateStatus(id, status);
    }
    // Thêm vào RoomController.java

    // Lấy thông tin 1 phòng theo ID (Dev 4 gọi khi user join)
    @GetMapping("/{id}")
    @Operation(summary = "Lấy thông tin phòng theo ID")
    public RoomResponse getById(@PathVariable Long id) {
        return roomService.getById(id);
    }

    // Cập nhật sub-level hiện tại trong phòng (Dev 4 gọi khi chuyển bài)
    @PatchMapping("/{id}/current-sub-level")
    @Operation(summary = "Cập nhật sub-level đang học trong phòng")
    public RoomResponse updateCurrentSubLevel(
            @PathVariable Long id,
            @RequestParam Long subLevelId) {
        return roomService.updateCurrentSubLevel(id, subLevelId);
    }
}