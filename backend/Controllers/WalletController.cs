using System.Security.Claims;
using backend.Data;
using backend.DTOs;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[ApiController]
[Route("api/wallet")]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly AppDbContext _db;
    public WalletController(AppDbContext db) => _db = db;

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

    // GET /api/wallet/balance
    [HttpGet("balance")]
    public async Task<IActionResult> GetBalance()
    {
        var user = await _db.Users.FindAsync(UserId);
        if (user == null) return NotFound();
        return Ok(new WalletBalanceDto(user.WalletBalance));
    }

    // GET /api/wallet/transactions
    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions()
    {
        var txs = await _db.WalletTransactions
            .Where(t => t.UserId == UserId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();
        return Ok(txs.Select(t => new WalletTransactionDto(
            t.Id, t.Amount, t.Type.ToString(), t.Status.ToString(),
            t.Note, t.RelatedOrderId, t.CreatedAt)));
    }

    // GET /api/wallet/bank-accounts
    [HttpGet("bank-accounts")]
    public async Task<IActionResult> GetBankAccounts()
    {
        var accounts = await _db.BankAccounts
            .Where(b => b.UserId == UserId)
            .OrderByDescending(b => b.IsDefault)
            .ThenByDescending(b => b.CreatedAt)
            .ToListAsync();
        return Ok(accounts.Select(MapBank));
    }

    // POST /api/wallet/bank-accounts
    [HttpPost("bank-accounts")]
    public async Task<IActionResult> AddBankAccount(AddBankAccountDto dto)
    {
        var hasAny = await _db.BankAccounts.AnyAsync(b => b.UserId == UserId);
        var account = new BankAccount
        {
            UserId = UserId,
            BankName = dto.BankName,
            AccountNumber = dto.AccountNumber,
            AccountHolder = dto.AccountHolder,
            IsDefault = !hasAny,
        };
        _db.BankAccounts.Add(account);
        await _db.SaveChangesAsync();
        return Ok(MapBank(account));
    }

    // DELETE /api/wallet/bank-accounts/{id}
    [HttpDelete("bank-accounts/{id}")]
    public async Task<IActionResult> DeleteBankAccount(int id)
    {
        var account = await _db.BankAccounts.FindAsync(id);
        if (account == null) return NotFound();
        if (account.UserId != UserId) return Forbid();
        _db.BankAccounts.Remove(account);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa tài khoản ngân hàng" });
    }

    // PATCH /api/wallet/bank-accounts/{id}/set-default
    [HttpPatch("bank-accounts/{id}/set-default")]
    public async Task<IActionResult> SetDefault(int id)
    {
        var accounts = await _db.BankAccounts.Where(b => b.UserId == UserId).ToListAsync();
        foreach (var a in accounts) a.IsDefault = (a.Id == id);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã đặt làm mặc định" });
    }

    // POST /api/wallet/withdraw
    [HttpPost("withdraw")]
    public async Task<IActionResult> Withdraw(WithdrawDto dto)
    {
        if (dto.Amount <= 0) return BadRequest("Số tiền không hợp lệ");
        if (dto.Amount < 10000) return BadRequest("Số tiền rút tối thiểu là 10,000đ");

        var user = await _db.Users.FindAsync(UserId);
        if (user == null) return NotFound();
        if (user.WalletBalance < dto.Amount)
            return BadRequest("Số dư không đủ");

        var bank = await _db.BankAccounts.FindAsync(dto.BankAccountId);
        if (bank == null || bank.UserId != UserId)
            return BadRequest("Tài khoản ngân hàng không hợp lệ");

        // Giữ tiền (trừ ví ngay, chờ admin duyệt mới hoàn tất)
        user.WalletBalance -= dto.Amount;

        var tx = new WalletTransaction
        {
            UserId = UserId,
            Amount = dto.Amount,
            Type = TransactionType.Withdrawal,
            Status = TransactionStatus.Pending,
            Note = $"Rút tiền về {bank.BankName} - {bank.AccountNumber} ({bank.AccountHolder})",
            BankAccountId = dto.BankAccountId,
        };
        _db.WalletTransactions.Add(tx);
        await _db.SaveChangesAsync();

        // Gửi notification cho tất cả admin
        var admins = await _db.Users
            .Where(u => u.Role == UserRole.Admin)
            .Select(u => u.Id)
            .ToListAsync();
        foreach (var adminId in admins)
        {
            await NotificationsController.CreateAsync(_db, adminId,
                "Yêu cầu rút tiền mới",
                $"Người dùng {user.FullName} yêu cầu rút {dto.Amount:N0}đ. Vui lòng xử lý.",
                NotificationType.System, "/admin/withdrawals");
        }

        return Ok(new WalletTransactionDto(
            tx.Id, tx.Amount, tx.Type.ToString(), tx.Status.ToString(),
            tx.Note, tx.RelatedOrderId, tx.CreatedAt));
    }

    private static BankAccountDto MapBank(BankAccount b) =>
        new(b.Id, b.BankName, b.AccountNumber, b.AccountHolder, b.IsDefault, b.CreatedAt);
}
