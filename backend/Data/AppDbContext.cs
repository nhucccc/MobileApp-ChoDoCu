using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<ListingImage> ListingImages => Set<ListingImage>();
    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<BankAccount> BankAccounts => Set<BankAccount>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<SupportMessage> SupportMessages => Set<SupportMessage>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // User
        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();

        // Listing price
        modelBuilder.Entity<Listing>().Property(l => l.Price).HasColumnType("decimal(18,0)");

        // Review - tránh cascade delete cycle
        modelBuilder.Entity<Review>()
            .HasOne(r => r.Reviewer).WithMany(u => u.ReviewsGiven)
            .HasForeignKey(r => r.ReviewerId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Review>()
            .HasOne(r => r.Reviewee).WithMany(u => u.ReviewsReceived)
            .HasForeignKey(r => r.RevieweeId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Review>()
            .HasOne(r => r.Listing).WithMany()
            .HasForeignKey(r => r.ListingId).OnDelete(DeleteBehavior.Restrict);

        // Conversation - tránh cascade delete cycle
        modelBuilder.Entity<Conversation>()
            .HasOne(c => c.Buyer).WithMany()
            .HasForeignKey(c => c.BuyerId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Conversation>()
            .HasOne(c => c.Seller).WithMany()
            .HasForeignKey(c => c.SellerId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Conversation>()
            .HasOne(c => c.Listing).WithMany()
            .HasForeignKey(c => c.ListingId).OnDelete(DeleteBehavior.Restrict);

        // Favorite - tránh cascade delete cycle
        modelBuilder.Entity<Favorite>()
            .HasOne(f => f.User).WithMany(u => u.Favorites)
            .HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Favorite>()
            .HasOne(f => f.Listing).WithMany(l => l.Favorites)
            .HasForeignKey(f => f.ListingId).OnDelete(DeleteBehavior.Cascade);

        // Unique: 1 user chỉ favorite 1 listing 1 lần
        modelBuilder.Entity<Favorite>()
            .HasIndex(f => new { f.UserId, f.ListingId }).IsUnique();

        // Order - tránh cascade delete cycle
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Buyer).WithMany()
            .HasForeignKey(o => o.BuyerId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Listing).WithMany()
            .HasForeignKey(o => o.ListingId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Order>()
            .Property(o => o.TotalAmount).HasColumnType("decimal(18,0)");

        // Address
        modelBuilder.Entity<Address>()
            .HasOne(a => a.User).WithMany()
            .HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.Cascade);

        // Notification
        modelBuilder.Entity<Notification>()
            .HasOne(n => n.User).WithMany()
            .HasForeignKey(n => n.UserId).OnDelete(DeleteBehavior.Cascade);

        // BankAccount
        modelBuilder.Entity<BankAccount>()
            .HasOne(b => b.User).WithMany(u => u.BankAccounts)
            .HasForeignKey(b => b.UserId).OnDelete(DeleteBehavior.Cascade);

        // WalletTransaction
        modelBuilder.Entity<WalletTransaction>()
            .HasOne(t => t.User).WithMany(u => u.WalletTransactions)
            .HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<WalletTransaction>()
            .Property(t => t.Amount).HasColumnType("decimal(18,0)");

        // SupportMessage
        modelBuilder.Entity<SupportMessage>()
            .HasOne(s => s.User).WithMany()
            .HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);

        // User wallet balance
        modelBuilder.Entity<User>()
            .Property(u => u.WalletBalance).HasColumnType("decimal(18,0)");
    }
}
