namespace Lucy.AuthService.Contracts.Wallet;

public sealed record DepositResponse(
    long TransactionId,
    decimal BalanceAfter,
    string Status,
    DateTimeOffset CompletedAt);
