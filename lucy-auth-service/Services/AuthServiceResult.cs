namespace Lucy.AuthService.Services;

public enum AuthServiceStatus
{
    Success,
    ValidationError,
    DuplicateEmail,
    UserNotFound
}

public sealed record AuthServiceResult<T>(
    AuthServiceStatus Status,
    T? Payload,
    string? ErrorMessage)
{
    public static AuthServiceResult<T> Ok(T payload) =>
        new(AuthServiceStatus.Success, payload, null);

    public static AuthServiceResult<T> Fail(AuthServiceStatus status, string message) =>
        new(status, default, message);
}
