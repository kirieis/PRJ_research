namespace Lucy.AuthService.Models.Wallet;

public sealed record WalletTransaction(
    long Id,
    string IdempotencyKey,
    string TransactionType,
    string Status,
    decimal Amount,
    int? SenderWalletId,
    int? ReceiverWalletId,
    int? RoomId,
    string? GiftType,
    string? Description,
    DateTimeOffset CreatedAt,
    DateTimeOffset? CompletedAt);
