using Lucy.AuthService.Contracts.Wallet;

namespace Lucy.AuthService.Services.Wallet;

public interface IWalletService
{
    Task<WalletServiceResult<WalletBalanceResponse>> GetBalanceAsync(
        int userId,
        CancellationToken cancellationToken);

    Task<WalletServiceResult<GiftResponse>> GiftAsync(
        int senderUserId,
        GiftRequest request,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken);

    Task<WalletServiceResult<DepositResponse>> DepositAsync(
        int userId,
        DepositRequest request,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken);
}
