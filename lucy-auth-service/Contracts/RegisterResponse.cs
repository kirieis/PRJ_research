namespace Lucy.AuthService.Contracts;

public sealed record RegisterResponse(
    string AccessToken,
    string TokenType,
    DateTimeOffset ExpiresAt,
    AuthUserResponse User);
