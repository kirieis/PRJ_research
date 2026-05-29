package com.project.Lucy.service;

import com.project.Lucy.dto.request.PodcastRequest;
import com.project.Lucy.dto.response.PodcastResponse;
import com.project.Lucy.entity.Level;
import com.project.Lucy.entity.Podcast;
import com.project.Lucy.entity.User;
import com.project.Lucy.repository.LevelRepository;
import com.project.Lucy.repository.PodcastRepository;
import com.project.Lucy.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PodcastService {

    private final PodcastRepository podcastRepository;
    private final UserRepository userRepository;
    private final LevelRepository levelRepository;

    // GET /api/podcasts — tất cả podcast công khai
    public List<PodcastResponse> getAllPublicPodcasts() {
        return podcastRepository.findByIsPublicTrueOrderByCreatedAtDesc()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // GET /api/podcasts/creator/{creatorId}
    public List<PodcastResponse> getPodcastsByCreator(Long creatorId) {
        return podcastRepository.findByCreatorIdOrderByCreatedAtDesc(creatorId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // GET /api/podcasts/level/{levelId}
    public List<PodcastResponse> getPodcastsByLevel(Long levelId) {
        return podcastRepository.findByLevelIdAndIsPublicTrue(levelId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // GET /api/podcasts/{id}
    public PodcastResponse getPodcastById(Long id) {
        Podcast podcast = podcastRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Podcast not found: " + id));
        return toResponse(podcast);
    }

    // POST /api/podcasts — TODO: chỉ cho phép SUPER user gọi endpoint này
    public PodcastResponse createPodcast(PodcastRequest request) {
        User creator = userRepository.findById(request.getCreatorId())
                .orElseThrow(() -> new RuntimeException("User not found: " + request.getCreatorId()));

        Level level = levelRepository.findById(request.getLevelId())
                .orElseThrow(() -> new RuntimeException("Level not found: " + request.getLevelId()));

        Podcast podcast = new Podcast();
        podcast.setTitle(request.getTitle());
        podcast.setDescription(request.getDescription());
        podcast.setAudioUrl(request.getAudioUrl());
        podcast.setDurationSeconds(request.getDurationSeconds());
        podcast.setIsPublic(request.getIsPublic() != null ? request.getIsPublic() : true);
        podcast.setCreator(creator);
        podcast.setLevel(level);
        podcast.setCreatedAt(LocalDateTime.now());

        return toResponse(podcastRepository.save(podcast));
    }

    // ── Mapper ──────────────────────────────────────────────────────────────
    private PodcastResponse toResponse(Podcast podcast) {
        return PodcastResponse.builder()
                .id(podcast.getId())
                .title(podcast.getTitle())
                .description(podcast.getDescription())
                .audioUrl(podcast.getAudioUrl())
                .durationSeconds(podcast.getDurationSeconds())
                .isPublic(podcast.getIsPublic())
                .createdAt(podcast.getCreatedAt())
                .creator(PodcastResponse.CreatorInfo.builder()
                        .id(podcast.getCreator().getId())
                        .username(podcast.getCreator().getDisplayName())
                        .build())
                .level(PodcastResponse.LevelInfo.builder()
                        .id(podcast.getLevel().getId())
                        .topicName(podcast.getLevel().getTopicName())
                        .stageNumber(podcast.getLevel().getStageNumber())
                        .build())
                .build();
    }
}