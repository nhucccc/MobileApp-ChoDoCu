namespace backend.DTOs;

public record WalletBalanceDto(decimal Balance);

public record BankAccountDto(
    int Id,
    string BankName,
    string AccountNumber,
    string AccountHolder,
    bool IsDefault,
    DateTime CreatedAt);

public record AddBankAccountDto(
    string BankName,
    string AccountNumber,
    string AccountHolder);

public record WithdrawDto(
    decimal Amount,
    int BankAccountId);

public record WalletTransactionDto(
    int Id,
    decimal Amount,
    string Type,
    string Status,
    string? Note,
    int? RelatedOrderId,
    DateTime CreatedAt);
