package com.project.Lucy.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PodcastResponse {

    private Long id;
    private String title;
    private String description;
    private String audioUrl;
    private Integer durationSeconds;
    private Boolean isPublic;
    private LocalDateTime createdAt;

    // Nested info — tránh expose toàn bộ User/Level entity
    private CreatorInfo creator;
    private LevelInfo level;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreatorInfo {
        private Long id;
        private String username;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LevelInfo {
        private Long id;
        private String topicName;
        private Integer stageNumber;
    }
}