namespace backend.Services;

/// Lưu OTP trong memory với thời gian hết hạn 5 phút
public class OtpStore
{
    private readonly Dictionary<string, (string Code, DateTime Expiry)> _store = new();
    // Email đã verify OTP thành công, chờ reset password (hết hạn 10 phút)
    private readonly Dictionary<string, DateTime> _verified = new();
    private readonly object _lock = new();

    public string Generate(string email)
    {
        // Dùng RandomNumberGenerator để đảm bảo entropy tốt hơn
        var bytes = new byte[3];
        System.Security.Cryptography.RandomNumberGenerator.Fill(bytes);
        var code = ((bytes[0] << 16 | bytes[1] << 8 | bytes[2]) % 900000 + 100000).ToString();
        lock (_lock)
        {
            _store[email.ToLower()] = (code, DateTime.UtcNow.AddMinutes(5));
            _verified.Remove(email.ToLower()); // xóa verified cũ nếu có
        }
        return code;
    }

    public bool Verify(string email, string code)
    {
        lock (_lock)
        {
            var key = email.ToLower();
            if (!_store.TryGetValue(key, out var entry)) return false;
            if (DateTime.UtcNow > entry.Expiry) { _store.Remove(key); return false; }
            if (entry.Code != code) return false;
            _store.Remove(key); // dùng 1 lần
            _verified[key] = DateTime.UtcNow.AddMinutes(10); // đánh dấu đã verified
            return true;
        }
    }

    /// Kiểm tra email đã verify OTP thành công chưa (dùng cho reset-password)
    public bool IsVerified(string email)
    {
        lock (_lock)
        {
            var key = email.ToLower();
            if (!_verified.TryGetValue(key, out var expiry)) return false;
            if (DateTime.UtcNow > expiry) { _verified.Remove(key); return false; }
            _verified.Remove(key); // dùng 1 lần
            return true;
        }
    }
}
