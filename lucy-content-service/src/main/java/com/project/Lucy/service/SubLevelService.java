package com.project.Lucy.service;

import com.project.Lucy.dto.response.SubLevelResponse;
import com.project.Lucy.entity.SubLevel;
import com.project.Lucy.repository.SubLevelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SubLevelService {

    private final SubLevelRepository subLevelRepository;

    public List<SubLevelResponse> getByLevel(Long levelId) {
        return subLevelRepository.findByLevel_IdOrderByOrderIndex(levelId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private SubLevelResponse toResponse(SubLevel sl) {
        SubLevelResponse dto = new SubLevelResponse();
        dto.setId(sl.getId());
        dto.setLevelId(sl.getLevel().getId());
        dto.setOrderIndex(sl.getOrderIndex());
        dto.setTitle(sl.getTitle());
        dto.setPhonetic(sl.getPhonetic());
        dto.setDurationMinutes(sl.getDurationMinutes());
        dto.setContentType(sl.getContentType());
        return dto;
    }
}