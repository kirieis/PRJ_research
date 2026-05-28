using Lucy.AuthService.Models;

namespace Lucy.AuthService.Data;

public interface IWalletRepository
{
    Task<bool> ActiveUserExistsAsync(int userId, CancellationToken cancellationToken);

    Task<bool> RoomExistsAsync(int roomId, CancellationToken cancellationToken);

    Task<GiftTransferRecord?> TryFindGiftByIdempotencyKeyAsync(
        int senderId,
        string idempotencyKey,
        CancellationToken cancellationToken);

    Task<GiftTransferRecord> CreateGiftTransferAsync(
        int senderId,
        int receiverId,
        decimal amount,
        string giftType,
        int? roomId,
        string idempotencyKey,
        string? message,
        CancellationToken cancellationToken);
}
