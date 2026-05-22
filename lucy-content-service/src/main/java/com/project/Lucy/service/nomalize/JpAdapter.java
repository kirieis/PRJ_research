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
public class JpAdapter implements DocxAdapter {

    private static final Pattern JP_STAGE_PATTERN =
            Pattern.compile("ステージ\\s*(\\d+)", Pattern.CASE_INSENSITIVE);
    private static final Pattern JP_LEVEL_SINGLE_PATTERN =
            Pattern.compile("^.*?レベル\\s*(\\d+)\\s*[-–—:]\\s*(.*)", Pattern.CASE_INSENSITIVE);
    private static final Pattern JP_LEVEL_GROUP_PATTERN =
            Pattern.compile("^.*?レベル\\s*(\\d+)[-–—](\\d+)[:\\s]*(.*)", Pattern.CASE_INSENSITIVE);

    @Override
    public boolean supports(String filePath, String languageCode) {
        return "JP".equalsIgnoreCase(languageCode);
    }

    @Override
    public NormalizedMaterial parse(String filePath, String languageCode, List<Object> elements) throws IOException {
        int stageNum = detectStageFromFilename(filePath);
        
        String[] paths = {"data/import_data/mappings/jp_mapping.yml", "../data/import_data/mappings/jp_mapping.yml", "PRJ_research-main/data/import_data/mappings/jp_mapping.yml"};
        String yamlPath = "data/import_data/mappings/jp_mapping.yml";
        for (String p : paths) {
            if (new File(p).exists()) {
                yamlPath = p;
                break;
            }
        }
        File mappingFile = new File(yamlPath);
        JsonNode fileConfig = null;
        if (mappingFile.exists()) {
            ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
            JsonNode root = mapper.readTree(mappingFile);
            for (JsonNode f : root.get("files")) {
                if (filePath.endsWith(f.get("filename").asText())) {
                    fileConfig = f;
                    break;
                }
            }
        }

        NormalizedMaterial material = new NormalizedMaterial();
        material.setLanguage_code("JP");
        material.setStages(new ArrayList<>());

        Stage currentStage = new Stage(stageNum, new ArrayList<>());
        Level currentLevel = null;
        
        boolean inGroupRange = false;
        int groupStartLevel = 0;
        int groupEndLevel = 0;
        List<String> groupContent = new ArrayList<>();

        for (Object elem : elements) {
            if (!(elem instanceof String text)) continue;
            if (text.isBlank()) continue;

            Matcher stageMatcher = JP_STAGE_PATTERN.matcher(text);
            if (stageMatcher.find()) {
                currentStage.setStage_number(Integer.parseInt(stageMatcher.group(1)));
            }

            Matcher groupMatcher = JP_LEVEL_GROUP_PATTERN.matcher(text);
            if (groupMatcher.find()) {
                flushJpGroup(currentStage, inGroupRange, groupStartLevel, groupEndLevel, groupContent, fileConfig);
                if (currentLevel != null) {
                    currentStage.getLevels().add(currentLevel);
                    currentLevel = null;
                }

                groupStartLevel = Integer.parseInt(groupMatcher.group(1));
                groupEndLevel = Integer.parseInt(groupMatcher.group(2));
                groupContent = new ArrayList<>();
                inGroupRange = true;
                continue;
            }

            Matcher levelMatcher = JP_LEVEL_SINGLE_PATTERN.matcher(text);
            if (levelMatcher.find()) {
                if (inGroupRange) {
                    inGroupRange = false;
                    groupContent.clear();
                }
                if (currentLevel != null) {
                    currentStage.getLevels().add(currentLevel);
                }

                int levelNum = Integer.parseInt(levelMatcher.group(1));
                String topic = levelMatcher.group(2).trim();
                currentLevel = new Level(levelNum, topic, null, false, new ArrayList<>());
                continue;
            }

            if (currentLevel != null) {
                int order = currentLevel.getSub_levels().size() + 1;
                SubLevel sub = new SubLevel(order, text.trim(), "SPEAKING_TOPIC", null, new ArrayList<>());
                currentLevel.getSub_levels().add(sub);
            } else if (inGroupRange) {
                groupContent.add(text.trim());
            }
        }

        if (currentLevel != null) {
            currentStage.getLevels().add(currentLevel);
        }
        flushJpGroup(currentStage, inGroupRange, groupStartLevel, groupEndLevel, groupContent, fileConfig);

        if (!currentStage.getLevels().isEmpty()) {
            material.getStages().add(currentStage);
        }

        return material;
    }

    private void flushJpGroup(Stage stage, boolean inGroupRange, int startLevel, int endLevel, List<String> groupContent, JsonNode fileConfig) {
        if (!inGroupRange || groupContent.isEmpty()) return;

        boolean mappingFound = false;
        if (fileConfig != null && fileConfig.has("grouped_ranges")) {
            for (JsonNode rangeConfig : fileConfig.get("grouped_ranges")) {
                if (rangeConfig.get("range").asText().equals(startLevel + "-" + endLevel)) {
                    if (rangeConfig.get("content_lines_as_topics").asBoolean()) {
                        mappingFound = true;
                        int currentLevelNum = startLevel;
                        for (String line : groupContent) {
                            if (currentLevelNum > endLevel) break;
                            Level level = new Level(currentLevelNum++, line, null, true, new ArrayList<>());
                            stage.getLevels().add(level);
                        }
                    }
                    break;
                }
            }
        }

        if (!mappingFound) {
            Level groupLevel = new Level(startLevel, "Group " + startLevel + "-" + endLevel, null, true, new ArrayList<>());
            for (int i = 0; i < groupContent.size(); i++) {
                SubLevel sub = new SubLevel(i + 1, groupContent.get(i), "SPEAKING_TOPIC", null, new ArrayList<>());
                groupLevel.getSub_levels().add(sub);
            }
            stage.getLevels().add(groupLevel);
        }
    }

    private int detectStageFromFilename(String filePath) {
        String lower = filePath.toLowerCase();
        Matcher m = Pattern.compile("(?:stage|ステージ)\\s*(\\d+)", Pattern.CASE_INSENSITIVE).matcher(lower);
        if (m.find()) return Integer.parseInt(m.group(1));
        
        Matcher rangeMatcher = Pattern.compile("(?:level|レベル)\\s*(\\d+)").matcher(lower);
        if (rangeMatcher.find()) {
            int startLevel = Integer.parseInt(rangeMatcher.group(1));
            if (startLevel <= 30) return 1;
            if (startLevel <= 60) return 2;
            return 3;
        }
        return 1;
    }
}
