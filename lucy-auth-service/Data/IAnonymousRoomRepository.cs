using Lucy.AuthService.Models;

namespace Lucy.AuthService.Data;

public interface IAnonymousRoomRepository
{
    Task<UserAccount?> FindActiveByIdAsync(int userId, CancellationToken cancellationToken);
    Task<PersonaProfile?> FindPersonaByUserIdAsync(int userId, CancellationToken cancellationToken);
    Task<PersonaProfile> SavePersonaAsync(int userId, GeneratedPersona persona, CancellationToken cancellationToken);
}
