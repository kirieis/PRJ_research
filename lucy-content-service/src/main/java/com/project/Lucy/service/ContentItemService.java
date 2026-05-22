package com.project.Lucy.service;

import com.project.Lucy.dto.response.ContentItemResponse;
import com.project.Lucy.entity.ContentItem;
import com.project.Lucy.repository.ContentItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContentItemService {

    private final ContentItemRepository contentItemRepository;

    public List<ContentItemResponse> getBySubLevel(Long subLevelId) {
        return contentItemRepository.findBySubLevel_IdOrderByOrderIndex(subLevelId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private ContentItemResponse toResponse(ContentItem ci) {
        ContentItemResponse dto = new ContentItemResponse();
        dto.setId(ci.getId());
        dto.setSubLevelId(ci.getSubLevel().getId());
        dto.setItemType(ci.getItemType());
        dto.setOrderIndex(ci.getOrderIndex());
        dto.setContentText(ci.getContentText());
        dto.setPhonetic(ci.getPhonetic());
        return dto;
    }
}
