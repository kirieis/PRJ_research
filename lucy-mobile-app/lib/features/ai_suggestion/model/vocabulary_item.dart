// lib/features/ai_suggestion/model/vocabulary_item.dart
// ============================================================
// Project LUCY — Vocabulary Item Data Model
//
// Represents a vocabulary word extracted by AI from suggestions.
// Includes pronunciation, meaning, and example usage.
// ============================================================

import 'package:equatable/equatable.dart';

/// A vocabulary word surfaced by the AI suggestion engine.
///
/// Displayed in the expandable vocabulary card below
/// the suggestion bubble. Users can long-press to save
/// to their personal vocabulary notebook.
class VocabularyItem extends Equatable {
  /// The vocabulary word or phrase.
  final String word;

  /// IPA pronunciation (e.g. "/ˈplɛzənt/").
  final String? pronunciation;

  /// Part of speech (e.g. "adj", "verb", "noun").
  final String? partOfSpeech;

  /// Vietnamese translation.
  final String meaning;

  /// Example sentence using the word.
  final String? example;

  /// CEFR level of this word (A1-C2).
  final String? cefrLevel;

  /// Whether this item has been saved to the user's notebook.
  final bool isSaved;

  const VocabularyItem({
    required this.word,
    this.pronunciation,
    this.partOfSpeech,
    required this.meaning,
    this.example,
    this.cefrLevel,
    this.isSaved = false,
  });

  /// Formatted display: "word /pronunciation/ (pos)"
  /// e.g. "pleasant /ˈplɛzənt/ (adj)"
  String get formattedDisplay {
    final parts = <String>[word];
    if (pronunciation != null) parts.add(pronunciation!);
    if (partOfSpeech != null) parts.add('($partOfSpeech)');
    return parts.join(' ');
  }

  VocabularyItem copyWith({
    String? word,
    String? pronunciation,
    String? partOfSpeech,
    String? meaning,
    String? example,
    String? cefrLevel,
    bool? isSaved,
  }) {
    return VocabularyItem(
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      word: json['word'] as String,
      pronunciation: json['pronunciation'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: json['meaning'] as String,
      example: json['example'] as String?,
      cefrLevel: json['cefrLevel'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'pronunciation': pronunciation,
      'partOfSpeech': partOfSpeech,
      'meaning': meaning,
      'example': example,
      'cefrLevel': cefrLevel,
      'isSaved': isSaved,
    };
  }

  @override
  List<Object?> get props => [
        word,
        pronunciation,
        partOfSpeech,
        meaning,
        example,
        cefrLevel,
        isSaved,
      ];
}
