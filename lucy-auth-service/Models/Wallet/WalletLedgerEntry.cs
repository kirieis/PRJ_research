namespace Lucy.AuthService.Models.Wallet;

public sealed record WalletLedgerEntry(
    long Id,
    int WalletId,
    long TransactionId,
    string EntryType,
    decimal Amount,
    decimal BalanceBefore,
    decimal BalanceAfter,
    string? Description,
    DateTimeOffset CreatedAt);
