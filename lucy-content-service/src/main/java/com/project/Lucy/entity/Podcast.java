package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "podcasts")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Podcast {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "creator_id", nullable = false)
    private User creator;

    @ManyToOne
    @JoinColumn(name = "level_id", nullable = false)
    private Level level;

    private String audioUrl;
    private String title;
    private String description;
    private Integer durationSeconds;
    private Boolean isPublic = true;
    private LocalDateTime createdAt;
}