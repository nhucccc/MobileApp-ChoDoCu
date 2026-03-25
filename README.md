<div align="center">

# 🛍️ Chợ Đồ Cũ

**Ứng dụng mua bán đồ cũ trực tuyến**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![ASP.NET Core](https://img.shields.io/badge/ASP.NET_Core-8.0-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com)
[![SQL Server](https://img.shields.io/badge/SQL_Server-Azure_Edge-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](https://hub.docker.com/_/microsoft-azure-sql-edge)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)

> Nền tảng kết nối người mua và người bán đồ cũ, hỗ trợ chat realtime, ví điện tử và quản lý đơn hàng.

🌐 **API Live:** [https://berlinmmo.site/api](https://berlinmmo.site/api)

</div>

---

## ✨ Tính năng

| Tính năng | Mô tả |
|-----------|-------|
| 🔐 Xác thực | Đăng ký / đăng nhập bằng JWT + OTP qua email |
| 📦 Đăng tin | Đăng bán đồ cũ với ảnh, video, danh mục, địa chỉ |
| 🔍 Tìm kiếm | Lọc theo danh mục, vị trí, giá, tình trạng |
| 💬 Chat | Nhắn tin realtime giữa người mua và người bán (SignalR) |
| 🛒 Đặt hàng | Mua hàng, theo dõi trạng thái đơn hàng |
| 💰 Ví điện tử | Nạp tiền, thanh toán, lịch sử giao dịch |
| ⭐ Đánh giá | Đánh giá người bán sau khi giao dịch |
| 🔔 Thông báo | Thông báo realtime cho các hoạt động |
| 🛡️ Admin | Dashboard quản lý users, listings, orders, support |

---

## 🏗️ Kiến trúc

```
MobileApp-ChoDoCu/
├── 📱 mobile_app/              # Flutter Android App
│   └── lib/
│       ├── features/           # Màn hình theo feature
│       │   ├── auth/           # Đăng nhập, đăng ký, OTP
│       │   ├── home/           # Trang chủ, tìm kiếm
│       │   ├── listing/        # Đăng tin, chi tiết sản phẩm
│       │   ├── orders/         # Đặt hàng, lịch sử mua/bán
│       │   ├── chat/           # Chat realtime
│       │   ├── wallet/         # Ví điện tử
│       │   ├── profile/        # Hồ sơ người dùng
│       │   ├── notification/   # Thông báo
│       │   ├── admin/          # Admin dashboard
│       │   └── support/        # Hỗ trợ, liên hệ
│       ├── models/             # Data models
│       ├── core/               # Theme, network, utils
│       └── routes/             # App routing
│
├── ⚙️ backend/                 # ASP.NET Core 8 API
│   ├── Controllers/            # API endpoints
│   ├── Models/                 # Entity models
│   ├── DTOs/                   # Data transfer objects
│   ├── Services/               # Business logic
│   ├── Hubs/                   # SignalR hubs
│   ├── Migrations/             # EF Core migrations
│   └── Program.cs
│
└── 🐳 docker-compose.yml       # SQL Server + Backend
```

---

## 🛠️ Công nghệ

### Mobile
- **Flutter 3.x** — UI framework
- **Provider** — State management
- **SignalR** — Realtime chat
- **Dio** — HTTP client

### Backend
- **ASP.NET Core 8** — Web API
- **Entity Framework Core** — ORM
- **SignalR** — Realtime hub
- **JWT** — Authentication
- **Cloudinary** — Lưu trữ ảnh/video

### Infrastructure
- **Azure SQL Edge** — Database (Docker)
- **Docker Compose** — Container orchestration
- **Nginx** — Reverse proxy + SSL
- **VPS Ubuntu 20.04** — Hosting

---

## 🚀 Chạy local

### Yêu cầu
- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)

### Backend + Database
```bash
# Khởi động SQL Server và Backend bằng Docker
docker-compose up -d

# Hoặc chạy backend trực tiếp (cần SQL Server riêng)
cd backend
dotnet run
```

### Flutter App
```bash
cd mobile_app
flutter pub get
flutter run
```

> API endpoint được cấu hình tại `mobile_app/lib/core/constants/app_constants.dart`

---

## 📱 Download APK

Tải APK bản mới nhất tại:

**[⬇️ Download app-release.apk](https://berlinmmo.site/download/app-release.apk)**

---

## 📂 Danh mục sản phẩm

`Thời trang nam` · `Thời trang nữ` · `Sách` · `Đồ chơi` · `Đồ thể thao` · `Đồ gia dụng` · `Điện thoại & máy tính` · `Xe cộ` · `Đồ điện gia dụng` · `Mỹ phẩm` · `Nhà cửa` · `Khác`

---

<div align="center">
Made with ❤️ by **Ngô Quang Huy**
</div>
