using System.ComponentModel.DataAnnotations;

namespace Lucy.AuthService.Contracts;

public sealed record LoginRequest(
    [property: Required, EmailAddress, MaxLength(255)]
    string Email,

    [property: Required, MinLength(8), MaxLength(100)]
    string Password);
