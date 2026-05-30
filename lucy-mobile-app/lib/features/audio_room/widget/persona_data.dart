// lib/features/audio_room/widget/persona_data.dart
// ============================================================
// Project LUCY — Anonymous Persona Presets
// 10 preset personas for anonymous user avatars.
// ============================================================

/// A preset anonymous persona with an emoji and animal name.
class PersonaPreset {
  /// Emoji displayed as the avatar.
  final String emoji;

  /// Animal name used in the anonymous display name.
  /// Full display name format: "Anonymous [name]"
  final String name;

  /// Background color hex for the avatar circle.
  final int colorHex;

  const PersonaPreset({
    required this.emoji,
    required this.name,
    required this.colorHex,
  });

  /// Full anonymous display name, e.g. "Anonymous Fox".
  String get fullName => 'Anonymous $name';
}

/// 10 preset personas with distinct emojis and colors.
///
/// The [personaIndex] on [RoomUser] maps into this list.
/// Colors are carefully chosen to be visually distinct on dark backgrounds.
class PersonaData {
  PersonaData._();

  static const List<PersonaPreset> personas = [
    PersonaPreset(emoji: '🦊', name: 'Fox', colorHex: 0xFFFF6B35),
    PersonaPreset(emoji: '🐱', name: 'Cat', colorHex: 0xFFFFB347),
    PersonaPreset(emoji: '🐻', name: 'Bear', colorHex: 0xFF8B5E3C),
    PersonaPreset(emoji: '🦁', name: 'Lion', colorHex: 0xFFE8A317),
    PersonaPreset(emoji: '🐼', name: 'Panda', colorHex: 0xFF6B7B8D),
    PersonaPreset(emoji: '🐨', name: 'Koala', colorHex: 0xFF87CEEB),
    PersonaPreset(emoji: '🐯', name: 'Tiger', colorHex: 0xFFFF8C00),
    PersonaPreset(emoji: '🦄', name: 'Unicorn', colorHex: 0xFFDA70D6),
    PersonaPreset(emoji: '🐸', name: 'Frog', colorHex: 0xFF4CAF50),
    PersonaPreset(emoji: '🐵', name: 'Monkey', colorHex: 0xFFCD853F),
  ];

  /// Returns the persona at the given index, wrapping around if out of range.
  static PersonaPreset getPersona(int index) {
    return personas[index % personas.length];
  }
}
