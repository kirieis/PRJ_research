using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

public interface IWalletLedgerRepository
{
    /// <summary>
    /// Insert a ledger entry within an active DB transaction.
    /// </summary>
    Task<WalletLedgerEntry> CreateEntryAsync(
        int walletId,
        long transactionId,
        string entryType,
        decimal amount,
        decimal balanceBefore,
        decimal balanceAfter,
        string? description,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken);

    Task<WalletLedgerEntry?> FindByTransactionAndWalletAsync(
        long transactionId,
        int walletId,
        string entryType,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken);
}
