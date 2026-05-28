namespace Lucy.AuthService.Models.Wallet;

public sealed record Wallet(
    int Id,
    int UserId,
    decimal Balance,
    string Currency,
    bool IsLocked,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);
