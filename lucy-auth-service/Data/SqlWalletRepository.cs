using System.Data;
using Lucy.AuthService.Models;
using Lucy.AuthService.Services;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data;

public sealed class SqlWalletRepository(IConfiguration configuration, ILogger<SqlWalletRepository> logger) : IWalletRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

    public async Task<bool> ActiveUserExistsAsync(int userId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM dbo.users
            WHERE id = @user_id
              AND is_active = 1;
            """;

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;

        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    public async Task<bool> RoomExistsAsync(int roomId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM dbo.rooms
            WHERE id = @room_id;
            """;

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@room_id", SqlDbType.Int).Value = roomId;

        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    public async Task<GiftTransferRecord?> TryFindGiftByIdempotencyKeyAsync(
        int senderId,
        string idempotencyKey,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                t.id AS transaction_id,
                t.sender_id,
                t.receiver_id,
                t.room_id,
                t.gift_type,
                t.amount,
                t.status,
                t.created_at,
                sender_entry.id AS sender_ledger_id,
                sender_entry.balance_before AS sender_balance_before,
                sender_entry.balance_after AS sender_balance_after,
                receiver_entry.id AS receiver_ledger_id,
                receiver_entry.balance_before AS receiver_balance_before,
                receiver_entry.balance_after AS receiver_balance_after
            FROM dbo.wallet_transactions t
            INNER JOIN dbo.wallet_ledger sender_entry
                ON sender_entry.transaction_id = t.id
               AND sender_entry.user_id = t.sender_id
               AND sender_entry.direction = 'DEBIT'
            INNER JOIN dbo.wallet_ledger receiver_entry
                ON receiver_entry.transaction_id = t.id
               AND receiver_entry.user_id = t.receiver_id
               AND receiver_entry.direction = 'CREDIT'
            WHERE t.sender_id = @sender_id
              AND t.idempotency_key = @idempotency_key
              AND t.type = 'GIFT';
            """;

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@sender_id", SqlDbType.Int).Value = senderId;
        command.Parameters.Add("@idempotency_key", SqlDbType.VarChar, 100).Value = idempotencyKey;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return MapGiftTransfer(reader, isIdempotentReplay: true);
    }

    public async Task<GiftTransferRecord> CreateGiftTransferAsync(
        int senderId,
        int receiverId,
        decimal amount,
        string giftType,
        int? roomId,
        string idempotencyKey,
        string? message,
        CancellationToken cancellationToken)
    {
        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        try
        {
            await EnsureWalletPairAsync(connection, transaction, senderId, receiverId, cancellationToken);

            var existing = await FindGiftByIdempotencyKeyAsync(
                connection,
                transaction,
                senderId,
                idempotencyKey,
                isIdempotentReplay: true,
                cancellationToken);

            if (existing is not null)
            {
                await transaction.CommitAsync(cancellationToken);
                return existing;
            }

            var balances = await ReadWalletBalancesForUpdateAsync(connection, transaction, senderId, receiverId, cancellationToken);
            var senderBalanceBefore = balances[senderId];
            if (senderBalanceBefore < amount)
            {
                throw new InsufficientWalletBalanceException(senderBalanceBefore, amount);
            }

            var receiverBalanceBefore = balances[receiverId];
            var senderBalanceAfter = senderBalanceBefore - amount;
            var receiverBalanceAfter = receiverBalanceBefore + amount;

            await UpdateWalletBalanceAsync(connection, transaction, senderId, senderBalanceAfter, cancellationToken);
            await UpdateWalletBalanceAsync(connection, transaction, receiverId, receiverBalanceAfter, cancellationToken);
            await SyncUserBalanceAsync(connection, transaction, senderId, senderBalanceAfter, cancellationToken);
            await SyncUserBalanceAsync(connection, transaction, receiverId, receiverBalanceAfter, cancellationToken);

            var transactionId = await InsertGiftTransactionAsync(
                connection,
                transaction,
                senderId,
                receiverId,
                amount,
                giftType,
                roomId,
                idempotencyKey,
                message,
                cancellationToken);

            var senderLedgerId = await InsertLedgerAsync(
                connection,
                transaction,
                transactionId,
                senderId,
                "DEBIT",
                -amount,
                senderBalanceBefore,
                senderBalanceAfter,
                cancellationToken);

            var receiverLedgerId = await InsertLedgerAsync(
                connection,
                transaction,
                transactionId,
                receiverId,
                "CREDIT",
                amount,
                receiverBalanceBefore,
                receiverBalanceAfter,
                cancellationToken);

            var created = await FindGiftByTransactionIdAsync(
                connection,
                transaction,
                transactionId,
                senderLedgerId,
                receiverLedgerId,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            logger.LogInformation(
                "Gift transfer completed. TransactionId={TransactionId}, SenderId={SenderId}, ReceiverId={ReceiverId}, Amount={Amount}.",
                transactionId,
                senderId,
                receiverId,
                amount);

            return created;
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627)
        {
            await transaction.RollbackAsync(cancellationToken);
            logger.LogInformation(
                exception,
                "Gift idempotency replay detected after unique constraint. SenderId={SenderId}, IdempotencyKey={IdempotencyKey}.",
                senderId,
                idempotencyKey);

            var replay = await TryFindGiftByIdempotencyKeyAsync(senderId, idempotencyKey, cancellationToken);
            if (replay is not null)
            {
                return replay;
            }

            throw;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static async Task EnsureWalletPairAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int senderId,
        int receiverId,
        CancellationToken cancellationToken)
    {
        var firstUserId = Math.Min(senderId, receiverId);
        var secondUserId = Math.Max(senderId, receiverId);

        await EnsureWalletAsync(connection, transaction, firstUserId, cancellationToken);
        await EnsureWalletAsync(connection, transaction, secondUserId, cancellationToken);
    }

    private static async Task EnsureWalletAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int userId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.wallets WITH (UPDLOCK, HOLDLOCK)
                WHERE user_id = @user_id
            )
            BEGIN
                INSERT INTO dbo.wallets (user_id, balance)
                SELECT id, ISNULL(balance, 0)
                FROM dbo.users
                WHERE id = @user_id
                  AND is_active = 1;
            END;
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<Dictionary<int, decimal>> ReadWalletBalancesForUpdateAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int senderId,
        int receiverId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT user_id, balance
            FROM dbo.wallets WITH (UPDLOCK, HOLDLOCK)
            WHERE user_id IN (@first_user_id, @second_user_id)
            ORDER BY user_id;
            """;

        var firstUserId = Math.Min(senderId, receiverId);
        var secondUserId = Math.Max(senderId, receiverId);
        var balances = new Dictionary<int, decimal>(capacity: 2);

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@first_user_id", SqlDbType.Int).Value = firstUserId;
        command.Parameters.Add("@second_user_id", SqlDbType.Int).Value = secondUserId;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            balances[reader.GetInt32(reader.GetOrdinal("user_id"))] = reader.GetDecimal(reader.GetOrdinal("balance"));
        }

        if (!balances.ContainsKey(senderId) || !balances.ContainsKey(receiverId))
        {
            throw new InvalidOperationException("Wallet rows were not found.");
        }

        return balances;
    }

    private static async Task UpdateWalletBalanceAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int userId,
        decimal balance,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE dbo.wallets
            SET balance = @balance,
                updated_at = SYSUTCDATETIME()
            WHERE user_id = @user_id;
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@balance", SqlDbType.Decimal).ConfigureMoney(balance);
        command.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task SyncUserBalanceAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int userId,
        decimal balance,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE dbo.users
            SET balance = @balance
            WHERE id = @user_id;
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@balance", SqlDbType.Decimal).ConfigureMoney(balance);
        command.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<long> InsertGiftTransactionAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int senderId,
        int receiverId,
        decimal amount,
        string giftType,
        int? roomId,
        string idempotencyKey,
        string? message,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.wallet_transactions (
                user_id,
                sender_id,
                receiver_id,
                amount,
                type,
                status,
                description,
                room_id,
                gift_type,
                idempotency_key
            )
            OUTPUT inserted.id
            VALUES (
                @sender_id,
                @sender_id,
                @receiver_id,
                @amount,
                'GIFT',
                'COMPLETED',
                @description,
                @room_id,
                @gift_type,
                @idempotency_key
            );
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@sender_id", SqlDbType.Int).Value = senderId;
        command.Parameters.Add("@receiver_id", SqlDbType.Int).Value = receiverId;
        command.Parameters.Add("@amount", SqlDbType.Decimal).ConfigureMoney(amount);
        command.Parameters.Add("@description", SqlDbType.NVarChar, 1000).Value = ToDbValue(message);
        command.Parameters.Add("@room_id", SqlDbType.Int).Value = ToDbValue(roomId);
        command.Parameters.Add("@gift_type", SqlDbType.VarChar, 100).Value = giftType;
        command.Parameters.Add("@idempotency_key", SqlDbType.VarChar, 100).Value = idempotencyKey;

        var value = await command.ExecuteScalarAsync(cancellationToken);
        return Convert.ToInt64(value);
    }

    private static async Task<long> InsertLedgerAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        long transactionId,
        int userId,
        string direction,
        decimal amount,
        decimal balanceBefore,
        decimal balanceAfter,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.wallet_ledger (
                transaction_id,
                user_id,
                direction,
                amount,
                balance_before,
                balance_after
            )
            OUTPUT inserted.id
            VALUES (
                @transaction_id,
                @user_id,
                @direction,
                @amount,
                @balance_before,
                @balance_after
            );
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@transaction_id", SqlDbType.BigInt).Value = transactionId;
        command.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;
        command.Parameters.Add("@direction", SqlDbType.VarChar, 10).Value = direction;
        command.Parameters.Add("@amount", SqlDbType.Decimal).ConfigureMoney(amount);
        command.Parameters.Add("@balance_before", SqlDbType.Decimal).ConfigureMoney(balanceBefore);
        command.Parameters.Add("@balance_after", SqlDbType.Decimal).ConfigureMoney(balanceAfter);

        var value = await command.ExecuteScalarAsync(cancellationToken);
        return Convert.ToInt64(value);
    }

    private static async Task<GiftTransferRecord?> FindGiftByIdempotencyKeyAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        int senderId,
        string idempotencyKey,
        bool isIdempotentReplay,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                t.id AS transaction_id,
                t.sender_id,
                t.receiver_id,
                t.room_id,
                t.gift_type,
                t.amount,
                t.status,
                t.created_at,
                sender_entry.id AS sender_ledger_id,
                sender_entry.balance_before AS sender_balance_before,
                sender_entry.balance_after AS sender_balance_after,
                receiver_entry.id AS receiver_ledger_id,
                receiver_entry.balance_before AS receiver_balance_before,
                receiver_entry.balance_after AS receiver_balance_after
            FROM dbo.wallet_transactions t WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.wallet_ledger sender_entry
                ON sender_entry.transaction_id = t.id
               AND sender_entry.user_id = t.sender_id
               AND sender_entry.direction = 'DEBIT'
            INNER JOIN dbo.wallet_ledger receiver_entry
                ON receiver_entry.transaction_id = t.id
               AND receiver_entry.user_id = t.receiver_id
               AND receiver_entry.direction = 'CREDIT'
            WHERE t.sender_id = @sender_id
              AND t.idempotency_key = @idempotency_key
              AND t.type = 'GIFT';
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@sender_id", SqlDbType.Int).Value = senderId;
        command.Parameters.Add("@idempotency_key", SqlDbType.VarChar, 100).Value = idempotencyKey;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return MapGiftTransfer(reader, isIdempotentReplay);
    }

    private static async Task<GiftTransferRecord> FindGiftByTransactionIdAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        long transactionId,
        long senderLedgerId,
        long receiverLedgerId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                t.id AS transaction_id,
                t.sender_id,
                t.receiver_id,
                t.room_id,
                t.gift_type,
                t.amount,
                t.status,
                t.created_at,
                sender_entry.id AS sender_ledger_id,
                sender_entry.balance_before AS sender_balance_before,
                sender_entry.balance_after AS sender_balance_after,
                receiver_entry.id AS receiver_ledger_id,
                receiver_entry.balance_before AS receiver_balance_before,
                receiver_entry.balance_after AS receiver_balance_after
            FROM dbo.wallet_transactions t
            INNER JOIN dbo.wallet_ledger sender_entry
                ON sender_entry.id = @sender_ledger_id
            INNER JOIN dbo.wallet_ledger receiver_entry
                ON receiver_entry.id = @receiver_ledger_id
            WHERE t.id = @transaction_id;
            """;

        await using var command = CreateCommand(sql, connection, transaction);
        command.Parameters.Add("@transaction_id", SqlDbType.BigInt).Value = transactionId;
        command.Parameters.Add("@sender_ledger_id", SqlDbType.BigInt).Value = senderLedgerId;
        command.Parameters.Add("@receiver_ledger_id", SqlDbType.BigInt).Value = receiverLedgerId;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Gift transaction was not found after insert.");
        }

        return MapGiftTransfer(reader, isIdempotentReplay: false);
    }

    private async Task<SqlConnection> OpenConnectionAsync(CancellationToken cancellationToken)
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        return connection;
    }

    private static SqlCommand CreateCommand(string sql, SqlConnection connection, SqlTransaction transaction)
        => new(sql, connection, transaction);

    private static GiftTransferRecord MapGiftTransfer(SqlDataReader reader, bool isIdempotentReplay) =>
        new(
            reader.GetInt64(reader.GetOrdinal("transaction_id")),
            reader.GetInt64(reader.GetOrdinal("sender_ledger_id")),
            reader.GetInt64(reader.GetOrdinal("receiver_ledger_id")),
            reader.GetInt32(reader.GetOrdinal("sender_id")),
            reader.GetInt32(reader.GetOrdinal("receiver_id")),
            SqlUserRecordMapper.ReadNullableInt(reader, "room_id"),
            reader.GetString(reader.GetOrdinal("gift_type")),
            reader.GetDecimal(reader.GetOrdinal("amount")),
            reader.GetDecimal(reader.GetOrdinal("sender_balance_before")),
            reader.GetDecimal(reader.GetOrdinal("sender_balance_after")),
            reader.GetDecimal(reader.GetOrdinal("receiver_balance_before")),
            reader.GetDecimal(reader.GetOrdinal("receiver_balance_after")),
            reader.GetString(reader.GetOrdinal("status")),
            isIdempotentReplay,
            SqlUserRecordMapper.ReadNullableDateTimeOffset(reader, "created_at") ?? DateTimeOffset.UtcNow);

    private static object ToDbValue<T>(T? value) => value is null ? DBNull.Value : value;
}

internal static class SqlParameterExtensions
{
    public static void ConfigureMoney(this SqlParameter parameter, decimal value)
    {
        parameter.Precision = 18;
        parameter.Scale = 2;
        parameter.Value = value;
    }
}
