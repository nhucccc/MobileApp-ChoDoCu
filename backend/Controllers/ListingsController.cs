using System.Security.Claims;
using backend.Data;
using backend.DTOs;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ListingsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ListingsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetListings([FromQuery] ListingQueryDto query)
    {
        var userId = GetUserId();
        var q = _db.Listings
            .Include(l => l.Images)
            .Include(l => l.User)
            .Where(l => l.Status == ListingStatus.Active);

        if (!string.IsNullOrWhiteSpace(query.Keyword))
            q = q.Where(l => l.Title.Contains(query.Keyword) || l.Description.Contains(query.Keyword));
        if (!string.IsNullOrWhiteSpace(query.Category))
            q = q.Where(l => l.Category == query.Category);
        if (query.MinPrice.HasValue)
            q = q.Where(l => l.Price >= query.MinPrice.Value);
        if (query.MaxPrice.HasValue)
            q = q.Where(l => l.Price <= query.MaxPrice.Value);
        if (!string.IsNullOrWhiteSpace(query.Location))
            q = q.Where(l => l.Location.Contains(query.Location));
        if (!string.IsNullOrWhiteSpace(query.Condition))
            q = q.Where(l => l.Condition == query.Condition);

        var total = await q.CountAsync();

        // Sắp xếp theo sortBy: newest (mặc định), nearest (theo location), random, oldest, price_asc, price_desc
        IQueryable<Listing> sorted = query.SortBy switch
        {
            "newest" => q.OrderByDescending(l => l.CreatedAt),
            "oldest" => q.OrderBy(l => l.CreatedAt),
            "price_asc" => q.OrderBy(l => l.Price),
            "price_desc" => q.OrderByDescending(l => l.Price),
            "nearest" => !string.IsNullOrWhiteSpace(query.Location)
                ? q.OrderByDescending(l => l.Location.Contains(query.Location)).ThenByDescending(l => l.CreatedAt)
                : q.OrderByDescending(l => l.CreatedAt),
            "random" => q.OrderBy(l => l.Id % 97).ThenBy(l => l.Id), // stable pseudo-random dựa trên Id
            _ => q.OrderByDescending(l => l.CreatedAt)
        };

        var items = await sorted
            .Skip((query.Page - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync();

        var favoriteIds = userId.HasValue
            ? await _db.Favorites.Where(f => f.UserId == userId).Select(f => f.ListingId).ToListAsync()
            : new List<int>();

        return Ok(new { total, page = query.Page, pageSize = query.PageSize, items = items.Select(l => ToDto(l, favoriteIds)) });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetListing(int id)
    {
        var userId = GetUserId();
        var listing = await _db.Listings
            .Include(l => l.Images)
            .Include(l => l.User)
            .FirstOrDefaultAsync(l => l.Id == id);

        if (listing == null) return NotFound();

        listing.ViewCount++;
        await _db.SaveChangesAsync();

        var favoriteIds = userId.HasValue
            ? await _db.Favorites.Where(f => f.UserId == userId).Select(f => f.ListingId).ToListAsync()
            : new List<int>();

        return Ok(ToDto(listing, favoriteIds));
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateListing(CreateListingDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var listing = new Listing
        {
            Title = dto.Title,
            Description = dto.Description,
            Price = dto.Price,
            Category = dto.Category,
            Condition = dto.Condition,
            Location = dto.Location ?? string.Empty,
            Stock = dto.Stock,
            VideoUrl = dto.VideoUrl,
            UserId = userId,
            Images = dto.ImageUrls.Select((url, i) => new ListingImage { ImageUrl = url, Order = i }).ToList()
        };

        _db.Listings.Add(listing);
        await _db.SaveChangesAsync();

        await _db.Entry(listing).Reference(l => l.User).LoadAsync();
        return CreatedAtAction(nameof(GetListing), new { id = listing.Id }, ToDto(listing, new List<int>()));
    }

    [Authorize]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateListing(int id, UpdateListingDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var listing = await _db.Listings.Include(l => l.Images).FirstOrDefaultAsync(l => l.Id == id);

        if (listing == null) return NotFound();
        if (listing.UserId != userId) return Forbid();

        if (dto.Title != null) listing.Title = dto.Title;
        if (dto.Description != null) listing.Description = dto.Description;
        if (dto.Price.HasValue) listing.Price = dto.Price.Value;
        if (dto.Category != null) listing.Category = dto.Category;
        if (dto.Condition != null) listing.Condition = dto.Condition;
        if (dto.Location != null) listing.Location = dto.Location;
        if (dto.Status != null && Enum.TryParse<ListingStatus>(dto.Status, true, out var parsedStatus))
            listing.Status = parsedStatus;
        if (dto.Stock.HasValue) listing.Stock = dto.Stock.Value;
        if (dto.VideoUrl != null) listing.VideoUrl = dto.VideoUrl;
        if (dto.ImageUrls != null)
        {
            _db.ListingImages.RemoveRange(listing.Images);
            listing.Images = dto.ImageUrls.Select((url, i) => new ListingImage { ImageUrl = url, Order = i }).ToList();
        }
        listing.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return Ok(new { message = "Cập nhật thành công" });
    }

    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteListing(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var listing = await _db.Listings.FindAsync(id);
        if (listing == null) return NotFound();
        if (listing.UserId != userId) return Forbid();

        _db.Listings.Remove(listing);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa tin đăng" });
    }

    [Authorize]
    [HttpPost("{id}/favorite")]
    public async Task<IActionResult> ToggleFavorite(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var existing = await _db.Favorites.FirstOrDefaultAsync(f => f.UserId == userId && f.ListingId == id);

        if (existing != null)
        {
            _db.Favorites.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new { favorited = false });
        }

        _db.Favorites.Add(new Favorite { UserId = userId, ListingId = id });
        await _db.SaveChangesAsync();
        return Ok(new { favorited = true });
    }

    [Authorize]
    [HttpGet("favorites")]
    public async Task<IActionResult> GetFavorites()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var favorites = await _db.Favorites
            .Include(f => f.Listing).ThenInclude(l => l.Images)
            .Include(f => f.Listing).ThenInclude(l => l.User)
            .Where(f => f.UserId == userId)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        var favoriteIds = favorites.Select(f => f.ListingId).ToList();
        return Ok(favorites.Select(f => ToDto(f.Listing, favoriteIds)));
    }

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetUserListings(int userId)
    {
        var currentUserId = GetUserId();
        var q = _db.Listings.Include(l => l.Images).Include(l => l.User)
            .Where(l => l.UserId == userId);

        if (currentUserId != userId)
            q = q.Where(l => l.Status == ListingStatus.Active);

        var items = await q.OrderByDescending(l => l.CreatedAt).ToListAsync();
        var favoriteIds = currentUserId.HasValue
            ? await _db.Favorites.Where(f => f.UserId == currentUserId).Select(f => f.ListingId).ToListAsync()
            : new List<int>();

        return Ok(items.Select(l => ToDto(l, favoriteIds)));
    }

    private int? GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return claim != null ? int.Parse(claim) : null;
    }

    private static ListingDto ToDto(Listing l, List<int> favoriteIds) => new()
    {
        Id = l.Id,
        Title = l.Title,
        Description = l.Description,
        Price = l.Price,
        Category = l.Category,
        Condition = l.Condition,
        Location = l.Location,
        Status = l.Status.ToString(),
        Stock = l.Stock,
        ViewCount = l.ViewCount,
        CreatedAt = l.CreatedAt,
        ImageUrls = l.Images.OrderBy(i => i.Order).Select(i => i.ImageUrl).ToList(),
        VideoUrl = l.VideoUrl,
        Seller = new UserDto(l.User.Id, l.User.FullName, l.User.Email, l.User.PhoneNumber,
            l.User.AvatarUrl, l.User.Bio, l.User.Rating, l.User.RatingCount, l.User.CreatedAt,
            l.User.Gender, l.User.Birthday, l.User.IsVerified),
        IsFavorited = favoriteIds.Contains(l.Id)
    };
}
