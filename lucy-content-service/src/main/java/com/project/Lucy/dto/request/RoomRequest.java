package com.project.Lucy.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RoomRequest {
    @NotNull
    private Long hostId;
    @NotNull
    private Long levelId;
    private Integer maxParticipants = 50;
}