using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data;

public sealed class SqlAuditLogRepository(IConfiguration configuration) : IAuditLogRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

    public async Task CreateStandaloneAsync(
        string eventType,
        int? userId,
        long? transactionId,
        string severity,
        string message,
        string? detailsJson,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await CreateAsync(
            eventType,
            userId,
            transactionId,
            severity,
            message,
            detailsJson,
            ipAddress,
            userAgent,
            connection,
            null,
            cancellationToken);
    }

    public async Task CreateAsync(
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
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.audit_logs (
                event_type,
                user_id,
                transaction_id,
                severity,
                message,
                details_json,
                ip_address,
                user_agent
            )
            VALUES (
                @eventType,
                @userId,
                @transactionId,
                @severity,
                @message,
                @detailsJson,
                @ipAddress,
                @userAgent
            );
            """;

        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@eventType", eventType);
        command.Parameters.AddWithValue("@userId", (object?)userId ?? DBNull.Value);
        command.Parameters.AddWithValue("@transactionId", (object?)transactionId ?? DBNull.Value);
        command.Parameters.AddWithValue("@severity", severity);
        command.Parameters.AddWithValue("@message", message);
        command.Parameters.AddWithValue("@detailsJson", (object?)detailsJson ?? DBNull.Value);
        command.Parameters.AddWithValue("@ipAddress", (object?)ipAddress ?? DBNull.Value);
        command.Parameters.AddWithValue("@userAgent", (object?)userAgent ?? DBNull.Value);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
