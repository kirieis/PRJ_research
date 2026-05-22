using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
}
