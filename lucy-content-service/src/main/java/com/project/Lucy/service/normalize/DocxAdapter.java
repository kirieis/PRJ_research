package com.project.Lucy.service.normalize;

import com.project.Lucy.dto.NormalizedMaterial;
import java.io.IOException;
import java.util.List;

public interface DocxAdapter {
    NormalizedMaterial parse(String filePath, String languageCode, List<Object> elements) throws IOException;
    boolean supports(String filePath, String languageCode);
}
