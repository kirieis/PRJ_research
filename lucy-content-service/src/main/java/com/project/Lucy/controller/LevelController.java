package com.project.Lucy.controller;

import com.project.Lucy.dto.response.LevelResponse;
import com.project.Lucy.service.LevelService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/levels")
@RequiredArgsConstructor
@Tag(name = "Levels", description = "Quản lý cấp độ học tập")
public class LevelController {

    private final LevelService levelService;

    @GetMapping
    @Operation(summary = "Lấy Level theo languageId (+ stageNumber tùy chọn)")
    public List<LevelResponse> getLevels(
            @RequestParam Long languageId,
            @RequestParam(required = false) Integer stageNumber) {
        if (stageNumber != null) {
            return levelService.getByLanguageAndStage(languageId, stageNumber);
        }
        return levelService.getByLanguage(languageId);
    }

    @GetMapping("/published")
    @Operation(summary = "Lấy tất cả Level đã published")
    public List<LevelResponse> getPublished() {
        return levelService.getPublished();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Lấy Level theo ID")
    public LevelResponse getById(@PathVariable Long id) {
        return levelService.getById(id);
    }
}