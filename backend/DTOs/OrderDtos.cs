namespace backend.DTOs;

public record CreateOrderDto(int ListingId, int Quantity = 1);

public record UpdateOrderStatusDto(string Status);

public class OrderDto
{
    public int Id { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public int Quantity { get; set; }
    public DateTime CreatedAt { get; set; }
    public OrderListingDto Listing { get; set; } = null!;
    public UserDto Seller { get; set; } = null!;
    public UserDto? Buyer { get; set; }
}

public class OrderListingDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string ThumbnailUrl { get; set; } = string.Empty;
    public decimal Price { get; set; }
}
