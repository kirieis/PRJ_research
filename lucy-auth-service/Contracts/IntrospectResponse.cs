namespace Lucy.AuthService.Contracts;

public sealed record IntrospectResponse(
    bool Active,
    string? TokenUse,
    DateTimeOffset? ExpiresAt,
    IReadOnlyDictionary<string, string[]>? Claims);
