package com.project.Lucy.controller;

import com.project.Lucy.dto.ImportReport;
import com.project.Lucy.service.importer.JsonImporterService;
import com.project.Lucy.service.normalize.DocxNormalizer;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;

@RestController
@RequestMapping("/api/import")
@RequiredArgsConstructor
@Tag(name = "Import", description = "API quản lý việc import dữ liệu docx vào database")
public class ImportController {

    private final DocxNormalizer normalizer;
    private final JsonImporterService importer;

    @PostMapping
    @Operation(summary = "Kích hoạt pipeline import dữ liệu docx vào database")
    public ResponseEntity<?> runImport() {
        try {
            String[] paths = {"data/import_data", "../data/import_data", "PRJ_research-main/data/import_data"};
            String baseDir = "data/import_data";
            for (String p : paths) {
                if (new File(p).exists()) {
                    baseDir = p;
                    break;
                }
            }
            String inputDir = baseDir;
            String outputDir = baseDir + "/out";
            String schemaPath = baseDir + "/materials.schema.json";

            File dir = new File(inputDir);
            if (!dir.exists()) {
                return ResponseEntity.badRequest().body("⚠ Thư mục " + dir.getAbsolutePath() + " không tồn tại. Bỏ qua pipeline.");
            }

            System.out.println("=== BƯỚC 1: NORMALIZE DOCX -> JSON ===");
            normalizer.normalizeAll(inputDir, outputDir);
            System.out.println("✅ Normalize hoàn tất, xuất ra: " + outputDir);

            System.out.println("\n=== BƯỚC 2: IMPORT JSON -> DATABASE ===");
            ImportReport report = importer.importDirectory(outputDir, schemaPath);
            System.out.println("✅ Import hoàn tất.");

            return ResponseEntity.ok(report);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Pipeline failed: " + e.getMessage());
        }
    }
}
