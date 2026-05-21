package com.project.Lucy.dto.response;

import lombok.Data;

@Data
public class ContentItemResponse {
    private Long id;
    private Long subLevelId;
    private String itemType;
    private Integer orderIndex;
    private String contentText;
    private String phonetic;
}