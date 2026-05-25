using Lucy.AuthService.Contracts;
using Lucy.AuthService.Data;
using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public sealed class AnonymousRoomAccessService(
    IAnonymousRoomRepository anonymousRoomRepository,
    IPersonaGenerator personaGenerator,
    IJwtTokenService tokens) : IAnonymousRoomAccessService
{
    public async Task<AnonymousRoomAccessResult> EnterAnonymousRoomAsync(
        int userId,
        AnonymousRoomAccessRequest request,
        CancellationToken cancellationToken)
    {
        var user = await anonymousRoomRepository.FindActiveByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return new AnonymousRoomAccessResult(AnonymousRoomAccessStatus.UserNotFound, null);
        }

        var isAnonymous = UserRole.ResolveIsAnonymous(user.Role, user.IsAnonymous);
        if (!isAnonymous)
        {
            return new AnonymousRoomAccessResult(AnonymousRoomAccessStatus.NotAnonymousEligible, null);
        }

        var persona = await ResolvePersonaAsync(user, request.RotatePersona, cancellationToken);
        var realtimeToken = tokens.CreateRealtimeToken(user, persona, request.ChannelName.Trim(), request.RoomId);
        var payload = new AnonymousRoomAccessResponse(
            realtimeToken.RealtimeToken,
            "Bearer",
            realtimeToken.ExpiresAt,
            request.ChannelName.Trim(),
            request.RoomId,
            new PersonaResponse(
                persona.PublicSubject,
                persona.DisplayName,
                persona.AvatarCode,
                persona.AvatarUrl,
                true));

        return new AnonymousRoomAccessResult(AnonymousRoomAccessStatus.Success, payload);
    }

    private async Task<PersonaProfile> ResolvePersonaAsync(
        UserAccount user,
        bool rotatePersona,
        CancellationToken cancellationToken)
    {
        if (!rotatePersona)
        {
            var existingPersona = await anonymousRoomRepository.FindPersonaByUserIdAsync(user.Id, cancellationToken);
            if (existingPersona is not null)
            {
                return existingPersona;
            }
        }

        var generatedPersona = personaGenerator.Generate();
        return await anonymousRoomRepository.SavePersonaAsync(user.Id, generatedPersona, cancellationToken);
    }
}
