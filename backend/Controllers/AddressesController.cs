using System.Security.Claims;
using backend.Data;
using backend.DTOs;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[ApiController]
[Route("api/addresses")]
[Authorize]
public class AddressesController : ControllerBase
{
    private readonly AppDbContext _db;
    public AddressesController(AppDbContext db) => _db = db;

    private int UserId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var addresses = await _db.Addresses
            .Where(a => a.UserId == UserId)
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt)
            .ToListAsync();
        return Ok(addresses.Select(ToDto));
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateAddressDto dto)
    {
        // Nếu set default, bỏ default các địa chỉ khác
        if (dto.IsDefault)
            await _db.Addresses.Where(a => a.UserId == UserId)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false));

        var address = new Address
        {
            UserId = UserId,
            FullName = dto.FullName,
            PhoneNumber = dto.PhoneNumber,
            Street = dto.Street,
            District = dto.District,
            City = dto.City,
            IsDefault = dto.IsDefault,
        };
        _db.Addresses.Add(address);
        await _db.SaveChangesAsync();
        return Ok(ToDto(address));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, UpdateAddressDto dto)
    {
        var address = await _db.Addresses.FirstOrDefaultAsync(a => a.Id == id && a.UserId == UserId);
        if (address == null) return NotFound();

        if (dto.IsDefault == true)
            await _db.Addresses.Where(a => a.UserId == UserId && a.Id != id)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false));

        if (dto.FullName != null) address.FullName = dto.FullName;
        if (dto.PhoneNumber != null) address.PhoneNumber = dto.PhoneNumber;
        if (dto.Street != null) address.Street = dto.Street;
        if (dto.District != null) address.District = dto.District;
        if (dto.City != null) address.City = dto.City;
        if (dto.IsDefault.HasValue) address.IsDefault = dto.IsDefault.Value;

        await _db.SaveChangesAsync();
        return Ok(ToDto(address));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var address = await _db.Addresses.FirstOrDefaultAsync(a => a.Id == id && a.UserId == UserId);
        if (address == null) return NotFound();
        _db.Addresses.Remove(address);
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa địa chỉ" });
    }

    [HttpPatch("{id}/default")]
    public async Task<IActionResult> SetDefault(int id)
    {
        var address = await _db.Addresses.FirstOrDefaultAsync(a => a.Id == id && a.UserId == UserId);
        if (address == null) return NotFound();

        await _db.Addresses.Where(a => a.UserId == UserId)
            .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false));
        address.IsDefault = true;
        await _db.SaveChangesAsync();
        return Ok(ToDto(address));
    }

    private static AddressDto ToDto(Address a) => new()
    {
        Id = a.Id,
        FullName = a.FullName,
        PhoneNumber = a.PhoneNumber,
        Street = a.Street,
        District = a.District,
        City = a.City,
        IsDefault = a.IsDefault,
    };
}
