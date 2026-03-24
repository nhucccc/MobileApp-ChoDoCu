using System.Security.Claims;
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace backend.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly AppDbContext _db;

    public ChatHub(AppDbContext db) => _db = db;

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId != null)
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        await base.OnConnectedAsync();
    }

    public async Task SendMessage(int conversationId, string content)
    {
        var senderId = int.Parse(Context.User!.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var conversation = await _db.Conversations
            .FirstOrDefaultAsync(c => c.Id == conversationId &&
                (c.BuyerId == senderId || c.SellerId == senderId));

        if (conversation == null) return;

        var message = new Message
        {
            ConversationId = conversationId,
            SenderId = senderId,
            Content = content,
            SentAt = DateTime.UtcNow
        };

        _db.Messages.Add(message);
        conversation.LastMessageAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var receiverId = conversation.BuyerId == senderId
            ? conversation.SellerId : conversation.BuyerId;

        var payload = new { message.Id, message.Content, message.SentAt, message.SenderId, conversationId };

        await Clients.Group($"user_{senderId}").SendAsync("ReceiveMessage", payload);
        await Clients.Group($"user_{receiverId}").SendAsync("ReceiveMessage", payload);
    }

    public async Task MarkAsRead(int conversationId)
    {
        var userId = int.Parse(Context.User!.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var unread = await _db.Messages
            .Where(m => m.ConversationId == conversationId && m.SenderId != userId && !m.IsRead)
            .ToListAsync();
        unread.ForEach(m => m.IsRead = true);
        await _db.SaveChangesAsync();
    }
}
