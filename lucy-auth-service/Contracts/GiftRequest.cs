using System.ComponentModel.DataAnnotations;

namespace Lucy.AuthService.Contracts;

public sealed record GiftRequest(
    [property: Range(1, int.MaxValue)]
    int ReceiverId,

    [property: Range(typeof(decimal), "0.01", "999999999999.99")]
    decimal Amount,

    [property: Required, MaxLength(100)]
    string GiftType,

    [property: Range(1, int.MaxValue)]
    int? RoomId,

    [property: Required, MaxLength(100)]
    string IdempotencyKey,

    [property: MaxLength(1000)]
    string? Message = null);
