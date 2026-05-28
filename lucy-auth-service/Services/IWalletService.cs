using Lucy.AuthService.Contracts;

namespace Lucy.AuthService.Services;

public interface IWalletService
{
    Task<GiftResult> GiftAsync(int senderId, GiftRequest request, CancellationToken cancellationToken);
}
