using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

public interface IWalletRepository
{
    /// <summary>
    /// Find wallet by user ID. Returns null if no wallet exists.
    /// </summary>
    Task<Models.Wallet.Wallet?> FindByUserIdAsync(int userId, CancellationToken cancellationToken);

    /// <summary>
    /// Create a new wallet for a user. Throws if wallet already exists.
    /// </summary>
    Task<Models.Wallet.Wallet> CreateWalletAsync(int userId, CancellationToken cancellationToken);

    /// <summary>
    /// Return the user's wallet, creating it if missing. Safe for concurrent first use.
    /// </summary>
    Task<Models.Wallet.Wallet> EnsureByUserIdAsync(int userId, CancellationToken cancellationToken);

    /// <summary>
    /// Get wallet by ID with UPDLOCK + ROWLOCK for transactional update.
    /// Must be called within an active SqlTransaction.
    /// </summary>
    Task<Models.Wallet.Wallet> GetByIdForUpdateAsync(
        int walletId,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken);

    /// <summary>
    /// Update wallet balance within an active transaction.
    /// </summary>
    Task UpdateBalanceAsync(
        int walletId,
        decimal newBalance,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken);
}
