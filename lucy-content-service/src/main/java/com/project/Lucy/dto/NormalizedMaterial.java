package com.project.Lucy.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class NormalizedMaterial {
    private String language_code;
    private List<Stage> stages;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Stage {
        private int stage_number;
        private List<Level> levels;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Level {
        private int level_number;
        private String topic_name;
        private String target_outcome;
        private boolean incomplete;
        private List<SubLevel> sub_levels;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubLevel {
        private int order_index;
        private String title;
        private String content_type;
        private Integer duration_minutes;
        private List<ContentItem> content_items;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ContentItem {
        private int order_index;
        private String item_type;
        private String content_text;
        private String phonetic;
    }
}
