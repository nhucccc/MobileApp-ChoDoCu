using System.Text;
using backend.Data;
using backend.Helpers;
using backend.Hubs;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddScoped<JwtHelper>();
builder.Services.AddScoped<backend.Services.EmailService>();
builder.Services.AddSingleton<backend.Services.OtpStore>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
        // Cho phép SignalR dùng token qua query string
        opt.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var token = ctx.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(token) && ctx.HttpContext.Request.Path.StartsWithSegments("/hubs"))
                    ctx.Token = token;
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddSignalR();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(opt => opt.AddDefaultPolicy(p =>
    p.SetIsOriginAllowed(_ => true)
     .AllowAnyHeader()
     .AllowAnyMethod()
     .AllowCredentials()));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");

// Auto migrate khi khởi động
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();

    // Tạo bảng Orders nếu chưa tồn tại (migration AddOrders bị rỗng)
    db.Database.ExecuteSqlRaw(@"
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Orders' AND xtype='U')
        CREATE TABLE [Orders] (
            [Id] int NOT NULL IDENTITY,
            [Status] int NOT NULL DEFAULT 0,
            [TotalAmount] decimal(18,0) NOT NULL,
            [Quantity] int NOT NULL DEFAULT 1,
            [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
            [UpdatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
            [BuyerId] int NOT NULL,
            [ListingId] int NOT NULL,
            CONSTRAINT [PK_Orders] PRIMARY KEY ([Id]),
            CONSTRAINT [FK_Orders_Users_BuyerId] FOREIGN KEY ([BuyerId]) REFERENCES [Users]([Id]),
            CONSTRAINT [FK_Orders_Listings_ListingId] FOREIGN KEY ([ListingId]) REFERENCES [Listings]([Id])
        );
    ");

    // Thêm cột Stock nếu chưa có (migration AddStockToListing thiếu Designer file)
    db.Database.ExecuteSqlRaw(@"
        IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Listings') AND name = 'Stock')
        ALTER TABLE [Listings] ADD [Stock] int NOT NULL DEFAULT 1;
    ");
}

app.Run();
