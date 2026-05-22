namespace Lucy.AuthService.Models;

public sealed record UserAccount(
    int Id,
    string Email,
    string PasswordHash,
    string Role,
    int? LanguageId,
    string? DisplayName,
    string? AvatarUrl,
    bool IsAnonymous,
    decimal Balance,
    bool IsActive,
    DateTimeOffset? CreatedAt);
