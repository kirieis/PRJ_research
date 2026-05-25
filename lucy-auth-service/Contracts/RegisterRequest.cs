using System.ComponentModel.DataAnnotations;

namespace Lucy.AuthService.Contracts;

public sealed record RegisterRequest(
    [property: Required, EmailAddress, MaxLength(255)]
    string Email,

    [property: Required, MinLength(8), MaxLength(100)]
    string Password,

    [property: Required, MaxLength(50)]
    string Role,

    [property: Range(1, int.MaxValue)]
    int? LanguageId,

    [property: MaxLength(100)]
    string? DisplayName,

    [property: MaxLength(500)]
    string? AvatarUrl,

    bool IsAnonymous = true,

    [property: MaxLength(1000)]
    string? Bio = null);
