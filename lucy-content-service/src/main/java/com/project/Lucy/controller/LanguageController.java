package com.project.Lucy.controller;

import com.project.Lucy.dto.response.LanguageResponse;
import com.project.Lucy.service.LanguageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/languages")
@RequiredArgsConstructor
@Tag(name = "Languages", description = "Quản lý ngôn ngữ học")
public class LanguageController {

    private final LanguageService languageService;

    @GetMapping
    @Operation(summary = "Lấy tất cả ngôn ngữ")
    public List<LanguageResponse> getAll() {
        return languageService.getAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Lấy ngôn ngữ theo ID")
    public LanguageResponse getById(@PathVariable Long id) {
        return languageService.getById(id);
    }
}