package com.project.Lucy.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PodcastRequest {

    @NotBlank(message = "Title is required")
    private String title;

    private String description;

    @NotBlank(message = "Audio URL is required")
    private String audioUrl;

    @NotNull(message = "Duration is required")
    private Integer durationSeconds;

    private Boolean isPublic = true;

    @NotNull(message = "Creator ID is required")
    private Long creatorId;

    @NotNull(message = "Level ID is required")
    private Long levelId;
}