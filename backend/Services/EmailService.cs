using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace backend.Services;

public class EmailService
{
    private const string SmtpHost = "smtp.gmail.com";
    private const int SmtpPort = 587;
    private const string SenderEmail = "han255368@gmail.com";
    private const string SenderPassword = "krxbnkkqzxfnjyyb";
    private const string SenderName = "Oldie Market";

    public async Task SendOtpAsync(string toEmail, string otp)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(SenderName, SenderEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = "Mã xác thực Oldie Market";

        message.Body = new TextPart("html")
        {
            Text = $"""
            <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #eee;border-radius:12px;">
              <h2 style="color:#4CAF50;text-align:center;">Oldie Market</h2>
              <p style="color:#333;font-size:15px;">Xin chào,</p>
              <p style="color:#333;font-size:15px;">Mã xác thực của bạn là:</p>
              <div style="text-align:center;margin:24px 0;">
                <span style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#1A1A1A;">{otp}</span>
              </div>
              <p style="color:#777;font-size:13px;">Mã có hiệu lực trong <strong>5 phút</strong>. Không chia sẻ mã này với ai.</p>
              <hr style="border:none;border-top:1px solid #eee;margin:20px 0;">
              <p style="color:#aaa;font-size:12px;text-align:center;">© 2026 Oldie Market</p>
            </div>
            """
        };

        using var client = new SmtpClient();
        await client.ConnectAsync(SmtpHost, SmtpPort, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(SenderEmail, SenderPassword);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}
