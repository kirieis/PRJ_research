package com.project.Lucy.repository;

import com.project.Lucy.entity.Language;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LanguageRepository extends JpaRepository<Language, Long> {
    Language findByCode(String code);
}
