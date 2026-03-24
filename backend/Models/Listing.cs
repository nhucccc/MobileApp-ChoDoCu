namespace backend.Models;

public enum ListingStatus { Active, Hidden, Sold }

public class Listing
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Condition { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty; // tỉnh/thành phố
    public ListingStatus Status { get; set; } = ListingStatus.Active;
    public int Stock { get; set; } = 1;
    public int ViewCount { get; set; } = 0;
    public string? VideoUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public ICollection<ListingImage> Images { get; set; } = new List<ListingImage>();
    public ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
}

public class ListingImage
{
    public int Id { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int Order { get; set; } = 0;
    public int ListingId { get; set; }
    public Listing Listing { get; set; } = null!;
}
