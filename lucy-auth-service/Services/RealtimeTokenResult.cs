namespace Lucy.AuthService.Services;

public sealed record RealtimeTokenResult(string RealtimeToken, DateTimeOffset ExpiresAt);
