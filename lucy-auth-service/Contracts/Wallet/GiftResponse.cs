namespace Lucy.AuthService.Contracts.Wallet;

public sealed record GiftResponse(
    long TransactionId,
    decimal SenderBalanceAfter,
    string Status,
    string? GiftType,
    int ReceiverUserId,
    DateTimeOffset CompletedAt);
