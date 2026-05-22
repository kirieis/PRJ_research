package com.project.Lucy.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ImportReport {
    private String timestamp;
    private List<FileReport> files;
    private List<String> crossLanguageWarnings;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FileReport {
        private String filename;
        private String languageCode;
        private int levelsFound;
        private int levelsImported;
        private List<String> warnings;
        private List<String> errors;
    }
}
