using Lucy.AuthService.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Lucy.AuthService.Options;

public sealed class ConfigureJwtBearerOptions(
    IOptions<JwtOptions> jwtOptions,
    IJwtKeyProvider keyProvider,
    IWebHostEnvironment environment) : IConfigureNamedOptions<JwtBearerOptions>
{
    public void Configure(string? name, JwtBearerOptions options)
    {
        if (name != JwtBearerDefaults.AuthenticationScheme)
        {
            return;
        }

        var values = jwtOptions.Value;
        options.RequireHttpsMetadata = !environment.IsDevelopment();
        options.TokenValidationParameters = JwtTokenValidation.Build(
            values,
            keyProvider.ValidationKey,
            includeRealtimeAudience: false);
    }

    public void Configure(JwtBearerOptions options) =>
        Configure(JwtBearerDefaults.AuthenticationScheme, options);
}
