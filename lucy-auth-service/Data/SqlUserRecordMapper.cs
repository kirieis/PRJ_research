using Lucy.AuthService.Models;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data;

internal static class SqlUserRecordMapper
{
    public static UserAccount MapUser(SqlDataReader reader) =>
        new(
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

    public static PersonaProfile MapPersona(SqlDataReader reader) =>
        new(
            reader.GetInt32(reader.GetOrdinal("id")),
            reader.GetInt32(reader.GetOrdinal("user_id")),
            reader.GetString(reader.GetOrdinal("public_subject")),
            reader.GetString(reader.GetOrdinal("display_name")),
            reader.GetString(reader.GetOrdinal("avatar_code")),
            ReadNullableString(reader, "avatar_url"),
            ReadNullableDateTimeOffset(reader, "created_at") ?? DateTimeOffset.UtcNow,
            ReadNullableDateTimeOffset(reader, "updated_at"));

    public static int? ReadNullableInt(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetInt32(ordinal);
    }

    public static string? ReadNullableString(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    public static bool? ReadNullableBool(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetBoolean(ordinal);
    }

    public static decimal? ReadNullableDecimal(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
    }

    public static DateTimeOffset? ReadNullableDateTimeOffset(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal)
            ? null
            : new DateTimeOffset(reader.GetDateTime(ordinal), TimeSpan.Zero);
    }
}
