package com.project.Lucy.repository;

import com.project.Lucy.entity.AISupportQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import java.util.List;

/**
 * Repository cho bảng ai_support_questions.
 *
 * Bao gồm cả cầu nối tới Stored Procedure sp_GetAISupportByMinute
 * do Dev 2 viết trong LucyDB — dùng bởi API GET /api/rooms/{id}/moderator-hints
 * (Dev 3 - Tuần 6-7)
 */
public interface AISupportQuestionRepository extends JpaRepository<AISupportQuestion, Long> {

    /**
     * Gọi thẳng Stored Procedure sp_GetAISupportByMinute trong SQL Server.
     * Trả về tối đa 3 gợi ý gần nhất với phút hiện tại của phòng.
     *
     * @param subLevelId    ID của Sub-level đang chạy trong phòng
     * @param currentMinute Phút hiện tại (từ Timer Module của Node.js)
     * @return Danh sách tối đa 3 câu gợi ý đã đến giờ hiển thị
     */
    @Procedure(name = "AISupportQuestion.getByMinute")
    List<AISupportQuestion> getHintsByMinute(
        @Param("sub_level_id")   Integer subLevelId,
        @Param("current_minute") Integer currentMinute
    );

    /**
     * Lấy toàn bộ câu gợi ý của một Sub-level (dùng để seed dữ liệu).
     */
    List<AISupportQuestion> findBySubLevel_IdOrderByTriggerMinuteAscOrderIndexAsc(Long subLevelId);
}
