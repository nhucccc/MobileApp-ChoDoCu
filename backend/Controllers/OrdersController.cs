using System.Security.Claims;
using backend.Data;
using backend.DTOs;
using backend.Helpers;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[ApiController]
[Route("api/orders")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly AppDbContext _db;
    public OrdersController(AppDbContext db) => _db = db;

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

    // GET /api/orders/purchases?status=all
    [HttpGet("purchases")]
    public async Task<IActionResult> GetPurchases([FromQuery] string? status)
    {
        var query = _db.Orders
            .Include(o => o.Listing).ThenInclude(l => l.Images)
            .Include(o => o.Listing).ThenInclude(l => l.User)
            .Where(o => o.BuyerId == UserId)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status) && status != "all" &&
            Enum.TryParse<OrderStatus>(status, true, out var s))
            query = query.Where(o => o.Status == s);

        var orders = await query.OrderByDescending(o => o.CreatedAt).ToListAsync();
        return Ok(orders.Select(o => MapDto(o)));
    }

    // GET /api/orders/sales?status=all
    [HttpGet("sales")]
    public async Task<IActionResult> GetSales([FromQuery] string? status)
    {
        var query = _db.Orders
            .Include(o => o.Listing).ThenInclude(l => l.Images)
            .Include(o => o.Listing).ThenInclude(l => l.User)
            .Include(o => o.Buyer)
            .Where(o => o.Listing.UserId == UserId)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status) && status != "all" &&
            Enum.TryParse<OrderStatus>(status, true, out var s))
            query = query.Where(o => o.Status == s);

        var orders = await query.OrderByDescending(o => o.CreatedAt).ToListAsync();
        return Ok(orders.Select(o => MapDto(o, includeBuyer: true)));
    }

    // POST /api/orders
    [HttpPost]
    public async Task<IActionResult> Create(CreateOrderDto dto)
    {
        // Kiểm tra listing tồn tại và không phải của chính mình trước
        var listing = await _db.Listings.FindAsync(dto.ListingId);
        if (listing == null) return NotFound();
        if (listing.UserId == UserId) return BadRequest("Không thể mua sản phẩm của chính mình");

        // Dùng transaction + row-level update để tránh race condition oversell
        await using var tx = await _db.Database.BeginTransactionAsync();

        // Trừ stock với điều kiện atomic — chỉ update nếu còn đủ hàng
        var updated = await _db.Listings
            .Where(l => l.Id == dto.ListingId && l.Stock >= dto.Quantity)
            .ExecuteUpdateAsync(s => s.SetProperty(l => l.Stock, l => l.Stock - dto.Quantity));

        if (updated == 0)
            return BadRequest("Số lượng hàng không đủ");

        var order = new Order
        {
            BuyerId = UserId,
            ListingId = dto.ListingId,
            Quantity = dto.Quantity,
            TotalAmount = listing.Price * dto.Quantity,
            Status = OrderStatus.Pending,
        };
        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        await tx.CommitAsync();

        await _db.Entry(order).Reference(o => o.Listing).LoadAsync();
        await _db.Entry(order.Listing).Collection(l => l.Images).LoadAsync();
        await _db.Entry(order.Listing).Reference(l => l.User).LoadAsync();

        // Gửi notification cho người bán
        await NotificationsController.CreateAsync(_db, order.Listing.UserId,
            "Đơn hàng mới",
            $"Bạn có đơn hàng mới cho sản phẩm \"{order.Listing.Title}\"",
            NotificationType.Order, $"/order/{order.Id}");

        return Ok(MapDto(order));
    }

    // PATCH /api/orders/{id}/cancel
    [HttpPatch("{id}/cancel")]
    public async Task<IActionResult> Cancel(int id)
    {
        var order = await _db.Orders
            .Include(o => o.Listing)
            .FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();
        if (order.BuyerId != UserId) return Forbid();
        if (order.Status != OrderStatus.Pending) return BadRequest("Chỉ có thể hủy đơn đang chờ xác nhận");

        order.Status = OrderStatus.Cancelled;
        order.UpdatedAt = DateTime.UtcNow;

        // Hoàn lại stock khi hủy
        order.Listing.Stock += order.Quantity;

        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã hủy đơn hàng" });
    }

    // PATCH /api/orders/{id}/confirm-received  (buyer xác nhận đã nhận hàng)
    [HttpPatch("{id}/confirm-received")]
    public async Task<IActionResult> ConfirmReceived(int id)
    {
        var order = await _db.Orders
            .Include(o => o.Listing)
            .FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();
        if (order.BuyerId != UserId) return Forbid();
        if (order.Status != OrderStatus.Shipping)
            return BadRequest("Chỉ có thể xác nhận khi đơn hàng đang giao");

        order.Status = OrderStatus.Delivered;
        order.UpdatedAt = DateTime.UtcNow;

        // Cộng tiền vào ví người bán
        var seller = await _db.Users.FindAsync(order.Listing.UserId);
        if (seller != null)
        {
            seller.WalletBalance += order.TotalAmount;
            _db.WalletTransactions.Add(new WalletTransaction
            {
                UserId = seller.Id,
                Amount = order.TotalAmount,
                Type = TransactionType.OrderIncome,
                Status = TransactionStatus.Completed,
                Note = $"Thu nhập từ đơn hàng #{order.Id}",
                RelatedOrderId = order.Id,
            });
        }

        await _db.SaveChangesAsync();

        // Thông báo cho người bán
        await NotificationsController.CreateAsync(_db, order.Listing.UserId,
            "Đơn hàng hoàn tất",
            $"Người mua đã xác nhận nhận hàng cho đơn #{order.Id}. Tiền đã được cộng vào ví.",
            NotificationType.Order, $"/order/{order.Id}");

        return Ok(new { message = "Đã xác nhận nhận hàng" });
    }

    // PATCH /api/orders/{id}/status  (seller)
    [HttpPatch("{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, UpdateOrderStatusDto dto)
    {
        var order = await _db.Orders
            .Include(o => o.Listing)
            .FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();
        if (order.Listing.UserId != UserId) return Forbid();

        if (!Enum.TryParse<OrderStatus>(dto.Status, true, out var newStatus))
            return BadRequest("Trạng thái không hợp lệ");

        // Seller không được phép set Delivered trực tiếp — chỉ buyer confirm-received mới được
        if (newStatus == OrderStatus.Delivered)
            return BadRequest("Chỉ người mua mới có thể xác nhận đã nhận hàng");

        order.Status = newStatus;
        order.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã cập nhật trạng thái" });
    }

    private static OrderDto MapDto(Order o, bool includeBuyer = false) => new()
    {
        Id = o.Id,
        Status = o.Status.ToString(),
        TotalAmount = o.TotalAmount,
        Quantity = o.Quantity,
        CreatedAt = o.CreatedAt,
        Listing = new OrderListingDto
        {
            Id = o.Listing.Id,
            Title = o.Listing.Title,
            ThumbnailUrl = o.Listing.Images.OrderBy(i => i.Order).FirstOrDefault()?.ImageUrl ?? "",
            Price = o.Listing.Price,
        },
        Seller = new UserDto(
            o.Listing.User.Id,
            o.Listing.User.FullName,
            o.Listing.User.Email,
            o.Listing.User.PhoneNumber,
            o.Listing.User.AvatarUrl,
            o.Listing.User.Bio,
            o.Listing.User.Rating,
            o.Listing.User.RatingCount,
            o.Listing.User.CreatedAt,
            o.Listing.User.Gender,
            o.Listing.User.Birthday,
            o.Listing.User.IsVerified),
        Buyer = includeBuyer && o.Buyer != null ? new UserDto(
            o.Buyer.Id,
            o.Buyer.FullName,
            o.Buyer.Email,
            o.Buyer.PhoneNumber,
            o.Buyer.AvatarUrl,
            o.Buyer.Bio,
            o.Buyer.Rating,
            o.Buyer.RatingCount,
            o.Buyer.CreatedAt,
            o.Buyer.Gender,
            o.Buyer.Birthday,
            o.Buyer.IsVerified) : null,
    };
}
