using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public interface IAnonymousRoomAccessService
{
    Task<AnonymousRoomAccessResult> EnterAnonymousRoomAsync(
        int userId,
        AnonymousRoomAccessRequest request,
        CancellationToken cancellationToken);
}
