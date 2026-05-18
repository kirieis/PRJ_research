package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "content_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ContentItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "sub_level_id", nullable = false)
    private SubLevel subLevel;

    @Column(nullable = false)
    private String itemType; // Loại item

    private Integer orderIndex;

    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String contentText;

    private String phonetic;
}