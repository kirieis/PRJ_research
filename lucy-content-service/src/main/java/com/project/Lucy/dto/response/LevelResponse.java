package com.project.Lucy.dto.response;

import lombok.Data;

@Data
public class LevelResponse {
    private Long id;
    private Long languageId;
    private String languageName;
    private Integer stageNumber;
    private Integer levelNumber;
    private String topicName;
    private String targetOutcome;
    private Boolean isPublished;
}