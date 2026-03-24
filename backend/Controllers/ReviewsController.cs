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
public class ReviewsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ReviewsController(AppDbContext db) => _db = db;

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetUserReviews(int userId)
    {
        var reviews = await _db.Reviews
            .Include(r => r.Reviewer)
            .Where(r => r.RevieweeId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return Ok(reviews.Select(r => new ReviewDto
        {
            Id = r.Id, Rating = r.Rating, Comment = r.Comment, CreatedAt = r.CreatedAt,
            Reviewer = new UserDto(r.Reviewer.Id, r.Reviewer.FullName, r.Reviewer.Email,
                r.Reviewer.PhoneNumber, r.Reviewer.AvatarUrl, r.Reviewer.Bio,
                r.Reviewer.Rating, r.Reviewer.RatingCount, r.Reviewer.CreatedAt,
                r.Reviewer.Gender, r.Reviewer.Birthday, r.Reviewer.IsVerified)
        }));
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateReview(CreateReviewDto dto)
    {
        var reviewerId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        // Kiểm tra đã từng giao dịch thành công với seller này chưa
        var hasDeliveredOrder = await _db.Orders.AnyAsync(o =>
            o.BuyerId == reviewerId &&
            o.Listing.UserId == dto.RevieweeId &&
            o.Status == OrderStatus.Delivered);
        if (!hasDeliveredOrder)
            return BadRequest(new { message = "Bạn chỉ có thể đánh giá sau khi đã nhận hàng thành công" });

        if (await _db.Reviews.AnyAsync(r => r.ReviewerId == reviewerId && r.ListingId == dto.ListingId))
            return BadRequest(new { message = "Bạn đã đánh giá giao dịch này rồi" });

        var review = new Review
        {
            ReviewerId = reviewerId,
            RevieweeId = dto.RevieweeId,
            ListingId = dto.ListingId,
            Rating = dto.Rating,
            Comment = dto.Comment
        };

        _db.Reviews.Add(review);
        await _db.SaveChangesAsync();

        // Cập nhật rating trung bình
        var reviewee = await _db.Users.FindAsync(dto.RevieweeId);
        if (reviewee != null)
        {
            var allRatings = await _db.Reviews.Where(r => r.RevieweeId == dto.RevieweeId).Select(r => r.Rating).ToListAsync();
            reviewee.Rating = allRatings.Average();
            reviewee.RatingCount = allRatings.Count;
            await _db.SaveChangesAsync();
        }

        return Ok(new { message = "Đánh giá thành công" });
    }

    [Authorize]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateReview(int id, CreateReviewDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var review = await _db.Reviews.FindAsync(id);
        if (review == null) return NotFound();
        if (review.ReviewerId != userId) return Forbid();

        review.Rating = dto.Rating;
        review.Comment = dto.Comment;
        await _db.SaveChangesAsync();

        // Cập nhật lại rating trung bình
        var allRatings = await _db.Reviews.Where(r => r.RevieweeId == review.RevieweeId).Select(r => r.Rating).ToListAsync();
        var reviewee = await _db.Users.FindAsync(review.RevieweeId);
        if (reviewee != null)
        {
            reviewee.Rating = allRatings.Average();
            reviewee.RatingCount = allRatings.Count;
            await _db.SaveChangesAsync();
        }

        return Ok(new { message = "Cập nhật đánh giá thành công" });
    }

    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteReview(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var review = await _db.Reviews.FindAsync(id);
        if (review == null) return NotFound();
        if (review.ReviewerId != userId) return Forbid();

        var revieweeId = review.RevieweeId;
        _db.Reviews.Remove(review);
        await _db.SaveChangesAsync();

        // Cập nhật lại rating
        var allRatings = await _db.Reviews.Where(r => r.RevieweeId == revieweeId).Select(r => r.Rating).ToListAsync();
        var reviewee = await _db.Users.FindAsync(revieweeId);
        if (reviewee != null)
        {
            reviewee.Rating = allRatings.Any() ? allRatings.Average() : 0;
            reviewee.RatingCount = allRatings.Count;
            await _db.SaveChangesAsync();
        }

        return Ok(new { message = "Xóa đánh giá thành công" });
    }
}
