using Lucy.AuthService.Contracts;
using Lucy.AuthService.Data;
using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public sealed class WalletService(IWalletRepository walletRepository, ILogger<WalletService> logger) : IWalletService
{
    public async Task<GiftResult> GiftAsync(int senderId, GiftRequest request, CancellationToken cancellationToken)
    {
        var giftType = TrimToNull(request.GiftType);
        var idempotencyKey = TrimToNull(request.IdempotencyKey);
        if (giftType is null || idempotencyKey is null || request.Amount <= 0)
        {
            return new GiftResult(GiftStatus.InvalidRequest, null, "Gift type, positive amount, and idempotency key are required.");
        }

        if (senderId == request.ReceiverId)
        {
            return new GiftResult(GiftStatus.CannotGiftSelf, null, "Sender and receiver must be different users.");
        }

        if (!await walletRepository.ActiveUserExistsAsync(senderId, cancellationToken))
        {
            return new GiftResult(GiftStatus.SenderNotFound, null, "Sender account is not active.");
        }

        if (!await walletRepository.ActiveUserExistsAsync(request.ReceiverId, cancellationToken))
        {
            return new GiftResult(GiftStatus.ReceiverNotFound, null, "Receiver account is not active.");
        }

        if (request.RoomId is not null && !await walletRepository.RoomExistsAsync(request.RoomId.Value, cancellationToken))
        {
            return new GiftResult(GiftStatus.RoomNotFound, null, "Room does not exist.");
        }

        var replay = await walletRepository.TryFindGiftByIdempotencyKeyAsync(senderId, idempotencyKey, cancellationToken);
        if (replay is not null)
        {
            logger.LogInformation(
                "Gift idempotency replay returned. TransactionId={TransactionId}, SenderId={SenderId}, ReceiverId={ReceiverId}.",
                replay.TransactionId,
                replay.SenderId,
                replay.ReceiverId);
            return new GiftResult(GiftStatus.Success, ToResponse(replay));
        }

        try
        {
            var transfer = await walletRepository.CreateGiftTransferAsync(
                senderId,
                request.ReceiverId,
                decimal.Round(request.Amount, 2),
                giftType,
                request.RoomId,
                idempotencyKey,
                TrimToNull(request.Message),
                cancellationToken);

            return new GiftResult(GiftStatus.Success, ToResponse(transfer));
        }
        catch (InsufficientWalletBalanceException exception)
        {
            logger.LogWarning(
                exception,
                "Gift transfer rejected because balance is insufficient. SenderId={SenderId}, ReceiverId={ReceiverId}, Amount={Amount}.",
                senderId,
                request.ReceiverId,
                request.Amount);

            return new GiftResult(GiftStatus.InsufficientBalance, null, exception.Message);
        }
    }

    private static GiftResponse ToResponse(GiftTransferRecord transfer) =>
        new(
            transfer.TransactionId,
            transfer.SenderLedgerId,
            transfer.ReceiverLedgerId,
            transfer.SenderId,
            transfer.ReceiverId,
            transfer.RoomId,
            transfer.GiftType,
            transfer.Amount,
            transfer.SenderBalanceBefore,
            transfer.SenderBalanceAfter,
            transfer.ReceiverBalanceBefore,
            transfer.ReceiverBalanceAfter,
            transfer.Status,
            transfer.IsIdempotentReplay,
            transfer.CreatedAt);

    private static string? TrimToNull(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrEmpty(trimmed) ? null : trimmed;
    }
}
