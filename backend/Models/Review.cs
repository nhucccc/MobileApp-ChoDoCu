namespace backend.Models;

public class Review
{
    public int Id { get; set; }
    public int Rating { get; set; } // 1-5
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public int ReviewerId { get; set; }
    public User Reviewer { get; set; } = null!;
    public int RevieweeId { get; set; }
    public User Reviewee { get; set; } = null!;
    public int ListingId { get; set; }
    public Listing Listing { get; set; } = null!;
}

public class Favorite
{
    public int Id { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public int ListingId { get; set; }
    public Listing Listing { get; set; } = null!;
}
