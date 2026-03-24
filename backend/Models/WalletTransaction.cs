namespace backend.Models;

public enum TransactionType
{
    OrderIncome,    // Tiền từ đơn hàng bán được
    Withdrawal,     // Rút tiền
    Refund,         // Hoàn tiền
    Deposit,        // Nạp tiền
}

public enum TransactionStatus
{
    Pending,
    Completed,
    Failed,
    Rejected,
}

public class WalletTransaction
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public decimal Amount { get; set; }
    public TransactionType Type { get; set; }
    public TransactionStatus Status { get; set; } = TransactionStatus.Completed;
    public string? Note { get; set; }
    public int? RelatedOrderId { get; set; }
    public int? BankAccountId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
