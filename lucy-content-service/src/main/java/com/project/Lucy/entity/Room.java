package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "rooms")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Room {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "host_id", nullable = false)
    private User host;

    @ManyToOne
    @JoinColumn(name = "level_id", nullable = false)
    private Level level;

    @ManyToOne
    @JoinColumn(name = "current_sub_level_id")
    private SubLevel currentSubLevel;

    @Column(nullable = false)
    private String status; // WAITING | LIVE | ENDED

    private String agoraChannelName;
    private Integer maxParticipants = 50;
    private LocalDateTime createdAt;
    private LocalDateTime endedAt;
}