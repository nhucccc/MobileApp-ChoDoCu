using backend.Models;

namespace backend.DTOs;

public record CreateListingDto(
    string Title, string Description, decimal Price,
    string Category, string Condition, List<string> ImageUrls, string? Location = null, int Stock = 1, string? VideoUrl = null);

public record UpdateListingDto(
    string? Title, string? Description, decimal? Price,
    string? Category, string? Condition, string? Status, List<string>? ImageUrls, string? Location = null, int? Stock = null, string? VideoUrl = null);

public class ListingDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Condition { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int Stock { get; set; }
    public int ViewCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<string> ImageUrls { get; set; } = new();
    public string? VideoUrl { get; set; }
    public UserDto Seller { get; set; } = null!;
    public bool IsFavorited { get; set; }
}

public record ListingQueryDto(
    string? Keyword, string? Category,
    decimal? MinPrice, decimal? MaxPrice,
    string? Location,
    string? Condition = null,
    string? SortBy = null,
    int Page = 1, int PageSize = 20);
