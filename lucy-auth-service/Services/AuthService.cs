using Lucy.AuthService.Contracts;
using Lucy.AuthService.Data;
using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public sealed class AuthService(
    IUserRepository users,
    IJwtTokenService tokens,
    IPasswordHasher passwordHasher) : IAuthService
{
    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            return null;
        }

        var user = await users.FindActiveByEmailAsync(request.Email, cancellationToken);
        if (user is null || !UserRole.CanLogin(user.Role))
        {
            return null;
        }

        var passwordMatches = passwordHasher.Verify(request.Password, user.PasswordHash);
        if (!passwordMatches)
        {
            return null;
        }

        var isAnonymous = UserRole.ResolveIsAnonymous(user.Role, user.IsAnonymous);
        var token = tokens.CreateAccessToken(user);
        return new LoginResponse(
            token.AccessToken,
            "Bearer",
            token.ExpiresAt,
            new AuthUserResponse(
                user.Id,
                user.Email,
                user.Role,
                user.LanguageId,
                user.DisplayName,
                user.AvatarUrl,
                isAnonymous,
                user.Balance,
                user.CreatedAt));
    }
}
