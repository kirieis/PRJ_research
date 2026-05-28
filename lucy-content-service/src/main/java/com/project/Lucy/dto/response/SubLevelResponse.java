package com.project.Lucy.dto.response;

import lombok.Data;

@Data
public class SubLevelResponse {
    private Long id;
    private Long levelId;
    private Integer orderIndex;
    private String title;
    private String phonetic;
    private Integer durationMinutes;
    private String contentType;
}