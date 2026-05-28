using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public interface IJwtTokenService
{
    AccessTokenResult CreateAccessToken(UserAccount user);
}
