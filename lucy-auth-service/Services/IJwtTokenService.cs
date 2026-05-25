using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public interface IJwtTokenService
{
    AccessTokenResult CreateAccessToken(UserAccount user);
    RealtimeTokenResult CreateRealtimeToken(UserAccount user, PersonaProfile persona, string channelName, int? roomId);
}
