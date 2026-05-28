using Lucy.AuthService.Models;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data;

public sealed class SqlAnonymousRoomRepository(IConfiguration configuration) : IAnonymousRoomRepository
{
    private readonly string _connectionString = configuration.GetConnectionString("LucyDb")
        ?? throw new InvalidOperationException("Missing LucyDb connection string.");

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

    public async Task<PersonaProfile?> FindPersonaByUserIdAsync(int userId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP (1)
                id,
                user_id,
                public_subject,
                display_name,
                avatar_code,
                avatar_url,
                created_at,
                updated_at
            FROM dbo.user_personas
            WHERE user_id = @userId;
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

        return SqlUserRecordMapper.MapPersona(reader);
    }

    public async Task<PersonaProfile> SavePersonaAsync(int userId, GeneratedPersona persona, CancellationToken cancellationToken)
    {
        const string sql = """
            IF EXISTS (SELECT 1 FROM dbo.user_personas WHERE user_id = @userId)
            BEGIN
                UPDATE dbo.user_personas
                SET public_subject = @publicSubject,
                    display_name = @displayName,
                    avatar_code = @avatarCode,
                    avatar_url = @avatarUrl,
                    updated_at = SYSUTCDATETIME()
                WHERE user_id = @userId;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.user_personas (
                    user_id,
                    public_subject,
                    display_name,
                    avatar_code,
                    avatar_url
                )
                VALUES (
                    @userId,
                    @publicSubject,
                    @displayName,
                    @avatarCode,
                    @avatarUrl
                );
            END;

            SELECT TOP (1)
                id,
                user_id,
                public_subject,
                display_name,
                avatar_code,
                avatar_url,
                created_at,
                updated_at
            FROM dbo.user_personas
            WHERE user_id = @userId;
            """;

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@userId", userId);
        command.Parameters.AddWithValue("@publicSubject", persona.PublicSubject);
        command.Parameters.AddWithValue("@displayName", persona.DisplayName);
        command.Parameters.AddWithValue("@avatarCode", persona.AvatarCode);
        command.Parameters.AddWithValue("@avatarUrl", (object?)persona.AvatarUrl ?? DBNull.Value);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Persona could not be saved.");
        }

        return SqlUserRecordMapper.MapPersona(reader);
    }
}
