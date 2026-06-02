namespace Lucy.AuthService.Contracts;

public sealed record RegisterRequest(
    string Email,
    string Password,
    string Role,
    int? LanguageId,
    string? DisplayName,
    string? AvatarUrl);
