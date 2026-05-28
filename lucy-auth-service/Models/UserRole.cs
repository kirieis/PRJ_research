namespace Lucy.AuthService.Models;

public static class UserRole
{
    public const string Lucy = "LUCY";
    public const string Pro = "Pro";
    public const string Super = "Super";

    private static readonly Dictionary<string, string> AllowedRoles = new(StringComparer.OrdinalIgnoreCase)
    {
        ["LUCY"] = Lucy,
        ["PRO"] = Pro,
        ["Pro"] = Pro,
        ["SUPER"] = Super,
        ["Super"] = Super
    };

    public static bool CanLogin(string role) => AllowedRoles.ContainsKey(role);

    public static bool TryNormalize(string role, out string normalizedRole)
        => AllowedRoles.TryGetValue(role.Trim(), out normalizedRole!);
}
