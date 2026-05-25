using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
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

        var token = tokens.CreateAccessToken(user);
        return CreateLoginResponse(user, token);
    }

    public async Task<RegistrationResult> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken)
    {
        if (!UserRole.TryNormalize(request.Role, out var normalizedRole))
        {
            return new RegistrationResult(RegistrationStatus.InvalidRole, null);
        }

        if (await users.EmailExistsAsync(request.Email, cancellationToken))
        {
            return new RegistrationResult(RegistrationStatus.EmailAlreadyExists, null);
        }

        var newUser = new NewUserAccount(
            request.Email.Trim(),
            passwordHasher.Hash(request.Password),
            normalizedRole,
            request.LanguageId,
            TrimToNull(request.DisplayName),
            TrimToNull(request.AvatarUrl),
            request.IsAnonymous,
            TrimToNull(request.Bio));

        var user = await users.CreateAsync(newUser, cancellationToken);
        if (user is null)
        {
            return new RegistrationResult(RegistrationStatus.EmailAlreadyExists, null);
        }

        var token = tokens.CreateAccessToken(user);
        return new RegistrationResult(RegistrationStatus.Created, CreateLoginResponse(user, token));
    }

    public async Task<AuthUserResponse?> GetCurrentUserAsync(ClaimsPrincipal principal, CancellationToken cancellationToken)
    {
        var rawUserId = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? principal.FindFirstValue("userId");

        if (!int.TryParse(rawUserId, out var userId))
        {
            return null;
        }

        var user = await users.FindActiveByIdAsync(userId, cancellationToken);
        return user is null ? null : ToUserResponse(user);
    }

    private static LoginResponse CreateLoginResponse(UserAccount user, AccessTokenResult token)
    {
        return new LoginResponse(
            token.AccessToken,
            "Bearer",
            token.ExpiresAt,
            ToUserResponse(user));
    }

    private static AuthUserResponse ToUserResponse(UserAccount user)
    {
        return new AuthUserResponse(
            user.Id,
            user.Email,
            user.Role,
            user.LanguageId,
            user.DisplayName,
            user.AvatarUrl,
            UserRole.ResolveIsAnonymous(user.Role, user.IsAnonymous),
            user.Balance,
            user.CreatedAt);
    }

    private static string? TrimToNull(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrEmpty(trimmed) ? null : trimmed;
    }
}
