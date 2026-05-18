package com.project.Lucy.service;

import com.project.Lucy.dto.*;
import org.apache.poi.xwpf.usermodel.*;
import org.springframework.stereotype.Service;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;
import java.util.regex.Pattern;

@Service
public class DocxParserService {

    // REGEX – BẠN PHẢI SỬA THEO ĐÚNG ĐỊNH DẠNG FILE WORD
    private static final Pattern STAGE_PATTERN = 
        Pattern.compile("^(STAGE|GIAI ĐOẠN)\\s+(\\d+)[:\\s]*(.*)", Pattern.CASE_INSENSITIVE);
    private static final Pattern LEVEL_PATTERN = 
        Pattern.compile("^(LEVEL|CẤP ĐỘ)\\s+(\\d+)[:\\s]*(.*)", Pattern.CASE_INSENSITIVE);
    private static final Pattern SUBLEVEL_PATTERN = 
        Pattern.compile("^(ACTIVITY|HOẠT ĐỘNG|CHẶNG)\\s+(\\d+)[:\\s]*(.*)", Pattern.CASE_INSENSITIVE);
    private static final Pattern QUIZ_PATTERN = 
        Pattern.compile("^(Q\\d+)[:\\s]+(.*)", Pattern.CASE_INSENSITIVE);
    private static final Pattern AI_PATTERN = 
        Pattern.compile("^(AI|AI SUPPORT)[:\\s]+(.*)", Pattern.CASE_INSENSITIVE);

    private enum ParseState { OUTSIDE, IN_STAGE, IN_LEVEL, IN_SUBLEVEL }

    public ParsedDocumentDto parseDocument(String filePath, String languageCode) throws IOException {
        ParsedDocumentDto result = new ParsedDocumentDto();
        result.setLanguageCode(languageCode);
        result.setStages(new ArrayList<>());

        try (FileInputStream fis = new FileInputStream(filePath);
             XWPFDocument doc = new XWPFDocument(fis)) {

            ParseState state = ParseState.OUTSIDE;
            StageContentDto currentStage = null;
            LevelContentDto currentLevel = null;
            SubLevelContentDto currentSubLevel = null;

            for (IBodyElement element : doc.getBodyElements()) {
                if (element instanceof XWPFParagraph) {
                    XWPFParagraph para = (XWPFParagraph) element;
                    String text = para.getText().trim();
                    if (text.isEmpty()) continue;

                    // 1. Phát hiện Stage
                    var stageMatcher = STAGE_PATTERN.matcher(text);
                    if (stageMatcher.find()) {
                        if (currentStage != null) result.getStages().add(currentStage);
                        int stageNum = Integer.parseInt(stageMatcher.group(2));
                        String stageName = stageMatcher.group(3).trim();
                        currentStage = new StageContentDto();
                        currentStage.setStageNumber(stageNum);
                        currentStage.setStageName(stageName);
                        currentStage.setLevels(new ArrayList<>());
                        state = ParseState.IN_STAGE;
                        currentLevel = null;
                        currentSubLevel = null;
                        continue;
                    }

                    // 2. Phát hiện Level (chỉ khi đang ở trong Stage)
                    if (state == ParseState.IN_STAGE || state == ParseState.IN_LEVEL || state == ParseState.IN_SUBLEVEL) {
                        var levelMatcher = LEVEL_PATTERN.matcher(text);
                        if (levelMatcher.find()) {
                            if (currentLevel != null && currentStage != null) {
                                currentStage.getLevels().add(currentLevel);
                            }
                            int levelNum = Integer.parseInt(levelMatcher.group(2));
                            String topic = levelMatcher.group(3).trim();
                            currentLevel = new LevelContentDto();
                            currentLevel.setLevelNumber(levelNum);
                            currentLevel.setTopicName(topic);
                            currentLevel.setSubLevels(new ArrayList<>());
                            state = ParseState.IN_LEVEL;
                            currentSubLevel = null;
                            continue;
                        }
                    }

                    // 3. Phát hiện SubLevel
                    if (state == ParseState.IN_LEVEL || state == ParseState.IN_SUBLEVEL) {
                        var subMatcher = SUBLEVEL_PATTERN.matcher(text);
                        if (subMatcher.find()) {
                            if (currentSubLevel != null && currentLevel != null) {
                                currentLevel.getSubLevels().add(currentSubLevel);
                            }
                            String title = subMatcher.group(3).trim();
                            currentSubLevel = new SubLevelContentDto();
                            currentSubLevel.setTitle(title);
                            currentSubLevel.setContentText("");
                            currentSubLevel.setVocabulary(new ArrayList<>());
                            currentSubLevel.setAiSupportQuestions(new ArrayList<>());
                            currentSubLevel.setQuizQuestions(new ArrayList<>());
                            state = ParseState.IN_SUBLEVEL;
                            continue;
                        }
                    }

                    // 4. Xử lý nội dung text, câu hỏi (nếu đang ở SubLevel)
                    if (state == ParseState.IN_SUBLEVEL && currentSubLevel != null) {
                        // Quiz
                        var quizMatcher = QUIZ_PATTERN.matcher(text);
                        if (quizMatcher.find()) {
                            QuestionDto q = new QuestionDto();
                            q.setId(quizMatcher.group(1));
                            q.setText(quizMatcher.group(2));
                            currentSubLevel.getQuizQuestions().add(q);
                            continue;
                        }
                        // AI
                        var aiMatcher = AI_PATTERN.matcher(text);
                        if (aiMatcher.find()) {
                            QuestionDto q = new QuestionDto();
                            q.setId("AI-" + UUID.randomUUID().toString().substring(0, 6));
                            q.setText(aiMatcher.group(2));
                            currentSubLevel.getAiSupportQuestions().add(q);
                            continue;
                        }
                        // text thường
                        String existing = currentSubLevel.getContentText();
                        if (existing.isEmpty()) currentSubLevel.setContentText(text);
                        else currentSubLevel.setContentText(existing + "\n" + text);
                    }

                } else if (element instanceof XWPFTable) {
                    // Xử lý bảng – thường chứa từ vựng
                    if (state == ParseState.IN_SUBLEVEL && currentSubLevel != null) {
                        List<VocabularyItem> vocab = parseVocabularyTable((XWPFTable) element);
                        currentSubLevel.getVocabulary().addAll(vocab);
                    }
                }
            }

            // Sau khi duyệt xong, thêm các đối tượng cuối cùng
            if (currentSubLevel != null && currentLevel != null) currentLevel.getSubLevels().add(currentSubLevel);
            if (currentLevel != null && currentStage != null) currentStage.getLevels().add(currentLevel);
            if (currentStage != null) result.getStages().add(currentStage);
        }
        return result;
    }

    private List<VocabularyItem> parseVocabularyTable(XWPFTable table) {
        List<VocabularyItem> items = new ArrayList<>();
        for (XWPFTableRow row : table.getRows()) {
            List<XWPFTableCell> cells = row.getTableCells();
            if (cells.size() < 2) continue;
            VocabularyItem item = new VocabularyItem();
            item.setWord(cells.get(0).getText().trim());
            if (cells.size() >= 3) {
                item.setPhonetic(cells.get(1).getText().trim());
                item.setMeaning(cells.get(2).getText().trim());
            } else {
                item.setMeaning(cells.get(1).getText().trim());
            }
            items.add(item);
        }
        return items;
    }
}
