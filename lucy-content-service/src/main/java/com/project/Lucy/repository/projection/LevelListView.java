package com.project.Lucy.repository.projection;

public interface LevelListView {
    Long getId();
    Long getLanguageId();
    String getLanguageName();
    Integer getStageNumber();
    Integer getLevelNumber();
    String getTopicName();
    String getTargetOutcome();
    Boolean getIsPublished();
}
