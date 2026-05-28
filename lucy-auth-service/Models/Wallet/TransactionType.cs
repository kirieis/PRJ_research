namespace Lucy.AuthService.Models.Wallet;

/// <summary>
/// Constants for wallet transaction types.
/// </summary>
public static class TransactionType
{
    public const string Deposit = "DEPOSIT";
    public const string Gift = "GIFT";
    public const string Withdraw = "WITHDRAW";

    private static readonly HashSet<string> AllTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        Deposit,
        Gift,
        Withdraw
    };

    public static bool IsValid(string type) => AllTypes.Contains(type);
}
