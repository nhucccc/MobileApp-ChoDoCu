using System.Security.Claims;
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _db;
    public AdminController(AppDbContext db) => _db = db;

    // ---- Dashboard stats ----
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var totalUsers = await _db.Users.CountAsync(u => u.Role == UserRole.User);
        var totalListings = await _db.Listings.CountAsync();
        var activeListings = await _db.Listings.CountAsync(l => l.Status == ListingStatus.Active);
        var totalOrders = await _db.Orders.CountAsync();
        var pendingOrders = await _db.Orders.CountAsync(o => o.Status == OrderStatus.Pending);
        var processingOrders = await _db.Orders.CountAsync(o => o.Status == OrderStatus.Processing);
        var shippingOrders = await _db.Orders.CountAsync(o => o.Status == OrderStatus.Shipping);
        var deliveredOrders = await _db.Orders.CountAsync(o => o.Status == OrderStatus.Delivered);
        var cancelledOrders = await _db.Orders.CountAsync(o => o.Status == OrderStatus.Cancelled);
        var totalRevenue = await _db.Orders
            .Where(o => o.Status == OrderStatus.Delivered)
            .SumAsync(o => (decimal?)o.TotalAmount) ?? 0;
        var newUsersToday = await _db.Users
            .CountAsync(u => u.CreatedAt.Date == DateTime.UtcNow.Date);
        var pendingWithdrawals = await _db.WalletTransactions
            .CountAsync(t => t.Type == TransactionType.Withdrawal && t.Status == TransactionStatus.Pending);

        return Ok(new
        {
            totalUsers,
            totalListings,
            activeListings,
            totalOrders,
            pendingOrders,
            processingOrders,
            shippingOrders,
            deliveredOrders,
            cancelledOrders,
            totalRevenue,
            newUsersToday,
            pendingWithdrawals,
        });
    }

    // ---- Users ----
    [HttpGet("users")]
    public async Task<IActionResult> GetUsers([FromQuery] string? keyword, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var q = _db.Users.AsQueryable();
        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(u => u.FullName.Contains(keyword) || u.Email.Contains(keyword));

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(u => new
            {
                u.Id, u.FullName, u.Email, u.PhoneNumber, u.AvatarUrl,
                u.IsVerified, u.Role, u.Rating, u.RatingCount,
                u.WalletBalance, u.CreatedAt,
                listingCount = _db.Listings.Count(l => l.UserId == u.Id),
            }).ToListAsync();

        return Ok(new { total, page, pageSize, items });
    }

    [HttpPut("users/{id}/role")]
    public async Task<IActionResult> SetRole(int id, [FromBody] SetRoleDto dto)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();
        if (Enum.TryParse<UserRole>(dto.Role, true, out var role))
            user.Role = role;
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã cập nhật role" });
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();
        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa người dùng" });
    }

    // ---- Listings ----
    [HttpGet("listings")]
    public async Task<IActionResult> GetListings([FromQuery] string? keyword, [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var q = _db.Listings.Include(l => l.User).Include(l => l.Images).AsQueryable();
        if (!string.IsNullOrWhiteSpace(keyword))
            q = q.Where(l => l.Title.Contains(keyword));
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<ListingStatus>(status, true, out var s))
            q = q.Where(l => l.Status == s);

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .ToListAsync();

        return Ok(new
        {
            total, page, pageSize,
            items = items.Select(l => new
            {
                l.Id, l.Title, l.Price, l.Category, l.Status, l.Stock,
                l.ViewCount, l.CreatedAt,
                thumbnail = l.Images.OrderBy(i => i.Order).Select(i => i.ImageUrl).FirstOrDefault(),
                seller = new { l.User.Id, l.User.FullName, l.User.Email },
            })
        });
    }

    [HttpDelete("listings/{id}")]
    public async Task<IActionResult> DeleteListing(int id)
    {
        var listing = await _db.Listings.FindAsync(id);
        if (listing == null) return NotFound();
        _db.Listings.Remove(listing);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa tin đăng" });
    }

    [HttpPut("listings/{id}/status")]
    public async Task<IActionResult> SetListingStatus(int id, [FromBody] SetStatusDto dto)
    {
        var listing = await _db.Listings.FindAsync(id);
        if (listing == null) return NotFound();
        if (Enum.TryParse<ListingStatus>(dto.Status, true, out var s))
            listing.Status = s;
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã cập nhật trạng thái" });
    }

    // ---- Orders ----
    [HttpGet("orders")]
    public async Task<IActionResult> GetOrders([FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var q = _db.Orders.Include(o => o.Listing).ThenInclude(l => l.User).Include(o => o.Buyer).AsQueryable();
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<OrderStatus>(status, true, out var s))
            q = q.Where(o => o.Status == s);

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .ToListAsync();

        return Ok(new
        {
            total, page, pageSize,
            items = items.Select(o => new
            {
                o.Id, o.Status, o.TotalAmount, o.Quantity, o.CreatedAt,
                listing = new { o.Listing.Id, o.Listing.Title },
                buyer = new { o.Buyer.Id, o.Buyer.FullName, o.Buyer.Email },
                seller = new { o.Listing.User.Id, o.Listing.User.FullName },
            })
        });
    }

    [HttpPut("orders/{id}/status")]
    public async Task<IActionResult> SetOrderStatus(int id, [FromBody] SetStatusDto dto)
    {
        var order = await _db.Orders
            .Include(o => o.Listing)
            .FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();
        if (!Enum.TryParse<OrderStatus>(dto.Status, true, out var s))
            return BadRequest("Trạng thái không hợp lệ");

        var oldStatus = order.Status;
        order.Status = s;
        order.UpdatedAt = DateTime.UtcNow;

        // Nếu admin set Delivered và chưa từng cộng tiền → cộng tiền cho seller
        if (s == OrderStatus.Delivered && oldStatus != OrderStatus.Delivered)
        {
            // Kiểm tra chưa có transaction income cho đơn này (tránh double-credit)
            var alreadyPaid = await _db.WalletTransactions.AnyAsync(t =>
                t.RelatedOrderId == order.Id && t.Type == TransactionType.OrderIncome);
            if (!alreadyPaid)
            {
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
                        Note = $"Thu nhập từ đơn hàng #{order.Id} (admin xác nhận)",
                        RelatedOrderId = order.Id,
                    });
                }
            }
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã cập nhật trạng thái đơn hàng" });
    }

    // ---- Withdrawals ----
    [HttpGet("withdrawals")]
    public async Task<IActionResult> GetWithdrawals([FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var q = _db.WalletTransactions
            .Include(t => t.User)
            .Where(t => t.Type == TransactionType.Withdrawal)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<TransactionStatus>(status, true, out var s))
            q = q.Where(t => t.Status == s);

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .ToListAsync();

        return Ok(new
        {
            total, page, pageSize,
            items = items.Select(t => new
            {
                t.Id, t.Amount, t.Status, t.Note, t.CreatedAt,
                user = new { t.User.Id, t.User.FullName, t.User.Email, t.User.WalletBalance },
            })
        });
    }

    [HttpPatch("withdrawals/{id}/approve")]
    public async Task<IActionResult> ApproveWithdrawal(int id)
    {
        var tx = await _db.WalletTransactions
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Id == id);
        if (tx == null) return NotFound();
        if (tx.Type != TransactionType.Withdrawal) return BadRequest();
        if (tx.Status != TransactionStatus.Pending) return BadRequest("Giao dịch không ở trạng thái chờ");

        tx.Status = TransactionStatus.Completed;
        await _db.SaveChangesAsync();

        // Thông báo cho người dùng
        await NotificationsController.CreateAsync(_db, tx.UserId,
            "Rút tiền thành công",
            $"Yêu cầu rút {tx.Amount:N0}đ của bạn đã được duyệt và xử lý thành công.",
            NotificationType.System, "/wallet");

        return Ok(new { message = "Đã duyệt rút tiền" });
    }

    [HttpPatch("withdrawals/{id}/reject")]
    public async Task<IActionResult> RejectWithdrawal(int id, [FromBody] RejectDto dto)
    {
        var tx = await _db.WalletTransactions
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Id == id);
        if (tx == null) return NotFound();
        if (tx.Type != TransactionType.Withdrawal) return BadRequest();
        if (tx.Status != TransactionStatus.Pending) return BadRequest("Giao dịch không ở trạng thái chờ");

        tx.Status = TransactionStatus.Rejected;
        // Hoàn tiền về ví
        tx.User.WalletBalance += tx.Amount;
        await _db.SaveChangesAsync();

        // Thông báo cho người dùng
        await NotificationsController.CreateAsync(_db, tx.UserId,
            "Yêu cầu rút tiền bị từ chối",
            $"Yêu cầu rút {tx.Amount:N0}đ đã bị từ chối. Lý do: {dto.Reason ?? "Không có"}. Tiền đã được hoàn về ví.",
            NotificationType.System, "/wallet");

        return Ok(new { message = "Đã từ chối và hoàn tiền" });
    }

    // ---- Broadcast Notification ----
    [HttpPost("notifications/broadcast")]
    public async Task<IActionResult> BroadcastNotification([FromBody] BroadcastDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title) || string.IsNullOrWhiteSpace(dto.Body))
            return BadRequest("Tiêu đề và nội dung không được để trống");

        var targetRole = dto.TargetRole?.ToLower() == "admin" ? UserRole.Admin : UserRole.User;
        var userIds = await _db.Users
            .Where(u => u.Role == targetRole)
            .Select(u => u.Id)
            .ToListAsync();

        if (!Enum.TryParse<NotificationType>(dto.Type ?? "Promotion", true, out var notifType))
            notifType = NotificationType.Promotion;

        foreach (var uid in userIds)
        {
            _db.Notifications.Add(new Notification
            {
                UserId = uid,
                Title = dto.Title,
                Body = dto.Body,
                Type = notifType,
                ActionUrl = dto.ActionUrl,
            });
        }
        await _db.SaveChangesAsync();

        return Ok(new { message = $"Đã gửi thông báo đến {userIds.Count} người dùng" });
    }
}

public record SetRoleDto(string Role);
public record SetStatusDto(string Status);
public record RejectDto(string? Reason);
public record BroadcastDto(string Title, string Body, string? Type, string? TargetRole, string? ActionUrl);
