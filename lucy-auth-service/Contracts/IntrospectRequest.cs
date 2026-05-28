using System.ComponentModel.DataAnnotations;

namespace Lucy.AuthService.Contracts;

public sealed record IntrospectRequest(
    [property: Required]
    string Token);
