package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sub_levels")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubLevel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "level_id", nullable = false)
    private Level level;

    private Integer orderIndex;
    
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String title;
    
    private String phonetic;
    private Integer durationMinutes;
}
