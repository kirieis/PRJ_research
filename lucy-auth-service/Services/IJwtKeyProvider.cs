using Microsoft.IdentityModel.Tokens;

namespace Lucy.AuthService.Services;

public interface IJwtKeyProvider
{
    SecurityKey SigningKey { get; }

    SecurityKey ValidationKey { get; }

    string Algorithm { get; }

    object ToJwksKey();
}
