namespace Lucy.AuthService.Models;

public static class UserRole
{
    private static readonly HashSet<string> AllowedRoles = new(StringComparer.OrdinalIgnoreCase)
    {
        "LUCY",
        "PRO",
        "SUPER"
    };

    public static bool CanLogin(string role) => AllowedRoles.Contains(role);
}
