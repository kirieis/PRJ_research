using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public sealed record RegistrationResult(RegistrationStatus Status, LoginResponse? Response);

public enum RegistrationStatus
{
    Created,
    InvalidRole,
    EmailAlreadyExists
}
