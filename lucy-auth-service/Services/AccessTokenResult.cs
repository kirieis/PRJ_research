namespace Lucy.AuthService.Services;

public sealed record AccessTokenResult(string AccessToken, DateTimeOffset ExpiresAt);
