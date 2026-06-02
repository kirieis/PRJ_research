using Lucy.AuthService.Models;

namespace Lucy.AuthService.Data;

public interface IUserRepository
{
    Task<UserAccount?> FindActiveByEmailAsync(string email, CancellationToken cancellationToken);

    Task<UserAccount?> FindActiveByIdAsync(int userId, CancellationToken cancellationToken);

    Task<UserAccount> CreateAsync(
        string email,
        string passwordHash,
        string role,
        int? languageId,
        string? displayName,
        string? avatarUrl,
        bool isAnonymous,
        CancellationToken cancellationToken);
}
