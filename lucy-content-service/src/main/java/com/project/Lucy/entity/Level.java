package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "levels")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Level {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "language_id", nullable = false)
    private Language language;

    private Integer stageNumber; // 1, 2, 3
    private Integer levelNumber; // 1 to 100
    
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String topicName;
    
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String targetOutcome;
    
    @Column(name = "is_published")
    private Boolean isPublished = false;
}
