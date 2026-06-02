using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Lucy.AuthService.Models;
using Lucy.AuthService.Options;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Lucy.AuthService.Services;

public sealed class JwtTokenService(
    IOptions<JwtOptions> options,
    IJwtKeyProvider keyProvider,
    TimeProvider timeProvider) : IJwtTokenService
{
    private readonly JwtOptions _options = options.Value;

    public AccessTokenResult CreateAccessToken(UserAccount user)
    {
        var now = timeProvider.GetUtcNow();
        var expiresAt = now.AddMinutes(_options.AccessTokenMinutes);
        var claims = BuildAccessClaims(user);
        var token = CreateToken(claims, _options.Audience, now, expiresAt);

        return new AccessTokenResult(new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    public RealtimeTokenResult CreateRealtimeToken(UserAccount user, PersonaProfile persona, string channelName, int? roomId)
    {
        var now = timeProvider.GetUtcNow();
        var expiresAt = now.AddMinutes(_options.RealtimeTokenMinutes);
        var claims = BuildRealtimeClaims(user, persona, channelName, roomId);
        var token = CreateToken(claims, _options.RealtimeAudience, now, expiresAt);

        return new RealtimeTokenResult(new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    private JwtSecurityToken CreateToken(
        IReadOnlyCollection<Claim> claims,
        string audience,
        DateTimeOffset now,
        DateTimeOffset expiresAt)
    {
        var credentials = new SigningCredentials(keyProvider.SigningKey, keyProvider.Algorithm);

        return new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: audience,
            claims: claims,
            notBefore: now.UtcDateTime,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);
    }

    private List<Claim> BuildAccessClaims(UserAccount user)
    {
        var isAnonymous = UserRole.ResolveIsAnonymous(user.Role, user.IsAnonymous);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Role, user.Role),
            new("Role", user.Role),
            new("role", user.Role),
            new("userId", user.Id.ToString()),
            new("isAnonymous", isAnonymous.ToString().ToLowerInvariant()),
            new("token_use", "access")
        };

        if (user.LanguageId is not null)
        {
            claims.Add(new Claim("languageId", user.LanguageId.Value.ToString()));
        }

        return claims;
    }

    private static List<Claim> BuildRealtimeClaims(UserAccount user, PersonaProfile persona, string channelName, int? roomId)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, persona.PublicSubject),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new(ClaimTypes.Role, user.Role),
            new("role", user.Role),
            new("token_use", "realtime"),
            new("isAnonymous", "true"),
            new("personaSubject", persona.PublicSubject),
            new("displayName", persona.DisplayName),
            new("avatarCode", persona.AvatarCode),
            new("channelName", channelName)
        };

        if (roomId is not null)
        {
            claims.Add(new Claim("roomId", roomId.Value.ToString()));
        }

        if (user.LanguageId is not null)
        {
            claims.Add(new Claim("languageId", user.LanguageId.Value.ToString()));
        }

        if (!string.IsNullOrWhiteSpace(persona.AvatarUrl))
        {
            claims.Add(new Claim("avatarUrl", persona.AvatarUrl));
        }

        return claims;
    }
}
