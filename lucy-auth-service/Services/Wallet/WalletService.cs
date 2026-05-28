using System.Data;
using System.Text.Json;
using Lucy.AuthService.Contracts.Wallet;
using Lucy.AuthService.Data;
using Lucy.AuthService.Data.Wallet;
using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;
using WalletModel = Lucy.AuthService.Models.Wallet.Wallet;

namespace Lucy.AuthService.Services.Wallet;

public sealed class WalletService(
    IConfiguration configuration,
    IUserRepository users,
    IWalletRepository wallets,
    IWalletTransactionRepository transactions,
    IWalletLedgerRepository ledger,
    IAuditLogRepository auditLogs,
    TimeProvider timeProvider,
    ILogger<WalletService> logger) : IWalletService
{
    private const string Debit = "DEBIT";
    private const string Credit = "CREDIT";

    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

    public async Task<WalletServiceResult<WalletBalanceResponse>> GetBalanceAsync(
        int userId,
        CancellationToken cancellationToken)
    {
        var user = await users.FindActiveByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return WalletServiceResult<WalletBalanceResponse>.Fail(
                WalletServiceStatus.UserNotFound,
                "User not found.");
        }

        var wallet = await wallets.EnsureByUserIdAsync(userId, cancellationToken);
        return WalletServiceResult<WalletBalanceResponse>.Ok(ToBalanceResponse(wallet));
    }

    public async Task<WalletServiceResult<GiftResponse>> GiftAsync(
        int senderUserId,
        GiftRequest request,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken)
    {
        var validationError = ValidateGift(senderUserId, request);
        if (validationError is not null)
        {
            return WalletServiceResult<GiftResponse>.Fail(WalletServiceStatus.ValidationError, validationError);
        }

        var sender = await users.FindActiveByIdAsync(senderUserId, cancellationToken);
        var receiver = await users.FindActiveByIdAsync(request.ReceiverUserId, cancellationToken);
        if (sender is null || receiver is null)
        {
            return WalletServiceResult<GiftResponse>.Fail(
                WalletServiceStatus.UserNotFound,
                "Sender or receiver user not found.");
        }

        var senderWallet = await wallets.EnsureByUserIdAsync(senderUserId, cancellationToken);
        var receiverWallet = await wallets.EnsureByUserIdAsync(request.ReceiverUserId, cancellationToken);

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);

        try
        {
            var existing = await transactions.FindByIdempotencyKeyForUpdateAsync(
                request.IdempotencyKey.Trim(),
                connection,
                transaction,
                cancellationToken);

            if (existing is not null)
            {
                if (!IsExistingGiftCompatible(existing))
                {
                    await transaction.RollbackAsync(cancellationToken);
                    return WalletServiceResult<GiftResponse>.Fail(
                        WalletServiceStatus.Conflict,
                        "Idempotency key belongs to another wallet operation.");
                }

                var response = await BuildExistingGiftResponseAsync(
                    existing,
                    request.ReceiverUserId,
                    connection,
                    transaction,
                    cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return WalletServiceResult<GiftResponse>.Ok(response);
            }

            var lockedWallets = await LockWalletsInStableOrderAsync(
                senderWallet.Id,
                receiverWallet.Id,
                connection,
                transaction,
                cancellationToken);
            var lockedSenderWallet = lockedWallets[senderWallet.Id];
            var lockedReceiverWallet = lockedWallets[receiverWallet.Id];

            if (lockedSenderWallet.IsLocked || lockedReceiverWallet.IsLocked)
            {
                await transaction.RollbackAsync(cancellationToken);
                return WalletServiceResult<GiftResponse>.Fail(
                    WalletServiceStatus.WalletLocked,
                    "Sender or receiver wallet is locked.");
            }

            if (lockedSenderWallet.Balance < request.Amount)
            {
                await transaction.RollbackAsync(cancellationToken);
                return WalletServiceResult<GiftResponse>.Fail(
                    WalletServiceStatus.InsufficientFunds,
                    "Insufficient wallet balance.");
            }

            var walletTransaction = await transactions.CreateAsync(
                request.IdempotencyKey.Trim(),
                TransactionType.Gift,
                request.Amount,
                lockedSenderWallet.Id,
                lockedReceiverWallet.Id,
                request.RoomId,
                NormalizeNullable(request.GiftType),
                "Gift transfer",
                connection,
                transaction,
                cancellationToken);

            var senderBalanceAfter = lockedSenderWallet.Balance - request.Amount;
            var receiverBalanceAfter = lockedReceiverWallet.Balance + request.Amount;

            await ledger.CreateEntryAsync(
                lockedSenderWallet.Id,
                walletTransaction.Id,
                Debit,
                request.Amount,
                lockedSenderWallet.Balance,
                senderBalanceAfter,
                "Gift sent",
                connection,
                transaction,
                cancellationToken);

            await ledger.CreateEntryAsync(
                lockedReceiverWallet.Id,
                walletTransaction.Id,
                Credit,
                request.Amount,
                lockedReceiverWallet.Balance,
                receiverBalanceAfter,
                "Gift received",
                connection,
                transaction,
                cancellationToken);

            await wallets.UpdateBalanceAsync(lockedSenderWallet.Id, senderBalanceAfter, connection, transaction, cancellationToken);
            await wallets.UpdateBalanceAsync(lockedReceiverWallet.Id, receiverBalanceAfter, connection, transaction, cancellationToken);
            await transactions.UpdateStatusAsync(walletTransaction.Id, TransactionStatus.Completed, connection, transaction, cancellationToken);

            await auditLogs.CreateAsync(
                "WALLET_GIFT_COMPLETED",
                senderUserId,
                walletTransaction.Id,
                "INFO",
                "Gift transaction completed.",
                JsonSerializer.Serialize(new
                {
                    senderUserId,
                    receiverUserId = request.ReceiverUserId,
                    request.RoomId,
                    request.Amount,
                    request.GiftType
                }),
                ipAddress,
                userAgent,
                connection,
                transaction,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);

            return WalletServiceResult<GiftResponse>.Ok(new GiftResponse(
                walletTransaction.Id,
                senderBalanceAfter,
                TransactionStatus.Completed,
                NormalizeNullable(request.GiftType),
                request.ReceiverUserId,
                timeProvider.GetUtcNow()));
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            await RollbackQuietlyAsync(transaction, cancellationToken);
            logger.LogWarning(ex, "Duplicate wallet idempotency key {IdempotencyKey}", request.IdempotencyKey);
            return WalletServiceResult<GiftResponse>.Fail(
                WalletServiceStatus.Conflict,
                "A transaction with this idempotency key already exists.");
        }
        catch (Exception ex)
        {
            await RollbackQuietlyAsync(transaction, cancellationToken);
            logger.LogError(ex, "Gift transaction failed for sender {SenderUserId}", senderUserId);
            await AuditFailureAsync(
                "WALLET_GIFT_FAILED",
                senderUserId,
                null,
                ex,
                ipAddress,
                userAgent,
                cancellationToken);
            throw;
        }
    }

    public async Task<WalletServiceResult<DepositResponse>> DepositAsync(
        int userId,
        DepositRequest request,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken)
    {
        var validationError = ValidateDeposit(request);
        if (validationError is not null)
        {
            return WalletServiceResult<DepositResponse>.Fail(WalletServiceStatus.ValidationError, validationError);
        }

        var user = await users.FindActiveByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return WalletServiceResult<DepositResponse>.Fail(WalletServiceStatus.UserNotFound, "User not found.");
        }

        var wallet = await wallets.EnsureByUserIdAsync(userId, cancellationToken);

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);

        try
        {
            var existing = await transactions.FindByIdempotencyKeyForUpdateAsync(
                request.IdempotencyKey.Trim(),
                connection,
                transaction,
                cancellationToken);

            if (existing is not null)
            {
                if (!string.Equals(existing.TransactionType, TransactionType.Deposit, StringComparison.OrdinalIgnoreCase))
                {
                    await transaction.RollbackAsync(cancellationToken);
                    return WalletServiceResult<DepositResponse>.Fail(
                        WalletServiceStatus.Conflict,
                        "Idempotency key belongs to another wallet operation.");
                }

                var response = await BuildExistingDepositResponseAsync(
                    existing,
                    wallet.Id,
                    connection,
                    transaction,
                    cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return WalletServiceResult<DepositResponse>.Ok(response);
            }

            var lockedWallet = await wallets.GetByIdForUpdateAsync(wallet.Id, connection, transaction, cancellationToken);
            if (lockedWallet.IsLocked)
            {
                await transaction.RollbackAsync(cancellationToken);
                return WalletServiceResult<DepositResponse>.Fail(
                    WalletServiceStatus.WalletLocked,
                    "Wallet is locked.");
            }

            var walletTransaction = await transactions.CreateAsync(
                request.IdempotencyKey.Trim(),
                TransactionType.Deposit,
                request.Amount,
                null,
                lockedWallet.Id,
                null,
                null,
                NormalizeNullable(request.Description) ?? "Deposit",
                connection,
                transaction,
                cancellationToken);

            var balanceAfter = lockedWallet.Balance + request.Amount;
            await ledger.CreateEntryAsync(
                lockedWallet.Id,
                walletTransaction.Id,
                Credit,
                request.Amount,
                lockedWallet.Balance,
                balanceAfter,
                "Deposit credited",
                connection,
                transaction,
                cancellationToken);

            await wallets.UpdateBalanceAsync(lockedWallet.Id, balanceAfter, connection, transaction, cancellationToken);
            await transactions.UpdateStatusAsync(walletTransaction.Id, TransactionStatus.Completed, connection, transaction, cancellationToken);

            await auditLogs.CreateAsync(
                "WALLET_DEPOSIT_COMPLETED",
                userId,
                walletTransaction.Id,
                "INFO",
                "Deposit transaction completed.",
                JsonSerializer.Serialize(new
                {
                    userId,
                    request.Amount,
                    request.Description
                }),
                ipAddress,
                userAgent,
                connection,
                transaction,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);

            return WalletServiceResult<DepositResponse>.Ok(new DepositResponse(
                walletTransaction.Id,
                balanceAfter,
                TransactionStatus.Completed,
                timeProvider.GetUtcNow()));
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            await RollbackQuietlyAsync(transaction, cancellationToken);
            logger.LogWarning(ex, "Duplicate wallet idempotency key {IdempotencyKey}", request.IdempotencyKey);
            return WalletServiceResult<DepositResponse>.Fail(
                WalletServiceStatus.Conflict,
                "A transaction with this idempotency key already exists.");
        }
        catch (Exception ex)
        {
            await RollbackQuietlyAsync(transaction, cancellationToken);
            logger.LogError(ex, "Deposit transaction failed for user {UserId}", userId);
            await AuditFailureAsync(
                "WALLET_DEPOSIT_FAILED",
                userId,
                null,
                ex,
                ipAddress,
                userAgent,
                cancellationToken);
            throw;
        }
    }

    private async Task<Dictionary<int, WalletModel>> LockWalletsInStableOrderAsync(
        int firstWalletId,
        int secondWalletId,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        var result = new Dictionary<int, WalletModel>(capacity: 2);
        foreach (var walletId in new[] { firstWalletId, secondWalletId }.OrderBy(id => id))
        {
            result[walletId] = await wallets.GetByIdForUpdateAsync(
                walletId,
                connection,
                transaction,
                cancellationToken);
        }

        return result;
    }

    private async Task<GiftResponse> BuildExistingGiftResponseAsync(
        WalletTransaction existing,
        int receiverUserId,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        if (!string.Equals(existing.TransactionType, TransactionType.Gift, StringComparison.OrdinalIgnoreCase)
            || existing.SenderWalletId is null)
        {
            throw new InvalidOperationException("Idempotency key belongs to a non-gift transaction.");
        }

        var debitEntry = await ledger.FindByTransactionAndWalletAsync(
            existing.Id,
            existing.SenderWalletId.Value,
            Debit,
            connection,
            transaction,
            cancellationToken);

        return new GiftResponse(
            existing.Id,
            debitEntry?.BalanceAfter ?? 0,
            existing.Status,
            existing.GiftType,
            receiverUserId,
            existing.CompletedAt ?? timeProvider.GetUtcNow());
    }

    private static bool IsExistingGiftCompatible(WalletTransaction existing) =>
        string.Equals(existing.TransactionType, TransactionType.Gift, StringComparison.OrdinalIgnoreCase)
        && existing.SenderWalletId is not null
        && existing.ReceiverWalletId is not null;

    private async Task<DepositResponse> BuildExistingDepositResponseAsync(
        WalletTransaction existing,
        int walletId,
        SqlConnection connection,
        SqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        if (!string.Equals(existing.TransactionType, TransactionType.Deposit, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Idempotency key belongs to a non-deposit transaction.");
        }

        var creditEntry = await ledger.FindByTransactionAndWalletAsync(
            existing.Id,
            walletId,
            Credit,
            connection,
            transaction,
            cancellationToken);

        return new DepositResponse(
            existing.Id,
            creditEntry?.BalanceAfter ?? 0,
            existing.Status,
            existing.CompletedAt ?? timeProvider.GetUtcNow());
    }

    private async Task AuditFailureAsync(
        string eventType,
        int? userId,
        long? transactionId,
        Exception exception,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken)
    {
        try
        {
            await auditLogs.CreateStandaloneAsync(
                eventType,
                userId,
                transactionId,
                "ERROR",
                exception.Message,
                JsonSerializer.Serialize(new { exception = exception.GetType().Name }),
                ipAddress,
                userAgent,
                cancellationToken);
        }
        catch (Exception auditException)
        {
            logger.LogError(auditException, "Failed to write audit log for {EventType}", eventType);
        }
    }

    private static WalletBalanceResponse ToBalanceResponse(WalletModel wallet) =>
        new(wallet.Id, wallet.UserId, wallet.Balance, wallet.Currency, wallet.IsLocked);

    private static string? ValidateGift(int senderUserId, GiftRequest request)
    {
        if (request.ReceiverUserId <= 0)
        {
            return "receiverUserId is required.";
        }

        if (request.ReceiverUserId == senderUserId)
        {
            return "Sender and receiver must be different users.";
        }

        if (request.Amount <= 0)
        {
            return "amount must be greater than zero.";
        }

        if (string.IsNullOrWhiteSpace(request.IdempotencyKey))
        {
            return "idempotencyKey is required.";
        }

        if (request.IdempotencyKey.Length > 128)
        {
            return "idempotencyKey must be 128 characters or fewer.";
        }

        return null;
    }

    private static string? ValidateDeposit(DepositRequest request)
    {
        if (request.Amount <= 0)
        {
            return "amount must be greater than zero.";
        }

        if (string.IsNullOrWhiteSpace(request.IdempotencyKey))
        {
            return "idempotencyKey is required.";
        }

        if (request.IdempotencyKey.Length > 128)
        {
            return "idempotencyKey must be 128 characters or fewer.";
        }

        return null;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static async Task RollbackQuietlyAsync(SqlTransaction transaction, CancellationToken cancellationToken)
    {
        try
        {
            await transaction.RollbackAsync(cancellationToken);
        }
        catch
        {
            // The original exception is more useful than a rollback failure.
        }
    }
}
