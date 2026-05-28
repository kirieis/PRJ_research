namespace Lucy.AuthService.Models;

public static class UserRole
{
    public const string Lucy = "LUCY";

    private static readonly HashSet<string> AllowedRoles = new(StringComparer.OrdinalIgnoreCase)
    {
        Lucy,
        "PRO",
        "SUPER"
    };

    public static bool CanLogin(string role) => AllowedRoles.Contains(role);

    public static bool ResolveIsAnonymous(string role, bool isAnonymous) =>
        string.Equals(role, Lucy, StringComparison.OrdinalIgnoreCase) || isAnonymous;
}
