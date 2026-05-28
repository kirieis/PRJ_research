using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public sealed class RandomPersonaGenerator : IPersonaGenerator
{
    private static readonly string[] Prefixes =
    [
        "Anonymous",
        "Quiet",
        "Curious",
        "Bright",
        "Gentle",
        "Swift",
        "Calm",
        "Kind"
    ];

    private static readonly string[] Animals =
    [
        "Fox",
        "Otter",
        "Sparrow",
        "Panda",
        "Koala",
        "Dolphin",
        "Robin",
        "Falcon",
        "Whale",
        "Tiger",
        "Fawn",
        "Lynx"
    ];

    public GeneratedPersona Generate()
    {
        var prefix = Prefixes[Random.Shared.Next(Prefixes.Length)];
        var animal = Animals[Random.Shared.Next(Animals.Length)];
        var avatarCode = animal.ToLowerInvariant();
        var publicSubject = $"prs_{Guid.NewGuid():N}";

        return new GeneratedPersona(
            publicSubject,
            $"{prefix} {animal}",
            avatarCode,
            null);
    }
}
