package com.project.Lucy.service.normalize;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.project.Lucy.dto.NormalizedMaterial;
import com.project.Lucy.dto.NormalizedMaterial.*;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class ZhAdapter implements DocxAdapter {

    private static final Pattern ZH_QUESTION_PATTERN =
            Pattern.compile("^Q\\d*[:\\s]+(.+)", Pattern.CASE_INSENSITIVE);

    @Override
    public boolean supports(String filePath, String languageCode) {
        return "ZH".equalsIgnoreCase(languageCode);
    }

    @Override
    public NormalizedMaterial parse(String filePath, String languageCode, List<Object> elements) throws IOException {
        String[] paths = {"data/import_data/mappings/zh_mapping.yml", "../data/import_data/mappings/zh_mapping.yml", "PRJ_research-main/data/import_data/mappings/zh_mapping.yml"};
        String yamlPath = "data/import_data/mappings/zh_mapping.yml";
        for (String p : paths) {
            if (new File(p).exists()) {
                yamlPath = p;
                break;
            }
        }
        File mappingFile = new File(yamlPath);
        if (!mappingFile.exists()) {
            throw new IOException("Missing mapping file: " + mappingFile.getAbsolutePath());
        }
        
        ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
        JsonNode root = mapper.readTree(mappingFile);
        
        JsonNode fileConfig = null;
        for (JsonNode f : root.get("files")) {
            if (filePath.endsWith(f.get("filename").asText())) {
                fileConfig = f;
                break;
            }
        }
        
        if (fileConfig == null) {
            throw new IOException("No mapping config found for file: " + filePath);
        }

        int stageNum = fileConfig.get("stage_number").asInt();
        Pattern levelPattern = Pattern.compile(fileConfig.get("level_marker_regex").asText());
        String subLevelStrategy = fileConfig.get("sub_level_strategy").asText();

        NormalizedMaterial material = new NormalizedMaterial();
        material.setLanguage_code("ZH");
        material.setStages(new ArrayList<>());

        Stage currentStage = new Stage(stageNum, new ArrayList<>());
        Level currentLevel = null;
        SubLevel currentSubLevel = null;

        for (Object elem : elements) {
            if (!(elem instanceof String text)) continue;
            if (text.isBlank()) continue;

            Matcher levelMatcher = levelPattern.matcher(text);
            if (levelMatcher.find()) {
                if (currentLevel != null) {
                    flushLevel(currentLevel, currentSubLevel);
                    currentStage.getLevels().add(currentLevel);
                }
                int levelNum = Integer.parseInt(levelMatcher.group(1));
                String topic = levelMatcher.group(2).trim();
                currentLevel = new Level(levelNum, topic, null, false, new ArrayList<>());
                currentSubLevel = null;
                continue;
            }

            if (currentLevel != null && "questions_as_sublevels".equals(subLevelStrategy)) {
                Matcher qMatcher = ZH_QUESTION_PATTERN.matcher(text);
                if (qMatcher.find()) {
                    if (currentSubLevel != null) {
                        currentLevel.getSub_levels().add(currentSubLevel);
                    }
                    int orderIndex = currentLevel.getSub_levels().size() + 1;
                    String title = qMatcher.group(1).trim();
                    currentSubLevel = new SubLevel(orderIndex, title, "QUESTION", null, new ArrayList<>());
                } else {
                    if (currentSubLevel != null) {
                        int order = currentSubLevel.getContent_items().size() + 1;
                        currentSubLevel.getContent_items().add(new ContentItem(order, "TEXT", text, null));
                    } else {
                        int orderIndex = currentLevel.getSub_levels().size() + 1;
                        currentSubLevel = new SubLevel(orderIndex, "Intro", "TEXT", null, new ArrayList<>());
                        currentSubLevel.getContent_items().add(new ContentItem(1, "TEXT", text, null));
                    }
                }
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
        if (level.getSub_levels().size() != 6) {
            level.setIncomplete(true);
        }
    }
}
