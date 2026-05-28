using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

public sealed class SqlWalletRepository(IConfiguration configuration) : IWalletRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

    public async Task<Models.Wallet.Wallet?> FindByUserIdAsync(int userId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                user_id,
                balance,
                currency,
                is_locked,
                created_at,
                updated_at
            FROM dbo.wallets
            WHERE user_id = @userId;
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@userId", userId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return SqlWalletRecordMapper.MapWallet(reader);
    }

    public async Task<Models.Wallet.Wallet> CreateWalletAsync(int userId, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.wallets (user_id, balance, currency, is_locked)
            VALUES (@userId, 0, 'LUCY_COIN', 0);

            SELECT
                id,
                user_id,
                balance,
                currency,
                is_locked,
                created_at,
                updated_at
            FROM dbo.wallets
            WHERE id = SCOPE_IDENTITY();
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@userId", userId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException($"Failed to create wallet for user {userId}.");
        }

        return SqlWalletRecordMapper.MapWallet(reader);
    }

    public async Task<Models.Wallet.Wallet> GetByIdForUpdateAsync(
        int walletId,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        // UPDLOCK + ROWLOCK: lock this specific row for update within the transaction
        // Prevents other transactions from reading this row until commit/rollback
        const string sql = """
            SELECT
                id,
                user_id,
                balance,
                currency,
                is_locked,
                created_at,
                updated_at
            FROM dbo.wallets WITH (UPDLOCK, ROWLOCK)
            WHERE id = @walletId;
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@walletId", walletId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException($"Wallet {walletId} not found.");
        }

        return SqlWalletRecordMapper.MapWallet(reader);
    }

    public async Task UpdateBalanceAsync(
        int walletId,
        decimal newBalance,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE dbo.wallets
            SET balance = @newBalance,
                updated_at = SYSUTCDATETIME()
            WHERE id = @walletId;
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@walletId", walletId);
        command.Parameters.AddWithValue("@newBalance", newBalance);

        var affected = await command.ExecuteNonQueryAsync(cancellationToken);
        if (affected == 0)
        {
            throw new InvalidOperationException($"Failed to update balance for wallet {walletId}.");
        }
    }
}
