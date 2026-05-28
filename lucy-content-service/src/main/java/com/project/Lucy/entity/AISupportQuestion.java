package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Map với bảng ai_support_questions trong LucyDB.
 * Gợi ý thảo luận hiển thị cho Moderator/Pro theo mốc phút.
 *
 * Stored Procedure sp_GetAISupportByMinute được Dev 2 viết trong DB.
 * Dev 1 khai báo ở đây để Spring JPA có thể gọi trực tiếp.
 * Dev 1 - Tuần 6-7
 *
 * Fix Tuần 8-10 (double-check):
 * - Bỏ @AllArgsConstructor (conflict với field default orderIndex = 1)
 * - Thêm @EqualsAndHashCode(onlyExplicitlyIncluded = true) để tránh infinite loop
 *   khi Lombok @Data tự sinh hashCode qua @ManyToOne proxy chain.
 */
@Entity
@Table(name = "ai_support_questions")

// Khai báo Stored Procedure để gọi từ repository
@NamedStoredProcedureQuery(
    name  = "AISupportQuestion.getByMinute",
    procedureName = "sp_GetAISupportByMinute",
    resultClasses = AISupportQuestion.class,
    parameters = {
        @StoredProcedureParameter(mode = ParameterMode.IN, name = "sub_level_id",   type = Integer.class),
        @StoredProcedureParameter(mode = ParameterMode.IN, name = "current_minute", type = Integer.class)
    }
)

@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"subLevel", "language"})
public class AISupportQuestion {

    @EqualsAndHashCode.Include
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sub_level_id", nullable = false)
    private SubLevel subLevel;

    @Column(name = "question_text", nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String questionText;

    /**
     * Phút thứ mấy trong Sub-level thì câu gợi ý này xuất hiện.
     * Node.js Timer Module tick mỗi phút và gọi Stored Procedure này.
     */
    @Column(name = "trigger_minute", nullable = false)
    private Integer triggerMinute;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "language_id")
    private Language language;

    @Column(name = "order_index", nullable = false)
    private Integer orderIndex = 1;
}
