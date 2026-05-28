namespace Lucy.AuthService.Services;

public sealed class InsufficientWalletBalanceException(decimal currentBalance, decimal requiredAmount) : Exception(
    $"Insufficient wallet balance. Current balance is {currentBalance}, required amount is {requiredAmount}.")
{
    public decimal CurrentBalance { get; } = currentBalance;
    public decimal RequiredAmount { get; } = requiredAmount;
}
