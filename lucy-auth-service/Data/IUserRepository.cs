using Lucy.AuthService.Models;

namespace Lucy.AuthService.Data;

public interface IUserRepository
{
    Task<UserAccount?> FindActiveByEmailAsync(string email, CancellationToken cancellationToken);

    Task<UserAccount?> FindActiveByIdAsync(int id, CancellationToken cancellationToken);

    Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken);

    Task<UserAccount?> CreateAsync(NewUserAccount user, CancellationToken cancellationToken);
}
