using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public enum AnonymousRoomAccessStatus
{
    Success,
    UserNotFound,
    NotAnonymousEligible
}

public sealed record AnonymousRoomAccessResult(
    AnonymousRoomAccessStatus Status,
    AnonymousRoomAccessResponse? Payload);
