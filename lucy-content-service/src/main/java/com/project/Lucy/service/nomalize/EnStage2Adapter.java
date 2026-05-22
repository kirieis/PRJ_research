package com.project.Lucy.service.normalize;

import com.project.Lucy.dto.NormalizedMaterial;
import com.project.Lucy.dto.NormalizedMaterial.*;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class EnStage2Adapter implements DocxAdapter {

    private static final Pattern EN_LEVEL_SINGLE_PATTERN =
            Pattern.compile("^.*?LEVEL\\s+(\\d+)\\s*[-–—:]\\s*(.*)", Pattern.CASE_INSENSITIVE);

    @Override
    public boolean supports(String filePath, String languageCode) {
        if (!"EN".equalsIgnoreCase(languageCode)) return false;
        String lower = filePath.toLowerCase();
        return lower.contains("stage 2") || lower.contains("level 31-60") || lower.contains("levels 31-60");
    }

    @Override
    public NormalizedMaterial parse(String filePath, String languageCode, List<Object> elements) {
        NormalizedMaterial material = new NormalizedMaterial();
        material.setLanguage_code("EN");
        material.setStages(new ArrayList<>());

        Stage currentStage = new Stage(2, new ArrayList<>());
        Level currentLevel = null;

        for (Object elem : elements) {
            if (!(elem instanceof String text)) continue;
            if (text.isBlank()) continue;

            Matcher levelMatcher = EN_LEVEL_SINGLE_PATTERN.matcher(text);
            if (levelMatcher.find()) {
                if (currentLevel != null) {
                    currentStage.getLevels().add(currentLevel);
                }
                int levelNum = Integer.parseInt(levelMatcher.group(1));
                String topic = levelMatcher.group(2).trim();
                currentLevel = new Level(levelNum, topic, null, false, new ArrayList<>());
                continue;
            }

            if (currentLevel != null) {
                int orderIndex = currentLevel.getSub_levels().size() + 1;
                String[] parts = splitTitleAndDescription(text);
                
                SubLevel sub = new SubLevel(orderIndex, parts[0], "SPEAKING_TOPIC", null, new ArrayList<>());
                if (!parts[1].isEmpty()) {
                    sub.getContent_items().add(new ContentItem(1, "TEXT", parts[1], null));
                }
                currentLevel.getSub_levels().add(sub);
            }
        }

        if (currentLevel != null) {
            currentStage.getLevels().add(currentLevel);
        }

        if (!currentStage.getLevels().isEmpty()) {
            material.getStages().add(currentStage);
        }

        return material;
    }

    private String[] splitTitleAndDescription(String text) {
        Pattern splitPattern = Pattern.compile(
            "(?<=[a-z)])(?=(?:Talk|Describe|Explain|Compare|Share|Give|Say|Tell|Suggest|Simulate|" +
            "Reflect|Summarize|Practice|Support|Ask|Check|What|How|Where|When|Why|Which)\\b)"
        );
        Matcher m = splitPattern.matcher(text);
        if (m.find()) {
            return new String[]{
                text.substring(0, m.start()).trim(),
                text.substring(m.end()).trim()
            };
        }
        return new String[]{text.trim(), ""};
    }
}
