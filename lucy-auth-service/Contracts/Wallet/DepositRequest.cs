namespace Lucy.AuthService.Contracts.Wallet;

public sealed record DepositRequest(
    decimal Amount,
    string IdempotencyKey,
    string? Description);
