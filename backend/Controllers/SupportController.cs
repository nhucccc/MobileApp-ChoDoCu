using System.Security.Claims;
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Authorize]
[ApiController]
[Route("api/support")]
public class SupportController : ControllerBase
{
    private readonly AppDbContext _db;
    public SupportController(AppDbContext db) => _db = db;

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

    // User: lấy lịch sử chat hỗ trợ của mình
    [HttpGet("messages")]
    public async Task<IActionResult> GetMyMessages()
    {
        var msgs = await _db.SupportMessages
            .Where(m => m.UserId == UserId)
            .OrderBy(m => m.SentAt)
            .Select(m => new
            {
                m.Id, m.Content, m.IsFromAdmin, m.SentAt, m.IsRead
            })
            .ToListAsync();

        // Đánh dấu đã đọc các tin từ admin
        await _db.SupportMessages
            .Where(m => m.UserId == UserId && m.IsFromAdmin && !m.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.IsRead, true));

        return Ok(msgs);
    }

    // User: gửi tin nhắn hỗ trợ
    [HttpPost("messages")]
    public async Task<IActionResult> SendMessage([FromBody] SendSupportDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            return BadRequest("Nội dung không được để trống");

        var msg = new SupportMessage
        {
            UserId = UserId,
            Content = dto.Content,
            IsFromAdmin = false,
        };
        _db.SupportMessages.Add(msg);
        await _db.SaveChangesAsync();

        // Gửi notification cho admin
        var admins = await _db.Users
            .Where(u => u.Role == UserRole.Admin)
            .Select(u => u.Id)
            .ToListAsync();
        var user = await _db.Users.FindAsync(UserId);
        foreach (var adminId in admins)
        {
            await NotificationsController.CreateAsync(_db, adminId,
                "Tin nhắn hỗ trợ mới",
                $"{user?.FullName ?? "Người dùng"} vừa gửi tin nhắn hỗ trợ.",
                NotificationType.System, "/admin/support");
        }

        return Ok(new { msg.Id, msg.Content, msg.IsFromAdmin, msg.SentAt, msg.IsRead });
    }

    // Admin: lấy danh sách user có tin nhắn hỗ trợ
    [Authorize(Roles = "Admin")]
    [HttpGet("admin/users")]
    public async Task<IActionResult> GetSupportUsers()
    {
        // Lấy tất cả support messages kèm user, rồi group ở memory để tránh EF translation issue
        var msgs = await _db.SupportMessages
            .Include(m => m.User)
            .OrderByDescending(m => m.SentAt)
            .ToListAsync();

        var users = msgs
            .GroupBy(m => m.UserId)
            .Select(g =>
            {
                var latest = g.OrderByDescending(m => m.SentAt).First();
                return new
                {
                    userId = g.Key,
                    fullName = latest.User.FullName,
                    email = latest.User.Email,
                    avatarUrl = latest.User.AvatarUrl,
                    lastMessage = latest.Content,
                    lastAt = g.Max(m => m.SentAt),
                    unreadCount = g.Count(m => !m.IsFromAdmin && !m.IsRead),
                };
            })
            .OrderByDescending(x => x.lastAt)
            .ToList();

        return Ok(users);
    }

    // Admin: lấy lịch sử chat với 1 user
    [Authorize(Roles = "Admin")]
    [HttpGet("admin/messages/{userId}")]
    public async Task<IActionResult> GetUserMessages(int userId)
    {
        var msgs = await _db.SupportMessages
            .Where(m => m.UserId == userId)
            .OrderBy(m => m.SentAt)
            .Select(m => new { m.Id, m.Content, m.IsFromAdmin, m.SentAt, m.IsRead })
            .ToListAsync();

        // Đánh dấu đã đọc tin từ user
        await _db.SupportMessages
            .Where(m => m.UserId == userId && !m.IsFromAdmin && !m.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.IsRead, true));

        return Ok(msgs);
    }

    // Admin: reply tin nhắn hỗ trợ cho user
    [Authorize(Roles = "Admin")]
    [HttpPost("admin/reply/{userId}")]
    public async Task<IActionResult> Reply(int userId, [FromBody] SendSupportDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            return BadRequest("Nội dung không được để trống");

        var userExists = await _db.Users.AnyAsync(u => u.Id == userId);
        if (!userExists) return NotFound();

        var msg = new SupportMessage
        {
            UserId = userId,
            Content = dto.Content,
            IsFromAdmin = true,
        };
        _db.SupportMessages.Add(msg);
        await _db.SaveChangesAsync();

        // Thông báo cho user
        await NotificationsController.CreateAsync(_db, userId,
            "Phản hồi từ Hỗ trợ Oldie Market",
            dto.Content.Length > 60 ? dto.Content[..60] + "..." : dto.Content,
            NotificationType.System, "/support");

        return Ok(new { msg.Id, msg.Content, msg.IsFromAdmin, msg.SentAt, msg.IsRead });
    }
}

public record SendSupportDto(string Content);
