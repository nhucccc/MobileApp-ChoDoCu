namespace backend.DTOs;

public record RegisterDto(string FullName, string Email, string Password, string? PhoneNumber);
public record LoginDto(string Email, string Password);
public record AuthResponseDto(string Token, UserDto User);

public record UserDto(int Id, string FullName, string Email, string? PhoneNumber,
    string? AvatarUrl, string? Bio, double Rating, int RatingCount, DateTime CreatedAt,
    string? Gender = null, DateTime? Birthday = null, bool IsVerified = false, string Role = "User");
