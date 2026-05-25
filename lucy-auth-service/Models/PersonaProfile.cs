namespace Lucy.AuthService.Models;

public sealed record PersonaProfile(
    int Id,
    int UserId,
    string PublicSubject,
    string DisplayName,
    string AvatarCode,
    string? AvatarUrl,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);
