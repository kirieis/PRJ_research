namespace Lucy.AuthService.Contracts.Wallet;

public sealed record WalletBalanceResponse(
    int WalletId,
    int UserId,
    decimal Balance,
    string Currency,
    bool IsLocked);
