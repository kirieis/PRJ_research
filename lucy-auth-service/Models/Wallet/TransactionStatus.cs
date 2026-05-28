namespace Lucy.AuthService.Models.Wallet;

/// <summary>
/// Constants for wallet transaction statuses.
/// </summary>
public static class TransactionStatus
{
    public const string Pending = "PENDING";
    public const string Completed = "COMPLETED";
    public const string Failed = "FAILED";
    public const string Cancelled = "CANCELLED";

    private static readonly HashSet<string> AllStatuses = new(StringComparer.OrdinalIgnoreCase)
    {
        Pending,
        Completed,
        Failed,
        Cancelled
    };

    public static bool IsValid(string status) => AllStatuses.Contains(status);

    public static bool IsTerminal(string status) =>
        string.Equals(status, Completed, StringComparison.OrdinalIgnoreCase) ||
        string.Equals(status, Failed, StringComparison.OrdinalIgnoreCase) ||
        string.Equals(status, Cancelled, StringComparison.OrdinalIgnoreCase);
}
