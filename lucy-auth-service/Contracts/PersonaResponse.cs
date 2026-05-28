namespace Lucy.AuthService.Contracts;

public sealed record PersonaResponse(
    string Subject,
    string DisplayName,
    string AvatarCode,
    string? AvatarUrl,
    bool IsAnonymous);
