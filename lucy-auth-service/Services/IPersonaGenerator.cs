using Lucy.AuthService.Models;

namespace Lucy.AuthService.Services;

public interface IPersonaGenerator
{
    GeneratedPersona Generate();
}
