namespace backend.DTOs;

public record CreateReviewDto(int RevieweeId, int ListingId, int Rating, string? Comment);

public class ReviewDto
{
    public int Id { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public UserDto Reviewer { get; set; } = null!;
}
