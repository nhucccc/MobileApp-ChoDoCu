using System.Security.Claims;
using backend.Data;
using backend.DTOs;
using backend.Helpers;
using backend.Models;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtHelper _jwt;
    private readonly EmailService _email;
    private readonly OtpStore _otpStore;

    public AuthController(AppDbContext db, JwtHelper jwt, EmailService email, OtpStore otpStore)
    {
        _db = db;
        _jwt = jwt;
        _email = email;
        _otpStore = otpStore;
    }

    [HttpPost("send-otp")]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Email))
            return BadRequest(new { message = "Email không hợp lệ" });

        var code = _otpStore.Generate(dto.Email);
        try
        {
            await _email.SendOtpAsync(dto.Email, code);
            return Ok(new { message = "Đã gửi mã xác thực" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Không thể gửi email: {ex.Message}" });
        }
    }

    [HttpPost("verify-otp")]
    public IActionResult VerifyOtp([FromBody] VerifyOtpDto dto)
    {
        var ok = _otpStore.Verify(dto.Email, dto.Code);
        if (!ok) return BadRequest(new { message = "Mã xác thực không đúng hoặc đã hết hạn" });
        return Ok(new { message = "Xác thực thành công" });
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        if (await _db.Users.AnyAsync(u => u.Email == dto.Email))
            return BadRequest(new { message = "Email đã được sử dụng" });

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            PhoneNumber = dto.PhoneNumber,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password)
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return Ok(new AuthResponseDto(_jwt.GenerateToken(user), ToDto(user)));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
        if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng" });

        return Ok(new AuthResponseDto(_jwt.GenerateToken(user), ToDto(user)));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();
        return Ok(ToDto(user));
    }

    [Authorize]
    [HttpGet("me/stats")]
    public async Task<IActionResult> GetMyStats()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var totalListings = await _db.Listings.CountAsync(l => l.UserId == userId);
        var activeListings = await _db.Listings.CountAsync(l => l.UserId == userId && l.Status == ListingStatus.Active);
        var soldListings = await _db.Orders.CountAsync(o => o.Listing.UserId == userId && o.Status == OrderStatus.Delivered);
        var favoriteCount = await _db.Favorites.CountAsync(f => f.UserId == userId);
        var user = await _db.Users.FindAsync(userId);

        return Ok(new
        {
            totalListings,
            activeListings,
            soldListings,
            favoriteCount,
            rating = user?.Rating ?? 0.0,
            ratingCount = user?.RatingCount ?? 0,
        });
    }

    [Authorize]
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        if (dto.FullName != null) user.FullName = dto.FullName;
        if (dto.PhoneNumber != null) user.PhoneNumber = dto.PhoneNumber;
        if (dto.Bio != null) user.Bio = dto.Bio;
        if (dto.AvatarUrl != null) user.AvatarUrl = dto.AvatarUrl;
        if (dto.Gender != null) user.Gender = dto.Gender;
        if (dto.Birthday.HasValue) user.Birthday = dto.Birthday;

        await _db.SaveChangesAsync();
        return Ok(ToDto(user));
    }

    [Authorize]
    [HttpDelete("me")]
    public async Task<IActionResult> DeleteAccount()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();
        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Tài khoản đã được xóa" });
    }

    [HttpPost("google")]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginDto dto)
    {
        // Verify ID token với Google
        using var http = new HttpClient();
        var resp = await http.GetAsync($"https://oauth2.googleapis.com/tokeninfo?id_token={dto.IdToken}");
        if (!resp.IsSuccessStatusCode)
            return Unauthorized(new { message = "Google token không hợp lệ" });

        var json = await resp.Content.ReadAsStringAsync();
        using var doc = System.Text.Json.JsonDocument.Parse(json);
        var root = doc.RootElement;

        // Kiểm tra audience
        var aud = root.GetProperty("aud").GetString();
        if (aud != "176324381924-kre99vakl49ipe6hgtea6n0odme35b1j.apps.googleusercontent.com")
            return Unauthorized(new { message = "Client ID không khớp" });

        var email = root.GetProperty("email").GetString()!;
        var name = root.TryGetProperty("name", out var n) ? n.GetString() ?? email : email;
        var picture = root.TryGetProperty("picture", out var p) ? p.GetString() : null;

        // Tìm hoặc tạo user
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null)
        {
            user = new User
            {
                FullName = name,
                Email = email,
                AvatarUrl = picture,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()),
            };
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
        }

        return Ok(new AuthResponseDto(_jwt.GenerateToken(user), ToDto(user)));
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
    {
        // Phải verify OTP trước mới được reset
        if (!_otpStore.IsVerified(dto.Email))
            return BadRequest(new { message = "Vui lòng xác thực OTP trước khi đổi mật khẩu" });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
        if (user == null) return BadRequest(new { message = "Email không tồn tại" });

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đổi mật khẩu thành công" });
    }

    private static UserDto ToDto(User u) =>
        new(u.Id, u.FullName, u.Email, u.PhoneNumber, u.AvatarUrl, u.Bio,
            u.Rating, u.RatingCount, u.CreatedAt, u.Gender, u.Birthday, u.IsVerified, u.Role.ToString());

    // POST /api/auth/setup-admin  — chỉ dùng khi chưa có admin
    [HttpPost("setup-admin")]
    [AllowAnonymous]
    public async Task<IActionResult> SetupAdmin(SetupAdminDto dto)
    {
        if (await _db.Users.AnyAsync(u => u.Role == UserRole.Admin))
            return BadRequest(new { message = "Admin đã tồn tại" });

        var admin = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Role = UserRole.Admin,
            IsVerified = true,
        };
        _db.Users.Add(admin);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Tạo admin thành công", email = admin.Email });
    }
}

public record UpdateProfileDto(string? FullName, string? PhoneNumber, string? Bio, string? AvatarUrl,
    string? CoverUrl = null, string? Gender = null, DateTime? Birthday = null);
public record GoogleLoginDto(string IdToken);
public record SendOtpDto(string Email);
public record VerifyOtpDto(string Email, string Code);
public record ResetPasswordDto(string Email, string NewPassword);
public record SetupAdminDto(string FullName, string Email, string Password);
