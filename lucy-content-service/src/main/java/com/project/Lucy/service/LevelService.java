package com.project.Lucy.service;

import com.project.Lucy.dto.response.LevelResponse;
import com.project.Lucy.entity.Level;
import com.project.Lucy.repository.LevelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LevelService {

    private final LevelRepository levelRepository;

    public List<LevelResponse> getByLanguage(Long languageId) {
        return levelRepository.findByLanguage_Id(languageId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public List<LevelResponse> getByLanguageAndStage(Long languageId, int stageNumber) {
        return levelRepository.findByLanguage_IdAndStageNumber(languageId, stageNumber)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public List<LevelResponse> getPublished() {
        return levelRepository.findByIsPublishedTrue()
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public LevelResponse getById(Long id) {
        Level level = levelRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Level not found: " + id));
        return toResponse(level);
    }

    private LevelResponse toResponse(Level level) {
        LevelResponse dto = new LevelResponse();
        dto.setId(level.getId());
        dto.setLanguageId(level.getLanguage().getId());
        dto.setLanguageName(level.getLanguage().getName());
        dto.setStageNumber(level.getStageNumber());
        dto.setLevelNumber(level.getLevelNumber());
        dto.setTopicName(level.getTopicName());
        dto.setTargetOutcome(level.getTargetOutcome());
        dto.setIsPublished(level.getIsPublished());
        return dto;
    }
}