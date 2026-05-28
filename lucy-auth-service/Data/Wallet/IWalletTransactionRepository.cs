using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

public interface IWalletTransactionRepository
{
    /// <summary>
    /// Check if a transaction with the given idempotency key already exists.
    /// </summary>
    Task<WalletTransaction?> FindByIdempotencyKeyAsync(string key, CancellationToken cancellationToken);

    /// <summary>
    /// Insert a new wallet transaction within an active DB transaction.
    /// Returns the inserted record with generated ID.
    /// </summary>
    Task<WalletTransaction> CreateAsync(
        string idempotencyKey,
        string transactionType,
        decimal amount,
        int? senderWalletId,
        int? receiverWalletId,
        int? roomId,
        string? giftType,
        string? description,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken);

    /// <summary>
    /// Update transaction status and completed_at within an active DB transaction.
    /// </summary>
    Task UpdateStatusAsync(
        long transactionId,
        string status,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken);
}
