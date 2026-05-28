using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

public sealed class SqlWalletTransactionRepository(IConfiguration configuration) : IWalletTransactionRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

    public async Task<WalletTransaction?> FindByIdempotencyKeyAsync(string key, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                idempotency_key,
                transaction_type,
                status,
                amount,
                sender_wallet_id,
                receiver_wallet_id,
                room_id,
                gift_type,
                description,
                created_at,
                completed_at
            FROM dbo.wallet_transactions
            WHERE idempotency_key = @key;
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@key", key);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return SqlWalletRecordMapper.MapTransaction(reader);
    }

    public async Task<WalletTransaction?> FindByIdempotencyKeyForUpdateAsync(
        string key,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                idempotency_key,
                transaction_type,
                status,
                amount,
                sender_wallet_id,
                receiver_wallet_id,
                room_id,
                gift_type,
                description,
                created_at,
                completed_at
            FROM dbo.wallet_transactions WITH (UPDLOCK, HOLDLOCK)
            WHERE idempotency_key = @key;
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@key", key);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return SqlWalletRecordMapper.MapTransaction(reader);
    }

    public async Task<WalletTransaction> CreateAsync(
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
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.wallet_transactions (
                idempotency_key,
                transaction_type,
                status,
                amount,
                sender_wallet_id,
                receiver_wallet_id,
                room_id,
                gift_type,
                description
            )
            VALUES (
                @idempotencyKey,
                @transactionType,
                'PENDING',
                @amount,
                @senderWalletId,
                @receiverWalletId,
                @roomId,
                @giftType,
                @description
            );

            SELECT
                id,
                idempotency_key,
                transaction_type,
                status,
                amount,
                sender_wallet_id,
                receiver_wallet_id,
                room_id,
                gift_type,
                description,
                created_at,
                completed_at
            FROM dbo.wallet_transactions
            WHERE id = SCOPE_IDENTITY();
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@idempotencyKey", idempotencyKey);
        command.Parameters.AddWithValue("@transactionType", transactionType);
        command.Parameters.AddWithValue("@amount", amount);
        command.Parameters.AddWithValue("@senderWalletId", (object?)senderWalletId ?? DBNull.Value);
        command.Parameters.AddWithValue("@receiverWalletId", (object?)receiverWalletId ?? DBNull.Value);
        command.Parameters.AddWithValue("@roomId", (object?)roomId ?? DBNull.Value);
        command.Parameters.AddWithValue("@giftType", (object?)giftType ?? DBNull.Value);
        command.Parameters.AddWithValue("@description", (object?)description ?? DBNull.Value);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create wallet transaction.");
        }

        return SqlWalletRecordMapper.MapTransaction(reader);
    }

    public async Task UpdateStatusAsync(
        long transactionId,
        string status,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE dbo.wallet_transactions
            SET status = @status,
                completed_at = CASE WHEN @status IN ('COMPLETED', 'FAILED', 'CANCELLED')
                                    THEN SYSUTCDATETIME()
                                    ELSE completed_at
                               END
            WHERE id = @transactionId;
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@transactionId", transactionId);
        command.Parameters.AddWithValue("@status", status);

        var affected = await command.ExecuteNonQueryAsync(cancellationToken);
        if (affected == 0)
        {
            throw new InvalidOperationException($"Failed to update status for transaction {transactionId}.");
        }
    }
}
