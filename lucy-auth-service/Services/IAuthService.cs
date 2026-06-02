using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);

    Task<AuthServiceResult<RegisterResponse>> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken);

    Task<AuthServiceResult<MeResponse>> GetMeAsync(int userId, CancellationToken cancellationToken);
}
