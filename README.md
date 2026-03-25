# Chợ Đồ Cũ - Mobile App

Ứng dụng mua bán đồ cũ trực tuyến, xây dựng bằng Flutter (mobile) và ASP.NET Core 8 (backend).

## Công nghệ sử dụng

- **Mobile**: Flutter 3.x (Android)
- **Backend**: ASP.NET Core 8 Web API
- **Database**: SQL Server (Azure SQL Edge)
- **Realtime**: SignalR (chat)
- **Storage**: Cloudinary (ảnh/video)
- **Deploy**: Docker + Nginx trên VPS Ubuntu

## Tính năng chính

- Đăng ký / đăng nhập (JWT + OTP email)
- Đăng tin bán đồ cũ (ảnh, video, địa chỉ, danh mục)
- Tìm kiếm, lọc theo danh mục, vị trí
- Chat realtime giữa người mua và người bán
- Đặt hàng, thanh toán qua ví
- Đánh giá người bán
- Thông báo realtime
- Admin dashboard (quản lý users, listings, orders, support)

## Cấu trúc dự án

```
├── backend/          # ASP.NET Core 8 API
│   ├── Controllers/
│   ├── Models/
│   ├── DTOs/
│   ├── Services/
│   └── Migrations/
├── mobile_app/       # Flutter app
│   └── lib/
│       ├── features/ # Các màn hình theo feature
│       ├── models/
│       ├── core/
│       └── routes/
└── docker-compose.yml
```

## Chạy local

### Backend
```bash
cd backend
dotnet run
```

### Flutter
```bash
cd mobile_app
flutter pub get
flutter run
```

## API

Backend chạy tại: `https://berlinmmo.site/api`
