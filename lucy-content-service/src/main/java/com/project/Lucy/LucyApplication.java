package com.project.Lucy;

import com.project.Lucy.service.importer.JsonImporterService;
import com.project.Lucy.service.normalize.DocxNormalizer;
import com.project.Lucy.dto.ImportReport;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.io.File;

@SpringBootApplication
public class LucyApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(LucyApplication.class, args);
    }

    @Bean
    CommandLineRunner run(DocxNormalizer normalizer, JsonImporterService importer) {
        return args -> {
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
                    System.out.println("⚠ Thư mục " + dir.getAbsolutePath() + " không tồn tại. Bỏ qua pipeline.");
                    return;
                }

                System.out.println("=== BƯỚC 1: NORMALIZE DOCX -> JSON ===");
                normalizer.normalizeAll(inputDir, outputDir);
                System.out.println("✅ Normalize hoàn tất, xuất ra: " + outputDir);

                System.out.println("\n=== BƯỚC 2: IMPORT JSON -> DATABASE ===");
                ImportReport report = importer.importDirectory(outputDir, schemaPath);
                System.out.println("✅ Import hoàn tất.");
                
                for (ImportReport.FileReport fr : report.getFiles()) {
                    System.out.println("File: " + fr.getFilename());
                    System.out.println(" - Levels Found: " + fr.getLevelsFound());
                    System.out.println(" - Levels Imported: " + fr.getLevelsImported());
                    if (!fr.getErrors().isEmpty()) {
                        System.out.println(" - Errors: " + fr.getErrors().size());
                    }
                    if (!fr.getWarnings().isEmpty()) {
                        System.out.println(" - Warnings: " + fr.getWarnings().size());
                    }
                }
            } catch (Exception e) {
                System.err.println("Pipeline failed: " + e.getMessage());
                e.printStackTrace();
            }
        };
    }
}
