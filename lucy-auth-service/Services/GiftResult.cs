using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public enum GiftStatus
{
    Success,
    InvalidRequest,
    ReceiverNotFound,
    SenderNotFound,
    CannotGiftSelf,
    RoomNotFound,
    InsufficientBalance
}

public sealed record GiftResult(
    GiftStatus Status,
    GiftResponse? Response,
    string? ErrorDetail = null);
