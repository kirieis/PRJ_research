package com.project.Lucy.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Entity
@Table(name = "languages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Language {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // "English", "Chinese", "Japanese"

    private String code; // "EN", "ZH", "JP"

    @OneToMany(mappedBy = "language", cascade = CascadeType.ALL)
    private List<Level> levels; // FK thẳng tới Level, không qua Stage
}