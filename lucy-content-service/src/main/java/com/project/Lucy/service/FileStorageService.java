package com.project.Lucy.service;

import com.project.Lucy.entity.RoomMaterial.FileType;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@Service
public class FileStorageService {

    // Cấu hình trong application.properties:
    // file.upload-dir=uploads/room-materials
    // file.base-url=http://localhost:8080/files
    @Value("${file.upload-dir:uploads/room-materials}")
    private String uploadDir;

    @Value("${file.base-url:http://localhost:8080/files}")
    private String baseUrl;

    // Map MIME type → FileType enum
    private static final Map<String, FileType> MIME_TO_TYPE = Map.of(
            "application/pdf", FileType.PDF,
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document", FileType.DOCX,
            "application/msword", FileType.DOCX,
            "image/jpeg", FileType.IMAGE,
            "image/png", FileType.IMAGE,
            "image/gif", FileType.IMAGE,
            "image/webp", FileType.IMAGE);

    /**
     * Lưu file vào local storage, trả về URL public để lưu vào DB.
     */
    public String store(MultipartFile file) {
        validateFile(file);

        try {
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // Tạo tên file unique để tránh trùng
            String originalFilename = file.getOriginalFilename();
            String extension = getExtension(originalFilename);
            String uniqueFilename = UUID.randomUUID() + "." + extension;

            Path targetPath = uploadPath.resolve(uniqueFilename);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            return baseUrl + "/" + uniqueFilename;

        } catch (IOException e) {
            throw new RuntimeException("Failed to store file: " + e.getMessage());
        }
    }

    /**
     * Detect FileType từ MIME type của file upload.
     */
    public FileType detectFileType(MultipartFile file) {
        String contentType = file.getContentType();
        FileType type = MIME_TO_TYPE.get(contentType);
        if (type == null) {
            throw new RuntimeException("Unsupported file type: " + contentType
                    + ". Allowed: PDF, DOCX, IMAGE (jpeg/png/gif/webp)");
        }
        return type;
    }

    /**
     * Xóa file khỏi local storage khi xóa material.
     */
    public void delete(String fileUrl) {
        try {
            String filename = fileUrl.substring(fileUrl.lastIndexOf("/") + 1);
            Path filePath = Paths.get(uploadDir).resolve(filename);
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            // Log warning nhưng không throw — DB record vẫn cần xóa
            System.err.println("Warning: Could not delete file: " + fileUrl);
        }
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("File is empty");
        }
        // Giới hạn 20MB
        long maxSize = 20 * 1024 * 1024L;
        if (file.getSize() > maxSize) {
            throw new RuntimeException("File size exceeds 20MB limit");
        }
        if (!MIME_TO_TYPE.containsKey(file.getContentType())) {
            throw new RuntimeException("Unsupported file type: " + file.getContentType());
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains("."))
            return "bin";
        return filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
    }
}