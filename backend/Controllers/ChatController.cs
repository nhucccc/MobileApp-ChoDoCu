using System.Security.Claims;
using backend.Data;
using backend.DTOs;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly AppDbContext _db;
    public ChatController(AppDbContext db) => _db = db;

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var uid = UserId;
        var convs = await _db.Conversations
            .Include(c => c.Buyer)
            .Include(c => c.Seller)
            .Include(c => c.Listing).ThenInclude(l => l.Images)
            .Include(c => c.Messages.OrderByDescending(m => m.SentAt).Take(1))
            .Where(c => c.BuyerId == uid || c.SellerId == uid)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();

        // Lấy unread counts trong 1 query duy nhất thay vì N queries
        var convIds = convs.Select(c => c.Id).ToList();
        var unreadCounts = await _db.Messages
            .Where(m => convIds.Contains(m.ConversationId) && m.SenderId != uid && !m.IsRead)
            .GroupBy(m => m.ConversationId)
            .Select(g => new { ConversationId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ConversationId, x => x.Count);

        var result = convs.Select(c =>
        {
            var other = c.BuyerId == uid ? c.Seller : c.Buyer;
            return new ConversationDto
            {
                Id = c.Id,
                OtherUser = new UserDto(other.Id, other.FullName, other.Email, other.PhoneNumber,
                    other.AvatarUrl, other.Bio, other.Rating, other.RatingCount, other.CreatedAt,
                    other.Gender, other.Birthday, other.IsVerified),
                Listing = new ListingDto
                {
                    Id = c.Listing.Id, Title = c.Listing.Title, Price = c.Listing.Price,
                    ImageUrls = c.Listing.Images.Take(1).Select(i => i.ImageUrl).ToList()
                },
                LastMessage = c.Messages.FirstOrDefault() is { } m
                    ? new MessageDto { Id = m.Id, Content = m.Content, SentAt = m.SentAt, SenderId = m.SenderId, IsRead = m.IsRead }
                    : null,
                UnreadCount = unreadCounts.GetValueOrDefault(c.Id, 0)
            };
        });

        return Ok(result);
    }

    [HttpGet("conversations/{id}/messages")]
    public async Task<IActionResult> GetMessages(int id, [FromQuery] int page = 1)
    {
        var uid = UserId;
        var conv = await _db.Conversations.FirstOrDefaultAsync(c => c.Id == id && (c.BuyerId == uid || c.SellerId == uid));
        if (conv == null) return NotFound();

        var messages = await _db.Messages
            .Where(m => m.ConversationId == id)
            .OrderByDescending(m => m.SentAt)
            .Skip((page - 1) * 30).Take(30)
            .Select(m => new MessageDto { Id = m.Id, Content = m.Content, SentAt = m.SentAt, SenderId = m.SenderId, IsRead = m.IsRead })
            .ToListAsync();

        return Ok(messages);
    }

    [HttpPost("start")]
    public async Task<IActionResult> StartConversation(StartConversationDto dto)
    {
        var uid = UserId;
        if (uid == dto.SellerId) return BadRequest(new { message = "Không thể chat với chính mình" });

        var existing = await _db.Conversations.FirstOrDefaultAsync(
            c => c.BuyerId == uid && c.SellerId == dto.SellerId && c.ListingId == dto.ListingId);

        if (existing != null) return Ok(new { conversationId = existing.Id });

        var conv = new Conversation { BuyerId = uid, SellerId = dto.SellerId, ListingId = dto.ListingId };
        _db.Conversations.Add(conv);
        await _db.SaveChangesAsync();

        _db.Messages.Add(new Message { ConversationId = conv.Id, SenderId = uid, Content = dto.FirstMessage });
        conv.LastMessageAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new { conversationId = conv.Id });
    }
}
