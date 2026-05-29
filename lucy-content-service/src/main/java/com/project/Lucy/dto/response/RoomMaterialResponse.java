package com.project.Lucy.dto.response;

import com.project.Lucy.entity.RoomMaterial.FileType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomMaterialResponse {

    private Long id;
    private Long roomId;
    private String fileUrl;
    private FileType fileType;
    private Long pinnedBy;
    private LocalDateTime createdAt;
}