using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

public sealed class SqlWalletLedgerRepository : IWalletLedgerRepository
{
    public async Task<WalletLedgerEntry> CreateEntryAsync(
        int walletId,
        long transactionId,
        string entryType,
        decimal amount,
        decimal balanceBefore,
        decimal balanceAfter,
        string? description,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.wallet_ledger (
                wallet_id,
                transaction_id,
                entry_type,
                amount,
                balance_before,
                balance_after,
                description
            )
            VALUES (
                @walletId,
                @transactionId,
                @entryType,
                @amount,
                @balanceBefore,
                @balanceAfter,
                @description
            );

            SELECT
                id,
                wallet_id,
                transaction_id,
                entry_type,
                amount,
                balance_before,
                balance_after,
                description,
                created_at
            FROM dbo.wallet_ledger
            WHERE id = SCOPE_IDENTITY();
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@walletId", walletId);
        command.Parameters.AddWithValue("@transactionId", transactionId);
        command.Parameters.AddWithValue("@entryType", entryType);
        command.Parameters.AddWithValue("@amount", amount);
        command.Parameters.AddWithValue("@balanceBefore", balanceBefore);
        command.Parameters.AddWithValue("@balanceAfter", balanceAfter);
        command.Parameters.AddWithValue("@description", (object?)description ?? DBNull.Value);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create ledger entry.");
        }

        return SqlWalletRecordMapper.MapLedgerEntry(reader);
    }

    public async Task<WalletLedgerEntry?> FindByTransactionAndWalletAsync(
        long transactionId,
        int walletId,
        string entryType,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                wallet_id,
                transaction_id,
                entry_type,
                amount,
                balance_before,
                balance_after,
                description,
                created_at
            FROM dbo.wallet_ledger
            WHERE transaction_id = @transactionId
              AND wallet_id = @walletId
              AND entry_type = @entryType
            ORDER BY id DESC;
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@transactionId", transactionId);
        command.Parameters.AddWithValue("@walletId", walletId);
        command.Parameters.AddWithValue("@entryType", entryType);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return SqlWalletRecordMapper.MapLedgerEntry(reader);
    }
}
