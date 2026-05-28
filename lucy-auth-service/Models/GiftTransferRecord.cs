namespace Lucy.AuthService.Models;

public sealed record GiftTransferRecord(
    long TransactionId,
    long SenderLedgerId,
    long ReceiverLedgerId,
    int SenderId,
    int ReceiverId,
    int? RoomId,
    string GiftType,
    decimal Amount,
    decimal SenderBalanceBefore,
    decimal SenderBalanceAfter,
    decimal ReceiverBalanceBefore,
    decimal ReceiverBalanceAfter,
    string Status,
    bool IsIdempotentReplay,
    DateTimeOffset CreatedAt);
