package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

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
    private Language language; // ✅ FK thẳng tới Language

    private Integer stageNumber; // 1=Sơ cấp, 2=Trung cấp, 3=Cao cấp
    private Integer levelNumber; // 1 → 100
    private String topicName; // Tên chủ đề
    private String targetOutcome; // Mục tiêu đầu ra
    private Boolean isPublished = false;

    @OneToMany(mappedBy = "level", cascade = CascadeType.ALL)
    private List<SubLevel> subLevels;
}