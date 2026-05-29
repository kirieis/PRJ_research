package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "room_materials")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoomMaterial {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(nullable = false)
    private String fileUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FileType fileType;

    // Lưu user_id trực tiếp, không FK để tránh coupling với User entity
    @Column(nullable = false)
    private Long pinnedBy;

    private LocalDateTime createdAt;

    public enum FileType {
        PDF, DOCX, IMAGE
    }
}