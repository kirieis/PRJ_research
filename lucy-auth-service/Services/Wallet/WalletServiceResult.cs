namespace Lucy.AuthService.Services.Wallet;

public enum WalletServiceStatus
{
    Success,
    ValidationError,
    UserNotFound,
    WalletLocked,
    InsufficientFunds,
    Conflict
}

public sealed record WalletServiceResult<T>(
    WalletServiceStatus Status,
    T? Payload,
    string? ErrorMessage)
{
    public static WalletServiceResult<T> Ok(T payload) =>
        new(WalletServiceStatus.Success, payload, null);

    public static WalletServiceResult<T> Fail(WalletServiceStatus status, string message) =>
        new(status, default, message);
}
