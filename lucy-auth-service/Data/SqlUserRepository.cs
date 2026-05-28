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
}
