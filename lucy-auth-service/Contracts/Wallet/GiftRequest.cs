namespace Lucy.AuthService.Contracts.Wallet;

public sealed record GiftRequest(
    int ReceiverUserId,
    decimal Amount,
    string? GiftType,
    int? RoomId,
    string IdempotencyKey);
