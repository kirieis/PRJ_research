namespace Lucy.AuthService.Contracts.Wallet;

public sealed record SepayWebhookRequest(
    string Gateway,
    string TransactionDate,
    string AccountNumber,
    string Code,
    string Content,
    string TransferType,
    decimal TransferAmount,
    decimal Accumulated);
