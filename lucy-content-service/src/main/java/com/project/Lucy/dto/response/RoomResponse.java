package com.project.Lucy.dto.response;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class RoomResponse {
    private Long id;
    private Long hostId;
    private String hostDisplayName;
    private Long levelId;
    private String levelTopicName;
    private Long currentSubLevelId;
    private String status;
    private String agoraChannelName;
    private Integer maxParticipants;
    private LocalDateTime createdAt;
}