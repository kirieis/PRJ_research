package com.project.Lucy;

import com.project.Lucy.dto.LevelContentDto;
import com.project.Lucy.dto.ParsedDocumentDto;
import com.project.Lucy.dto.StageContentDto;
import com.project.Lucy.dto.SubLevelContentDto;
import com.project.Lucy.service.DocxParserService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.File;

@SpringBootApplication
public class LucyApplication implements CommandLineRunner {
    
    private final DocxParserService parser;

    public LucyApplication(DocxParserService parser) {
        this.parser = parser;
    }

    public static void main(String[] args) {
        SpringApplication.run(LucyApplication.class, args);
    }

    @Override
    public void run(String... args) {
        try {
            String path = "D:/your-folder/LISA_Stage1.docx"; // đường dẫn file thật
            File file = new File(path);
            
            if (!file.exists()) {
                System.out.println("⚠ File không tồn tại tại đường dẫn: " + path + ". Bỏ qua chạy Test Parser.");
                return;
            }
            
            ParsedDocumentDto doc = parser.parseDocument(path, "LISA");
            System.out.println("Language: " + doc.getLanguageCode());
            for (StageContentDto stage : doc.getStages()) {
                System.out.println("Stage " + stage.getStageNumber() + ": " + stage.getStageName());
                for (LevelContentDto level : stage.getLevels()) {
                    System.out.println("  Level " + level.getLevelNumber() + ": " + level.getTopicName());
                    for (SubLevelContentDto sub : level.getSubLevels()) {
                        System.out.println("    Sub: " + sub.getTitle());
                        System.out.println("      Vocab: " + sub.getVocabulary().size());
                        System.out.println("      AI: " + sub.getAiSupportQuestions().size());
                        System.out.println("      Quiz: " + sub.getQuizQuestions().size());
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi parse file Docx: " + e.getMessage());
        }
    }
}
