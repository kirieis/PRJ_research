using System.Security.Cryptography;
using Lucy.AuthService.Options;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Lucy.AuthService.Services;

public sealed class RsaJwtKeyProvider : IJwtKeyProvider, IDisposable
{
    private readonly RSA _rsa;
    private readonly RsaSecurityKey _key;

    public RsaJwtKeyProvider(IOptions<JwtOptions> options, IWebHostEnvironment environment)
    {
        var jwtOptions = options.Value;
        var pem = ResolvePrivateKeyPem(jwtOptions, environment);

        _rsa = RSA.Create();
        _rsa.ImportFromPem(pem);
        _key = new RsaSecurityKey(_rsa)
        {
            KeyId = jwtOptions.RsaKeyId
        };
    }

    public SecurityKey SigningKey => _key;

    public SecurityKey ValidationKey => _key;

    public string Algorithm => SecurityAlgorithms.RsaSha256;

    public object ToJwksKey()
    {
        var parameters = _rsa.ExportParameters(includePrivateParameters: false);

        return new
        {
            kty = "RSA",
            use = "sig",
            alg = Algorithm,
            kid = _key.KeyId,
            n = Base64UrlEncoder.Encode(parameters.Modulus),
            e = Base64UrlEncoder.Encode(parameters.Exponent)
        };
    }

    public void Dispose() => _rsa.Dispose();

    private static string ResolvePrivateKeyPem(JwtOptions options, IWebHostEnvironment environment)
    {
        if (!string.IsNullOrWhiteSpace(options.RsaPrivateKeyPem))
        {
            return options.RsaPrivateKeyPem;
        }

        if (!string.IsNullOrWhiteSpace(options.RsaPrivateKeyPath))
        {
            var path = Path.IsPathRooted(options.RsaPrivateKeyPath)
                ? options.RsaPrivateKeyPath
                : Path.Combine(environment.ContentRootPath, options.RsaPrivateKeyPath);

            if (File.Exists(path))
            {
                return File.ReadAllText(path);
            }
        }

        throw new InvalidOperationException(
            "JWT RS256 private key is not configured. Set Jwt:RsaPrivateKeyPem or Jwt:RsaPrivateKeyPath.");
    }
}
