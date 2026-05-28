package com.project.Lucy.service.normalize;

import com.project.Lucy.dto.NormalizedMaterial;
import com.project.Lucy.dto.NormalizedMaterial.*;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class EnStage1Adapter implements DocxAdapter {

    private static final Pattern EN_LEVEL_GROUP_PATTERN =
            Pattern.compile("^(?:LEVELS?|🔷\\s*LEVELS?)\\s+([\\d]+)[-–—]([\\d]+)[:\\s]*(.*)", Pattern.CASE_INSENSITIVE);

    private static final Pattern EN_LEVEL_SINGLE_PATTERN =
            Pattern.compile("^.*?LEVEL\\s+(\\d+)\\s*[-–—:]\\s*(.*)", Pattern.CASE_INSENSITIVE);

    private static final Pattern EN_SUBLEVEL_PATTERN =
            Pattern.compile("^(?:Sub-level|Sublevel|ACTIVITY|HOẠT ĐỘNG|CHẶNG)\\s+(\\d+)[:\\s]*(.*)", Pattern.CASE_INSENSITIVE);

    private static final Pattern STAGE_PATTERN =
            Pattern.compile("(?:STAGE|GIAI ĐOẠN)\\s*(\\d+)", Pattern.CASE_INSENSITIVE);

    @Override
    public boolean supports(String filePath, String languageCode) {
        if (!"EN".equalsIgnoreCase(languageCode)) return false;
        String lower = filePath.toLowerCase();
        return lower.contains("stage 1") || lower.contains("level 1-30") || lower.contains("levels 1-30");
    }

    @Override
    public NormalizedMaterial parse(String filePath, String languageCode, List<Object> elements) {
        NormalizedMaterial material = new NormalizedMaterial();
        material.setLanguage_code("EN");
        material.setStages(new ArrayList<>());

        int stageNum = 1;
        Stage currentStage = new Stage(stageNum, new ArrayList<>());

        Level currentLevel = null;
        SubLevel currentSubLevel = null;

        for (Object elem : elements) {
            if (elem instanceof String text) {
                if (text.isBlank()) continue;

                if (EN_LEVEL_GROUP_PATTERN.matcher(text).find()) {
                    continue;
                }

                Matcher stageMatcher = STAGE_PATTERN.matcher(text);
                if (stageMatcher.find()) {
                    stageNum = Integer.parseInt(stageMatcher.group(1));
                    currentStage.setStage_number(stageNum);
                    continue;
                }

                Matcher levelMatcher = EN_LEVEL_SINGLE_PATTERN.matcher(text);
                if (levelMatcher.find()) {
                    if (currentLevel != null) {
                        flushLevel(currentLevel, currentSubLevel);
                        currentStage.getLevels().add(currentLevel);
                        currentSubLevel = null;
                    }
                    int levelNum = Integer.parseInt(levelMatcher.group(1));
                    String topic = levelMatcher.group(2).trim();
                    currentLevel = new Level(levelNum, topic, null, false, new ArrayList<>());
                    continue;
                }

                Matcher subMatcher = EN_SUBLEVEL_PATTERN.matcher(text);
                if (subMatcher.find()) {
                    if (currentSubLevel != null && currentLevel != null) {
                        currentLevel.getSub_levels().add(currentSubLevel);
                    }
                    int orderIndex = Integer.parseInt(subMatcher.group(1));
                    String title = subMatcher.group(2).trim();
                    currentSubLevel = new SubLevel(orderIndex, title, "SPEAKING_TOPIC", null, new ArrayList<>());
                    continue;
                }

                if (currentSubLevel != null) {
                    int contentOrder = currentSubLevel.getContent_items().size() + 1;
                    currentSubLevel.getContent_items().add(new ContentItem(contentOrder, "TEXT", text, null));
                }
            } else if (elem instanceof List<?> tableRows && currentSubLevel != null) {
                parseVocabularyRows(tableRows, currentSubLevel.getContent_items());
            }
        }

        if (currentLevel != null) {
            flushLevel(currentLevel, currentSubLevel);
            currentStage.getLevels().add(currentLevel);
        }

        if (!currentStage.getLevels().isEmpty()) {
            material.getStages().add(currentStage);
        }

        return material;
    }

    private void flushLevel(Level level, SubLevel lastSubLevel) {
        if (lastSubLevel != null) {
            level.getSub_levels().add(lastSubLevel);
        }
        
        if (level.getSub_levels().isEmpty()) {
            level.setIncomplete(true);
            for (int i = 1; i <= 6; i++) {
                String title = switch(i) {
                    case 1 -> "Warm-up";
                    case 6 -> "Wrap-up";
                    default -> "Core " + (i - 1);
                };
                level.getSub_levels().add(new SubLevel(i, title, "SPEAKING_TOPIC", 10, new ArrayList<>()));
            }
        }
    }

    @SuppressWarnings("unchecked")
    private void parseVocabularyRows(List<?> tableRows, List<ContentItem> contentItems) {
        for (Object rowObj : tableRows) {
            if (!(rowObj instanceof List<?> cells)) continue;
            List<String> cellList = (List<String>) cells;
            if (cellList.size() < 2) continue;
            
            String firstCell = cellList.get(0).toLowerCase();
            if (firstCell.contains("word") || firstCell.contains("từ") || firstCell.isEmpty()) continue;
            
            String word = cellList.get(0).trim();
            String phonetic = cellList.size() >= 3 ? cellList.get(1).trim() : null;
            String meaning = cellList.size() >= 3 ? cellList.get(2).trim() : cellList.get(1).trim();
            
            String contentText = word + " - " + meaning;
            contentItems.add(new ContentItem(contentItems.size() + 1, "VOCAB", contentText, phonetic));
        }
    }
}
