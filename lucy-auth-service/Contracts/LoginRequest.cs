namespace Lucy.AuthService.Contracts;

public sealed record LoginRequest(string Email, string Password);
