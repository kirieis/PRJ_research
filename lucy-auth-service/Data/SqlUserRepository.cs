using Lucy.AuthService.Models;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data;

public sealed class SqlUserRepository(IConfiguration configuration) : IUserRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

    public async Task<UserAccount?> FindActiveByEmailAsync(string email, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                email,
                password_hash,
                role,
                language_id,
                display_name,
                avatar_url,
                is_anonymous,
                balance,
                is_active,
                created_at
            FROM dbo.users
            WHERE email = @email
              AND is_active = 1;
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@email", email.Trim());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return SqlUserRecordMapper.MapUser(reader);
    }

    public async Task<UserAccount?> FindActiveByIdAsync(int userId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                email,
                password_hash,
                role,
                language_id,
                display_name,
                avatar_url,
                is_anonymous,
                balance,
                is_active,
                created_at
            FROM dbo.users
            WHERE id = @userId
              AND is_active = 1;
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@userId", userId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return SqlUserRecordMapper.MapUser(reader);
    }

    public async Task<UserAccount> CreateAsync(
        string email,
        string passwordHash,
        string role,
        int? languageId,
        string? displayName,
        string? avatarUrl,
        bool isAnonymous,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO dbo.users (
                email,
                password_hash,
                role,
                language_id,
                display_name,
                avatar_url,
                is_anonymous,
                balance,
                is_active
            )
            VALUES (
                @email,
                @passwordHash,
                @role,
                @languageId,
                @displayName,
                @avatarUrl,
                @isAnonymous,
                0,
                1
            );

            SELECT TOP (1)
                id,
                email,
                password_hash,
                role,
                language_id,
                display_name,
                avatar_url,
                is_anonymous,
                balance,
                is_active,
                created_at
            FROM dbo.users
            WHERE id = SCOPE_IDENTITY();
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@email", email.Trim());
        command.Parameters.AddWithValue("@passwordHash", passwordHash);
        command.Parameters.AddWithValue("@role", role.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue("@languageId", (object?)languageId ?? DBNull.Value);
        command.Parameters.AddWithValue("@displayName", (object?)NormalizeNullable(displayName) ?? DBNull.Value);
        command.Parameters.AddWithValue("@avatarUrl", (object?)NormalizeNullable(avatarUrl) ?? DBNull.Value);
        command.Parameters.AddWithValue("@isAnonymous", isAnonymous);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Failed to create user.");
        }

        return SqlUserRecordMapper.MapUser(reader);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
