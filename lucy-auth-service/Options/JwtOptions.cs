using System.ComponentModel.DataAnnotations;

namespace Lucy.AuthService.Options;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    [Required]
    public string Issuer { get; init; } = string.Empty;

    [Required]
    public string Audience { get; init; } = string.Empty;

    [Required]
    public string Secret { get; init; } = string.Empty;

    [Range(1, 1440)]
    public int AccessTokenMinutes { get; init; } = 120;

    [Required]
    public string RealtimeAudience { get; init; } = "Lucy.Realtime";

    [Range(1, 1440)]
    public int RealtimeTokenMinutes { get; init; } = 30;
}
