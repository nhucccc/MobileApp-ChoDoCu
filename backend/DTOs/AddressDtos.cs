namespace backend.DTOs;

public record CreateAddressDto(
    string FullName,
    string PhoneNumber,
    string Street,
    string District,
    string City,
    bool IsDefault = false);

public record UpdateAddressDto(
    string? FullName,
    string? PhoneNumber,
    string? Street,
    string? District,
    string? City,
    bool? IsDefault);

public class AddressDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public string FullAddress => $"{Street}, {District}, {City}";
}
