namespace Lucy.AuthService.Services;

public sealed class BCryptPasswordHasher : IPasswordHasher
{
    public bool Verify(string password, string passwordHash)
    {
        try
        {
            return BCrypt.Net.BCrypt.Verify(password, passwordHash);
        }
        catch (BCrypt.Net.SaltParseException)
        {
            return false;
        }
    }

    public string Hash(string password) => BCrypt.Net.BCrypt.HashPassword(password);
}
