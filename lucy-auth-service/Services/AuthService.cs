using Lucy.AuthService.Contracts;
using Lucy.AuthService.Data;
using Lucy.AuthService.Data.Wallet;
using Lucy.AuthService.Models;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Services;

public sealed class AuthService(
    IUserRepository users,
    IWalletRepository wallets,
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

    public async Task<AuthServiceResult<RegisterResponse>> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken)
    {
        var validationError = ValidateRegister(request);
        if (validationError is not null)
        {
            return AuthServiceResult<RegisterResponse>.Fail(AuthServiceStatus.ValidationError, validationError);
        }

        var normalizedEmail = request.Email.Trim();
        var normalizedRole = request.Role.Trim().ToUpperInvariant();
        var isAnonymous = UserRole.ResolveIsAnonymous(normalizedRole, false);

        try
        {
            var createdUser = await users.CreateAsync(
                normalizedEmail,
                passwordHasher.Hash(request.Password),
                normalizedRole,
                request.LanguageId,
                NormalizeNullable(request.DisplayName),
                NormalizeNullable(request.AvatarUrl),
                isAnonymous,
                cancellationToken);

            await wallets.EnsureByUserIdAsync(createdUser.Id, cancellationToken);

            var token = tokens.CreateAccessToken(createdUser);
            return AuthServiceResult<RegisterResponse>.Ok(new RegisterResponse(
                token.AccessToken,
                "Bearer",
                token.ExpiresAt,
                ToAuthUserResponse(createdUser)));
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            return AuthServiceResult<RegisterResponse>.Fail(
                AuthServiceStatus.DuplicateEmail,
                "Email is already registered.");
        }
    }

    public async Task<AuthServiceResult<MeResponse>> GetMeAsync(int userId, CancellationToken cancellationToken)
    {
        var user = await users.FindActiveByIdAsync(userId, cancellationToken);
        return user is null
            ? AuthServiceResult<MeResponse>.Fail(AuthServiceStatus.UserNotFound, "User not found.")
            : AuthServiceResult<MeResponse>.Ok(new MeResponse(ToAuthUserResponse(user)));
    }

    private static AuthUserResponse ToAuthUserResponse(UserAccount user)
    {
        var isAnonymous = UserRole.ResolveIsAnonymous(user.Role, user.IsAnonymous);
        return new AuthUserResponse(
            user.Id,
            user.Email,
            user.Role,
            user.LanguageId,
            user.DisplayName,
            user.AvatarUrl,
            isAnonymous,
            user.Balance,
            user.CreatedAt);
    }

    private static string? ValidateRegister(RegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return "email is required.";
        }

        if (!request.Email.Contains('@', StringComparison.Ordinal) || request.Email.Length > 255)
        {
            return "email is invalid.";
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8)
        {
            return "password must be at least 8 characters.";
        }

        if (string.IsNullOrWhiteSpace(request.Role) || !UserRole.CanLogin(request.Role))
        {
            return "role must be one of LUCY, PRO, SUPER.";
        }

        return null;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
