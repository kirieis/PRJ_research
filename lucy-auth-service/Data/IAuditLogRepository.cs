using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data;

public interface IAuditLogRepository
{
    Task CreateAsync(
        string eventType,
        int? userId,
        long? transactionId,
        string severity,
        string message,
        string? detailsJson,
        string? ipAddress,
        string? userAgent,
        SqlConnection connection,
        SqlTransaction? transaction,
        CancellationToken cancellationToken);

    Task CreateStandaloneAsync(
        string eventType,
        int? userId,
        long? transactionId,
        string severity,
        string message,
        string? detailsJson,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken);
}
