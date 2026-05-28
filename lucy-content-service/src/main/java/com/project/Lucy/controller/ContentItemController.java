package com.project.Lucy.controller;

import com.project.Lucy.dto.response.ContentItemResponse;
import com.project.Lucy.service.ContentItemService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sub-levels/{subLevelId}/content-items")
@RequiredArgsConstructor
@Tag(name = "ContentItems", description = "Nội dung chi tiết trong mỗi SubLevel")
public class ContentItemController {

    private final ContentItemService contentItemService;

    @GetMapping
    @Operation(summary = "Lấy tất cả ContentItem của một SubLevel")
    public List<ContentItemResponse> getBySubLevel(@PathVariable Long subLevelId) {
        return contentItemService.getBySubLevel(subLevelId);
    }
}