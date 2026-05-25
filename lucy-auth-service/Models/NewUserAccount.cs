namespace Lucy.AuthService.Models;

public sealed record NewUserAccount(
    string Email,
    string PasswordHash,
    string Role,
    int? LanguageId,
    string? DisplayName,
    string? AvatarUrl,
    bool IsAnonymous,
    string? Bio);
