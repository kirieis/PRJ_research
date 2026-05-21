package com.project.Lucy.service;

import com.project.Lucy.dto.response.LanguageResponse;
import com.project.Lucy.entity.Language;
import com.project.Lucy.repository.LanguageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LanguageService {

    private final LanguageRepository languageRepository;

    public List<LanguageResponse> getAll() {
        return languageRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public LanguageResponse getById(Long id) {
        Language lang = languageRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Language not found: " + id));
        return toResponse(lang);
    }

    private LanguageResponse toResponse(Language lang) {
        LanguageResponse dto = new LanguageResponse();
        dto.setId(lang.getId());
        dto.setName(lang.getName());
        dto.setCode(lang.getCode());
        return dto;
    }
}