package com.project.Lucy.service;

import com.project.Lucy.dto.request.RoomRequest;
import com.project.Lucy.dto.response.RoomResponse;
import com.project.Lucy.entity.Level;
import com.project.Lucy.entity.Room;
import com.project.Lucy.entity.SubLevel;
import com.project.Lucy.entity.User;
import com.project.Lucy.repository.LevelRepository;
import com.project.Lucy.repository.RoomRepository;
import com.project.Lucy.repository.SubLevelRepository;
import com.project.Lucy.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomService {

    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final LevelRepository levelRepository;
    private final SubLevelRepository subLevelRepository;

    public List<RoomResponse> getLiveRooms() {
        return roomRepository.findByStatus("LIVE")
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public List<RoomResponse> getRoomsByLevel(Long levelId) {
        return roomRepository.findByLevel_Id(levelId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public RoomResponse createRoom(RoomRequest request) {
        User host = userRepository.findById(request.getHostId())
                .orElseThrow(() -> new RuntimeException("User not found: " + request.getHostId()));
        Level level = levelRepository.findById(request.getLevelId())
                .orElseThrow(() -> new RuntimeException("Level not found: " + request.getLevelId()));

        Room room = new Room();
        room.setHost(host);
        room.setLevel(level);
        room.setStatus("WAITING");
        room.setMaxParticipants(request.getMaxParticipants());
        room.setAgoraChannelName("lucy-" + UUID.randomUUID().toString().substring(0, 8));
        room.setCreatedAt(LocalDateTime.now());

        return toResponse(roomRepository.save(room));
    }

    public RoomResponse updateStatus(Long roomId, String status) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found: " + roomId));
        room.setStatus(status);
        if ("ENDED".equals(status))
            room.setEndedAt(LocalDateTime.now());
        return toResponse(roomRepository.save(room));
    }

    private RoomResponse toResponse(Room room) {
        RoomResponse dto = new RoomResponse();
        dto.setId(room.getId());
        dto.setHostId(room.getHost().getId());
        dto.setHostDisplayName(room.getHost().getDisplayName());
        dto.setLevelId(room.getLevel().getId());
        dto.setLevelTopicName(room.getLevel().getTopicName());
        if (room.getCurrentSubLevel() != null)
            dto.setCurrentSubLevelId(room.getCurrentSubLevel().getId());
        dto.setStatus(room.getStatus());
        dto.setAgoraChannelName(room.getAgoraChannelName());
        dto.setMaxParticipants(room.getMaxParticipants());
        dto.setCreatedAt(room.getCreatedAt());
        return dto;
    }

    public RoomResponse getById(Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found: " + roomId));
        return toResponse(room);
    }

    public RoomResponse updateCurrentSubLevel(Long roomId, Long subLevelId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found: " + roomId));
        SubLevel subLevel = subLevelRepository.findById(subLevelId)
                .orElseThrow(() -> new RuntimeException("SubLevel not found: " + subLevelId));
        room.setCurrentSubLevel(subLevel);
        return toResponse(roomRepository.save(room));
    }
}
