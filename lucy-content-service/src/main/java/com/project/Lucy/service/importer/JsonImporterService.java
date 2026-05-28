package com.project.Lucy.service.importer;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.networknt.schema.JsonSchema;
import com.networknt.schema.JsonSchemaFactory;
import com.networknt.schema.SpecVersion;
import com.networknt.schema.ValidationMessage;
import com.project.Lucy.dto.ImportReport;
import com.project.Lucy.dto.NormalizedMaterial;
import com.project.Lucy.entity.ContentItem;
import com.project.Lucy.entity.Language;
import com.project.Lucy.entity.Level;
import com.project.Lucy.entity.SubLevel;
import com.project.Lucy.repository.ContentItemRepository;
import com.project.Lucy.repository.LanguageRepository;
import com.project.Lucy.repository.LevelRepository;
import com.project.Lucy.repository.SubLevelRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Service
public class JsonImporterService {

    @Autowired
    private LanguageRepository languageRepo;
    @Autowired
    private LevelRepository levelRepo;
    @Autowired
    private SubLevelRepository subLevelRepo;
    @Autowired
    private ContentItemRepository contentItemRepo;

    private final ObjectMapper mapper = new ObjectMapper();

    @Transactional
    public ImportReport importDirectory(String inputDir, String schemaPath) throws IOException {
        ImportReport report = new ImportReport(Instant.now().toString(), new ArrayList<>(), new ArrayList<>());

        File dir = new File(inputDir);
        File[] files = dir.listFiles((d, name) -> name.endsWith(".json") && !name.equals("import_report.json"));
        if (files == null) return report;

        JsonSchemaFactory factory = JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V7);
        JsonSchema schema = null;
        if (new File(schemaPath).exists()) {
            schema = factory.getSchema(new FileInputStream(schemaPath));
        }

        for (File file : files) {
            ImportReport.FileReport fileReport = new ImportReport.FileReport();
            fileReport.setFilename(file.getName());
            fileReport.setWarnings(new ArrayList<>());
            fileReport.setErrors(new ArrayList<>());
            
            try {
                if (schema != null) {
                    Set<ValidationMessage> errors = schema.validate(mapper.readTree(file));
                    if (!errors.isEmpty()) {
                        for (ValidationMessage msg : errors) {
                            fileReport.getErrors().add("Schema validation error: " + msg.getMessage());
                        }
                        report.getFiles().add(fileReport);
                        continue;
                    }
                }

                NormalizedMaterial material = mapper.readValue(file, NormalizedMaterial.class);
                fileReport.setLanguageCode(material.getLanguage_code());

                Language lang = languageRepo.findByCode(material.getLanguage_code());
                if (lang == null) {
                    lang = new Language();
                    lang.setCode(material.getLanguage_code());
                    lang.setName(material.getLanguage_code());
                    lang = languageRepo.save(lang);
                }

                int levelsImported = 0;
                int levelsFound = 0;

                for (NormalizedMaterial.Stage stage : material.getStages()) {
                    for (NormalizedMaterial.Level l : stage.getLevels()) {
                        levelsFound++;
                        
                        if (l.isIncomplete()) {
                            fileReport.getWarnings().add("Level " + l.getLevel_number() + " is marked incomplete.");
                        }
                        
                        if (l.getSub_levels().size() < 6) {
                            fileReport.getWarnings().add("Level " + l.getLevel_number() + " has less than 6 sub-levels.");
                        }

                        Level dbLevel = levelRepo.findByLanguageIdAndStageNumberAndLevelNumber(
                                lang.getId(), stage.getStage_number(), l.getLevel_number());
                        if (dbLevel == null) {
                            dbLevel = new Level();
                            dbLevel.setLanguage(lang);
                            dbLevel.setStageNumber(stage.getStage_number());
                            dbLevel.setLevelNumber(l.getLevel_number());
                        }
                        dbLevel.setTopicName(l.getTopic_name());
                        dbLevel.setTargetOutcome(l.getTarget_outcome());
                        dbLevel = levelRepo.save(dbLevel);
                        
                        levelsImported++;

                        for (NormalizedMaterial.SubLevel sl : l.getSub_levels()) {
                            SubLevel dbSubLevel = subLevelRepo.findByLevelIdAndOrderIndex(dbLevel.getId(), sl.getOrder_index());
                            if (dbSubLevel == null) {
                                dbSubLevel = new SubLevel();
                                dbSubLevel.setLevel(dbLevel);
                                dbSubLevel.setOrderIndex(sl.getOrder_index());
                            }
                            dbSubLevel.setTitle(sl.getTitle());
                            dbSubLevel.setDurationMinutes(sl.getDuration_minutes() != null ? sl.getDuration_minutes() : 10);
                            dbSubLevel = subLevelRepo.save(dbSubLevel);

                            for (NormalizedMaterial.ContentItem ci : sl.getContent_items()) {
                                ContentItem dbContent = contentItemRepo.findBySubLevelIdAndOrderIndex(dbSubLevel.getId(), ci.getOrder_index());
                                if (dbContent == null) {
                                    dbContent = new ContentItem();
                                    dbContent.setSubLevel(dbSubLevel);
                                    dbContent.setOrderIndex(ci.getOrder_index());
                                }
                                dbContent.setItemType(ci.getItem_type());
                                dbContent.setContentText(ci.getContent_text());
                                dbContent.setPhonetic(ci.getPhonetic());
                                contentItemRepo.save(dbContent);
                            }
                        }
                    }
                }
                fileReport.setLevelsFound(levelsFound);
                fileReport.setLevelsImported(levelsImported);
            } catch (Exception e) {
                fileReport.getErrors().add("Import failed: " + e.getMessage());
            }
            report.getFiles().add(fileReport);
        }

        File reportFile = new File(dir, "import_report.json");
        mapper.writerWithDefaultPrettyPrinter().writeValue(reportFile, report);

        return report;
    }
}
