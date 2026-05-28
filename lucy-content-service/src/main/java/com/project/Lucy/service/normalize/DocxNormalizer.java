package com.project.Lucy.service.normalize;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.Lucy.dto.NormalizedMaterial;
import org.apache.poi.xwpf.usermodel.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Service
public class DocxNormalizer {

    private final List<DocxAdapter> adapters;
    private final ObjectMapper objectMapper;

    @Autowired
    public DocxNormalizer(List<DocxAdapter> adapters) {
        this.adapters = adapters;
        this.objectMapper = new ObjectMapper();
    }

    public NormalizedMaterial normalize(String filePath, String languageCode) throws IOException {
        DocxAdapter selectedAdapter = null;
        for (DocxAdapter adapter : adapters) {
            if (adapter.supports(filePath, languageCode)) {
                selectedAdapter = adapter;
                break;
            }
        }

        if (selectedAdapter == null) {
            throw new IllegalArgumentException("No adapter found for file: " + filePath + " and lang: " + languageCode);
        }

        List<Object> elements = extractElements(filePath);
        return selectedAdapter.parse(filePath, languageCode, elements);
    }

    public void normalizeAndSave(String filePath, String languageCode, String outputDir) throws IOException {
        NormalizedMaterial material = normalize(filePath, languageCode);
        
        File dir = new File(outputDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        File file = new File(filePath);
        String baseName = file.getName().substring(0, file.getName().lastIndexOf('.'));
        String outName = languageCode.toLowerCase() + "_" + baseName.replaceAll("\\s+", "_").toLowerCase() + ".json";
        
        File outFile = new File(dir, outName);
        objectMapper.writerWithDefaultPrettyPrinter().writeValue(outFile, material);
        System.out.println("Normalized to: " + outFile.getAbsolutePath());
    }

    public void normalizeAll(String inputDir, String outputDir) throws IOException {
        File dir = new File(inputDir);
        File[] files = dir.listFiles((d, name) -> name.endsWith(".docx") && !name.startsWith("~"));
        if (files == null) return;

        for (File file : files) {
            String name = file.getName().toLowerCase();
            String langCode = "EN";
            if (name.contains("chinese")) langCode = "ZH";
            else if (name.contains("japanese") || name.contains("janpanes") || name.contains("japan") || name.contains("jp")) langCode = "JP";

            try {
                normalizeAndSave(file.getAbsolutePath(), langCode, outputDir);
            } catch (Exception e) {
                System.err.println("Failed to normalize " + file.getName() + ": " + e.getMessage());
                e.printStackTrace();
            }
        }
    }

    private List<Object> extractElements(String filePath) throws IOException {
        List<Object> elements = new ArrayList<>();
        try (FileInputStream fis = new FileInputStream(filePath);
             XWPFDocument doc = new XWPFDocument(fis)) {
            for (IBodyElement element : doc.getBodyElements()) {
                if (element instanceof XWPFParagraph para) {
                    elements.add(para.getText().trim());
                } else if (element instanceof XWPFTable table) {
                    List<List<String>> rows = new ArrayList<>();
                    for (XWPFTableRow row : table.getRows()) {
                        List<String> cells = new ArrayList<>();
                        for (XWPFTableCell cell : row.getTableCells()) {
                            cells.add(cell.getText().trim());
                        }
                        rows.add(cells);
                    }
                    elements.add(rows);
                }
            }
        }
        return elements;
    }
}
