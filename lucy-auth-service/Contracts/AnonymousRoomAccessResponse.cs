namespace Lucy.AuthService.Contracts;

public sealed record AnonymousRoomAccessResponse(
    string RealtimeToken,
    string TokenType,
    DateTimeOffset ExpiresAt,
    string ChannelName,
    int? RoomId,
    PersonaResponse Persona);
