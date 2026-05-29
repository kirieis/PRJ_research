package com.project.Lucy.controller;

import com.project.Lucy.dto.request.PodcastRequest;
import com.project.Lucy.dto.response.PodcastResponse;
import com.project.Lucy.service.PodcastService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/podcasts")
@RequiredArgsConstructor
@Tag(name = "Podcast", description = "APIs for podcast management")
public class PodcastController {

    private final PodcastService podcastService;

    @GetMapping
    @Operation(summary = "Lấy tất cả podcast công khai")
    public ResponseEntity<List<PodcastResponse>> getAllPublicPodcasts() {
        return ResponseEntity.ok(podcastService.getAllPublicPodcasts());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Lấy podcast theo ID")
    public ResponseEntity<PodcastResponse> getPodcastById(@PathVariable Long id) {
        return ResponseEntity.ok(podcastService.getPodcastById(id));
    }

    @GetMapping("/creator/{creatorId}")
    @Operation(summary = "Lấy podcast theo creator")
    public ResponseEntity<List<PodcastResponse>> getPodcastsByCreator(@PathVariable Long creatorId) {
        return ResponseEntity.ok(podcastService.getPodcastsByCreator(creatorId));
    }

    @GetMapping("/level/{levelId}")
    @Operation(summary = "Lấy podcast theo level")
    public ResponseEntity<List<PodcastResponse>> getPodcastsByLevel(@PathVariable Long levelId) {
        return ResponseEntity.ok(podcastService.getPodcastsByLevel(levelId));
    }

    // TODO: Restrict to SUPER user only — add @PreAuthorize("hasRole('SUPER')") khi
    // có Spring Security
    @PostMapping
    @Operation(summary = "Tạo podcast mới (chỉ SUPER user)")
    public ResponseEntity<PodcastResponse> createPodcast(@Valid @RequestBody PodcastRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(podcastService.createPodcast(request));
    }
}