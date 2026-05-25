namespace Lucy.AuthService.Contracts;

public sealed record AnonymousRoomAccessRequest(
    string ChannelName,
    int? RoomId,
    bool RotatePersona = false);
