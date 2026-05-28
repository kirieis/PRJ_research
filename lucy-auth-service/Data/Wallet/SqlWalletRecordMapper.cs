using Lucy.AuthService.Models.Wallet;
using Microsoft.Data.SqlClient;

namespace Lucy.AuthService.Data.Wallet;

/// <summary>
/// Maps SqlDataReader columns to wallet-related domain records.
/// </summary>
internal static class SqlWalletRecordMapper
{
    public static Models.Wallet.Wallet MapWallet(SqlDataReader reader) =>
        new(
            reader.GetInt32(reader.GetOrdinal("id")),
            reader.GetInt32(reader.GetOrdinal("user_id")),
            reader.GetDecimal(reader.GetOrdinal("balance")),
            reader.GetString(reader.GetOrdinal("currency")),
            reader.GetBoolean(reader.GetOrdinal("is_locked")),
            ReadDateTimeOffset(reader, "created_at"),
            ReadNullableDateTimeOffset(reader, "updated_at"));

    public static WalletTransaction MapTransaction(SqlDataReader reader) =>
        new(
            reader.GetInt64(reader.GetOrdinal("id")),
            reader.GetString(reader.GetOrdinal("idempotency_key")),
            reader.GetString(reader.GetOrdinal("transaction_type")),
            reader.GetString(reader.GetOrdinal("status")),
            reader.GetDecimal(reader.GetOrdinal("amount")),
            ReadNullableInt(reader, "sender_wallet_id"),
            ReadNullableInt(reader, "receiver_wallet_id"),
            ReadNullableInt(reader, "room_id"),
            ReadNullableString(reader, "gift_type"),
            ReadNullableString(reader, "description"),
            ReadDateTimeOffset(reader, "created_at"),
            ReadNullableDateTimeOffset(reader, "completed_at"));

    public static WalletLedgerEntry MapLedgerEntry(SqlDataReader reader) =>
        new(
            reader.GetInt64(reader.GetOrdinal("id")),
            reader.GetInt32(reader.GetOrdinal("wallet_id")),
            reader.GetInt64(reader.GetOrdinal("transaction_id")),
            reader.GetString(reader.GetOrdinal("entry_type")),
            reader.GetDecimal(reader.GetOrdinal("amount")),
            reader.GetDecimal(reader.GetOrdinal("balance_before")),
            reader.GetDecimal(reader.GetOrdinal("balance_after")),
            ReadNullableString(reader, "description"),
            ReadDateTimeOffset(reader, "created_at"));

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

    private static DateTimeOffset ReadDateTimeOffset(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return new DateTimeOffset(reader.GetDateTime(ordinal), TimeSpan.Zero);
    }

    private static DateTimeOffset? ReadNullableDateTimeOffset(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal)
            ? null
            : new DateTimeOffset(reader.GetDateTime(ordinal), TimeSpan.Zero);
    }
}
