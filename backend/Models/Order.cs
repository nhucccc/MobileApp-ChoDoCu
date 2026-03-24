namespace backend.Models;

public enum OrderStatus
{
    Pending,       // Chờ xác nhận
    Processing,    // Đang xử lý
    Shipping,      // Chờ giao hàng
    Delivered,     // Đã giao
    Returned,      // Trả hàng
    Cancelled      // Hủy hàng
}

public class Order
{
    public int Id { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public decimal TotalAmount { get; set; }
    public int Quantity { get; set; } = 1;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Buyer
    public int BuyerId { get; set; }
    public User Buyer { get; set; } = null!;

    // Listing
    public int ListingId { get; set; }
    public Listing Listing { get; set; } = null!;
}
