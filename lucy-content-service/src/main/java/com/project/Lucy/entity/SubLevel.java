package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

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

    private Integer orderIndex; // Thứ tự trong buổi học
    private String title; // Tên chặng
    private String phonetic; // Phiên âm
    private Integer durationMinutes; // 10-20 phút

    @Column(nullable = false)
    private String contentType; // Loại nội dung

    @OneToMany(mappedBy = "subLevel", cascade = CascadeType.ALL)
    private List<ContentItem> contentItems;
}