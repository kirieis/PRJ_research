namespace Lucy.AuthService.Contracts;

public sealed record IntrospectResponse(
    bool Active,
    IReadOnlyDictionary<string, string>? Claims);
