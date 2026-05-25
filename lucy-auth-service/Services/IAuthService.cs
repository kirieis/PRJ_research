using Lucy.AuthService.Contracts;
using System.Security.Claims;

namespace Lucy.AuthService.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);

    Task<RegistrationResult> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken);

    Task<AuthUserResponse?> GetCurrentUserAsync(ClaimsPrincipal principal, CancellationToken cancellationToken);
}
