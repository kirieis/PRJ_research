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

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@email", System.Data.SqlDbType.VarChar, 255).Value = email.Trim();

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return MapUser(reader);
    }

    public async Task<UserAccount?> FindActiveByIdAsync(int id, CancellationToken cancellationToken)
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
            WHERE id = @id
              AND is_active = 1;
            """;

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@id", System.Data.SqlDbType.Int).Value = id;

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return MapUser(reader);
    }

    public async Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM dbo.users
            WHERE email = @email;
            """;

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@email", System.Data.SqlDbType.VarChar, 255).Value = email.Trim();

        var value = await command.ExecuteScalarAsync(cancellationToken);
        return value is not null;
    }

    public async Task<UserAccount?> CreateAsync(NewUserAccount user, CancellationToken cancellationToken)
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
                bio
            )
            OUTPUT
                inserted.id,
                inserted.email,
                inserted.password_hash,
                inserted.role,
                inserted.language_id,
                inserted.display_name,
                inserted.avatar_url,
                inserted.is_anonymous,
                inserted.balance,
                inserted.is_active,
                inserted.created_at
            VALUES (
                @email,
                @password_hash,
                @role,
                @language_id,
                @display_name,
                @avatar_url,
                @is_anonymous,
                @bio
            );
            """;

        await using var connection = await OpenConnectionAsync(cancellationToken);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@email", System.Data.SqlDbType.VarChar, 255).Value = user.Email.Trim();
        command.Parameters.Add("@password_hash", System.Data.SqlDbType.VarChar, 255).Value = user.PasswordHash;
        command.Parameters.Add("@role", System.Data.SqlDbType.VarChar, 50).Value = user.Role;
        command.Parameters.Add("@language_id", System.Data.SqlDbType.Int).Value = ToDbValue(user.LanguageId);
        command.Parameters.Add("@display_name", System.Data.SqlDbType.NVarChar, 100).Value = ToDbValue(user.DisplayName);
        command.Parameters.Add("@avatar_url", System.Data.SqlDbType.VarChar, 500).Value = ToDbValue(user.AvatarUrl);
        command.Parameters.Add("@is_anonymous", System.Data.SqlDbType.Bit).Value = user.IsAnonymous;
        command.Parameters.Add("@bio", System.Data.SqlDbType.NVarChar, 1000).Value = ToDbValue(user.Bio);

        try
        {
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                return null;
            }

            return MapUser(reader);
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627)
        {
            return null;
        }
    }

    private async Task<SqlConnection> OpenConnectionAsync(CancellationToken cancellationToken)
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        return connection;
    }

    private static UserAccount MapUser(SqlDataReader reader)
    {
        return new UserAccount(
            reader.GetInt32(reader.GetOrdinal("id")),
            reader.GetString(reader.GetOrdinal("email")),
            reader.GetString(reader.GetOrdinal("password_hash")),
            reader.GetString(reader.GetOrdinal("role")),
            ReadNullableInt(reader, "language_id"),
            ReadNullableString(reader, "display_name"),
            ReadNullableString(reader, "avatar_url"),
            ReadNullableBool(reader, "is_anonymous") ?? true,
            ReadNullableDecimal(reader, "balance") ?? 0,
            ReadNullableBool(reader, "is_active") ?? true,
            ReadNullableDateTimeOffset(reader, "created_at"));
    }

    private static object ToDbValue<T>(T? value) => value is null ? DBNull.Value : value;

    private static int? ReadNullableInt(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetInt32(ordinal);
    }

    private static string? ReadNullableString(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    private static bool? ReadNullableBool(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetBoolean(ordinal);
    }

    private static decimal? ReadNullableDecimal(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
    }

    private static DateTimeOffset? ReadNullableDateTimeOffset(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal)
            ? null
            : new DateTimeOffset(reader.GetDateTime(ordinal), TimeSpan.Zero);
    }
}
