package com.project.Lucy.controller;

import com.project.Lucy.dto.response.SubLevelResponse;
import com.project.Lucy.service.SubLevelService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/levels/{levelId}/sub-levels")
@RequiredArgsConstructor
@Tag(name = "SubLevels", description = "Các chặng trong mỗi Level")
public class SubLevelController {

    private final SubLevelService subLevelService;

    @GetMapping
    @Operation(summary = "Lấy tất cả SubLevel của một Level")
    public List<SubLevelResponse> getByLevel(@PathVariable Long levelId) {
        return subLevelService.getByLevel(levelId);
    }
}