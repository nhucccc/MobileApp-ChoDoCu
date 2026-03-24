using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class UploadController : ControllerBase
{
    private readonly Cloudinary _cloudinary;

    public UploadController(IConfiguration config)
    {
        var account = new Account(
            config["Cloudinary:CloudName"],
            config["Cloudinary:ApiKey"],
            config["Cloudinary:ApiSecret"]);
        _cloudinary = new Cloudinary(account);
    }

    [HttpPost("image")]
    public async Task<IActionResult> UploadImage(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Không có file" });

        using var stream = file.OpenReadStream();
        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = "cho_do_cu",
            Transformation = new Transformation().Width(800).Height(800).Crop("limit").Quality("auto")
        };

        var result = await _cloudinary.UploadAsync(uploadParams);
        if (result.Error != null)
            return BadRequest(new { message = result.Error.Message });

        return Ok(new { url = result.SecureUrl.ToString() });
    }

    [HttpPost("video")]
    public async Task<IActionResult> UploadVideo(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Không có file" });

        // Giới hạn 100MB
        if (file.Length > 100 * 1024 * 1024)
            return BadRequest(new { message = "Video không được vượt quá 100MB" });

        using var stream = file.OpenReadStream();
        var uploadParams = new VideoUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = "cho_do_cu/videos",
            Transformation = new Transformation().Width(1280).Height(720).Crop("limit").Quality("auto")
        };

        var result = await _cloudinary.UploadAsync(uploadParams);
        if (result.Error != null)
            return BadRequest(new { message = result.Error.Message });

        return Ok(new
        {
            url = result.SecureUrl.ToString(),
            thumbnailUrl = result.SecureUrl.ToString().Replace("/upload/", "/upload/so_0,f_jpg/")
        });
    }
}
