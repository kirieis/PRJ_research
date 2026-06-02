using Lucy.AuthService.Options;
using Microsoft.IdentityModel.Tokens;

namespace Lucy.AuthService.Services;

public static class JwtTokenValidation
{
    public static TokenValidationParameters Build(
        JwtOptions options,
        SecurityKey validationKey,
        bool includeRealtimeAudience)
    {
        var audiences = includeRealtimeAudience
            ? new[] { options.Audience, options.RealtimeAudience }
            : new[] { options.Audience };

        return new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = options.Issuer,
            ValidateAudience = true,
            ValidAudiences = audiences,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = validationKey,
            ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    }
}
