package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Bảng lưu URL tài nguyên (slide, hình ảnh) mà Host ghim vào phòng học.
 * Dev 1 - Tuần 6-7
 *
 * Fix Tuần 8-10 (double-check):
 * - Thay @Data bằng @Getter/@Setter + @EqualsAndHashCode(onlyExplicitlyIncluded = true)
 *   để tránh Lombok sinh hashCode/toString đi qua @ManyToOne(LAZY) proxy → StackOverflow.
 * - Thêm @ToString(exclude = "room") để tránh in cả Room entity khi log.
 */
@Entity
@Table(name = "room_resources")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = "room")
public class RoomResource {

    @EqualsAndHashCode.Include
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(name = "resource_url", nullable = false, length = 1000)
    private String resourceUrl;

    /**
     * Loại tài nguyên: IMAGE | SLIDE | DOCUMENT
     */
    @Column(name = "resource_type", nullable = false, length = 50)
    private String resourceType;

    /**
     * Tiêu đề tuỳ chọn hiển thị cho học viên
     */
    @Column(name = "title", columnDefinition = "NVARCHAR(255)")
    private String title;

    /**
     * Thứ tự hiển thị trong phòng (để Host sắp xếp lại được)
     */
    @Column(name = "order_index", nullable = false)
    private Integer orderIndex = 1;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
