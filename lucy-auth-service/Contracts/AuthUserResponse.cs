namespace Lucy.AuthService.Contracts;

public sealed record AuthUserResponse(
    int Id,
    string Email,
    string Role,
    int? LanguageId,
    string? DisplayName,
    string? AvatarUrl,
    bool IsAnonymous,
    decimal Balance,
    DateTimeOffset? CreatedAt);
