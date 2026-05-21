package com.project.Lucy.repository;

import com.project.Lucy.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    // Tìm user theo email (dùng cho login / check duplicate)
    Optional<User> findByEmail(String email);

    // Tìm tất cả user theo role (LUCY | PRO | SUPER | ADMIN)
    List<User> findByRole(String role);

    // Tìm user đang active
    List<User> findByIsActiveTrue();

    // Tìm user theo ngôn ngữ học (languageId)
    List<User> findByLanguage_Id(Long languageId);
}