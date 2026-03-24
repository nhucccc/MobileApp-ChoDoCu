namespace backend.DTOs;

public record SendMessageDto(int ConversationId, string Content);
public record StartConversationDto(int SellerId, int ListingId, string FirstMessage);

public class ConversationDto
{
    public int Id { get; set; }
    public UserDto OtherUser { get; set; } = null!;
    public ListingDto Listing { get; set; } = null!;
    public MessageDto? LastMessage { get; set; }
    public int UnreadCount { get; set; }
}

public class MessageDto
{
    public int Id { get; set; }
    public string Content { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime SentAt { get; set; }
    public int SenderId { get; set; }
}
