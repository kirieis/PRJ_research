package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String role; // LUCY | PRO | SUPER | ADMIN

    @ManyToOne
    @JoinColumn(name = "language_id")
    private Language language;

    private String displayName;
    private String avatarUrl;
    private Boolean isAnonymous = true;
    private String bio;
    private BigDecimal balance = BigDecimal.ZERO;
    private Boolean isActive = true;
    private LocalDateTime createdAt;
}