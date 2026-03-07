# 🥗 DailyDiet - Günlük Kalori Takip Uygulaması

DailyDiet, kullanıcıların günlük kalori alımlarını takip edebileceği, AI destekli chatbot ile diyet önerileri alabileceği ve kişiselleştirilmiş diyet planları oluşturabileceği modern bir mobil uygulamadır.

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknolojiler](#-teknolojiler)
- [Proje Yapısı](#-proje-yapısı)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [API Dokümantasyonu](#-api-dokümantasyonu)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Test](#-test)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)

## ✨ Özellikler

### 🔐 Kimlik Doğrulama ve Yetkilendirme
- Kullanıcı kaydı ve girişi
- JWT token tabanlı kimlik doğrulama
- Rol tabanlı yetkilendirme sistemi:
  - **User**: Kendi yemeklerini ve profilini yönetebilir
  - **Manager**: Kullanıcı profillerini düzenleyebilir ve manager rolü verebilir
  - **Admin**: Tüm kullanıcıların yemeklerini ve profillerini yönetebilir

### 🍽️ Yemek Takibi
- Yemek ekleme, düzenleme ve silme
- Tarih ve saat bazlı filtreleme
- Günlük kalori limiti ayarlama
- Görsel geri bildirim:
  - 🟢 **Yeşil**: Günlük kalori limiti aşılmamış
  - 🔴 **Kırmızı**: Günlük kalori limiti aşılmış

### 🤖 AI Destekli Özellikler
- **Chatbot**: Dify AI entegrasyonu ile diyet danışmanlığı
- **Diyet Planı Oluşturma**: Kullanıcı bilgilerine göre kişiselleştirilmiş diyet planları
- Yaş, boy, kilo, cinsiyet ve hedef bazlı planlama

### 👤 Profil Yönetimi
- Profil bilgilerini görüntüleme ve güncelleme
- Email ve şifre değiştirme
- Günlük kalori limiti ayarlama

## 🛠️ Teknolojiler

### Frontend (Mobil Uygulama)
- **Flutter** - Cross-platform mobil uygulama framework
- **Dart** - Programlama dili
- **Provider** - State management
- **HTTP** - API iletişimi
- **SharedPreferences** - Yerel veri saklama

### Backend (API)
- **.NET Core** - Web API framework
- **ASP.NET Core Identity** - Kimlik doğrulama ve yetkilendirme
- **Entity Framework Core** - ORM
- **PostgreSQL** - Veritabanı
- **JWT Bearer** - Token tabanlı kimlik doğrulama
- **OData** - RESTful API sorgulama
- **Dify AI** - AI chatbot entegrasyonu

### Diğer Araçlar
- **Postman** - API test koleksiyonu
- **Swagger/OpenAPI** - API dokümantasyonu

## 📁 Proje Yapısı

```
DailyDietAPP/
├── DailyDiet-main/              # Flutter mobil uygulama
│   ├── lib/
│   │   ├── main.dart           # Uygulama giriş noktası
│   │   ├── models/             # Veri modelleri
│   │   ├── screens/            # Ekranlar
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── food_diary_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── chatbot_screen.dart
│   │   │   └── diet_plan_screen.dart
│   │   ├── services/           # API servisleri
│   │   │   └── api_service.dart
│   │   └── widgets/            # Özel widget'lar
│   ├── android/                # Android platform dosyaları
│   ├── ios/                    # iOS platform dosyaları
│   └── pubspec.yaml            # Flutter bağımlılıkları
│
├── DailyDiet-server-dotNet/    # .NET Core API
│   └── src/
│       ├── DailyDietAPI/       # Ana API projesi
│       │   ├── Controllers/    # API controller'ları
│       │   ├── Features/       # Özellik bazlı controller'lar
│       │   ├── Services/       # İş mantığı servisleri
│       │   └── Startup.cs      # Uygulama yapılandırması
│       ├── DailyDietAPI.Model/ # Veri modelleri
│       ├── DailyDietAPI.Persistence/ # Veritabanı context
│       └── DailyDietAPI.Services/ # Servis katmanı
│
├── DailyDiet Test (Public).postman_collection.json  # Postman test koleksiyonu
├── wiki/                       # Ekran görüntüleri
└── README.md                   # Bu dosya
```

## 🚀 Kurulum

### Gereksinimler

- **Flutter SDK** (>=2.18.0)
- **.NET Core SDK** (6.0 veya üzeri)
- **PostgreSQL** (12 veya üzeri)
- **Visual Studio** veya **Visual Studio Code** (backend için)
- **Android Studio** veya **Xcode** (mobil geliştirme için)

### Backend Kurulumu

1. **Repository'yi klonlayın:**
```bash
git clone https://github.com/kullaniciadi/DailyDietAPP.git
cd DailyDietAPP
```

2. **PostgreSQL veritabanını oluşturun:**
```sql
CREATE DATABASE DailyDietDb;
```

3. **Backend dizinine gidin:**
```bash
cd DailyDiet-server-dotNet/src/DailyDietAPI
```

4. **appsettings.json dosyasını düzenleyin:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=DailyDietDb;Username=postgres;Password=your_password"
  },
  "Jwt": {
    "Key": "your-super-secret-key-with-at-least-32-characters",
    "Issuer": "your-issuer",
    "Audience": "your-audience",
    "ExpiryInMinutes": 60
  },
  "Dify": {
    "ApiKey": "your-dify-api-key",
    "ApiUrl": "https://api.dify.ai/v1"
  }
}
```

5. **NuGet paketlerini geri yükleyin:**
```bash
dotnet restore
```

6. **Veritabanı migration'larını çalıştırın:**
```bash
dotnet ef database update
```

7. **API'yi başlatın:**
```bash
dotnet run
```

API varsayılan olarak `http://localhost:5001` adresinde çalışacaktır.

### Frontend Kurulumu

1. **Flutter dizinine gidin:**
```bash
cd DailyDiet-main
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **API servis URL'sini güncelleyin:**
`lib/services/api_service.dart` dosyasında `_baseUrl` değişkenini backend API adresinize göre güncelleyin:
```dart
_baseUrl = 'http://YOUR_API_IP:5001/api';
```

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 📱 Kullanım

### İlk Kullanım

1. Uygulamayı açın
2. **Kayıt Ol** butonuna tıklayın
3. Email ve şifre ile hesap oluşturun
4. Giriş yapın

### Yemek Ekleme

1. Ana ekrandan **Yemek Günlüğü** sekmesine gidin
2. **+** butonuna tıklayın
3. Yemek bilgilerini girin:
   - Tarih ve saat
   - Yemek açıklaması
   - Kalori miktarı
4. **Kaydet** butonuna tıklayın

### Filtreleme

1. Yemek listesi ekranında filtreleme seçeneklerini kullanın
2. Tarih aralığı seçin
3. Saat aralığı seçin (örneğin: öğle yemeği için 12:00-15:00)

### Diyet Planı Oluşturma

1. **Diyet Planı** sekmesine gidin
2. Kişisel bilgilerinizi girin:
   - Yaş
   - Boy
   - Kilo
   - Cinsiyet
   - Hedef (kilo verme, kilo alma, kas kütlesi artırma vb.)
   - Diyet tipi
3. **Plan Oluştur** butonuna tıklayın
4. AI tarafından oluşturulan planı görüntüleyin

### Chatbot Kullanımı

1. **Chatbot** sekmesine gidin
2. Diyet ile ilgili sorularınızı yazın
3. AI'dan anında yanıt alın

## 📚 API Dokümantasyonu

### Authentication Endpoints

#### Kayıt Ol
```http
POST /api/authentication/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Giriş Yap
```http
POST /api/Authentication/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Yanıt:**
```json
{
  "token": "jwt_token_here",
  "userId": 1
}
```

### Meals Endpoints

#### Yemek Listesi
```http
GET /api/v1/meals
Authorization: Bearer {token}
```

#### Yemek Ekle
```http
POST /api/v1/meals
Authorization: Bearer {token}
Content-Type: application/json

{
  "date": "2024-01-15",
  "time": "12:30:00",
  "text": "Tavuk göğsü, pilav, salata",
  "calories": 450
}
```

#### Yemek Güncelle
```http
PUT /api/v1/meals/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "date": "2024-01-15",
  "time": "12:30:00",
  "text": "Tavuk göğsü, pilav, salata",
  "calories": 500
}
```

#### Yemek Sil
```http
DELETE /api/v1/meals/{id}
Authorization: Bearer {token}
```

### Chatbot Endpoints

#### Mesaj Gönder
```http
POST /api/chatbot/ask
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": "Günde kaç kalori almalıyım?"
}
```

### Diet Plan Endpoints

#### Diyet Planı Kaydet
```http
POST /api/dietplan
Authorization: Bearer {token}
Content-Type: application/json

{
  "userId": 1,
  "plan": "{...json plan data...}",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

#### Diyet Planı Getir
```http
GET /api/dietplan/{userId}
Authorization: Bearer {token}
```

### Swagger UI

API dokümantasyonuna Swagger UI üzerinden erişebilirsiniz:
```
http://localhost:5001/swagger
```

## 📸 Ekran Görüntüleri

<p align="center">
  <img width="320" src="wiki/Login.png" alt="Giriş Ekranı">
  <img width="320" src="wiki/Register.png" alt="Kayıt Ekranı">
</p>

<p align="center">
  <img width="640" src="wiki/Meals-List.png" alt="Yemek Listesi">
  <img width="320" src="wiki/Meals-Update.png" alt="Yemek Güncelleme">
</p>

<p align="center">
  <img width="640" src="wiki/Swagger-UI.png" alt="Swagger UI">
  <img width="640" src="wiki/Postman.png" alt="Postman Collection">
</p>

## 🧪 Test

### Postman Collection

Proje ile birlikte gelen Postman collection'ı kullanarak API'yi test edebilirsiniz:

1. Postman'i açın
2. `DailyDiet Test (Public).postman_collection.json` dosyasını import edin
3. Collection'daki istekleri çalıştırın

### Backend Testleri

```bash
cd DailyDiet-server-dotNet/tests/DailyDietAPI.IntegrationTest
dotnet test
```

### Flutter Testleri

```bash
cd DailyDiet-main
flutter test
```

## 🔒 Güvenlik

- Tüm API endpoint'leri JWT token ile korunmaktadır
- Şifreler hash'lenerek saklanır
- Role-based access control (RBAC) uygulanmıştır
- CORS yapılandırması mevcuttur

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 📝 Lisans

Bu proje örnek bir proje olarak geliştirilmiştir. Lisans bilgisi için lütfen repository sahibi ile iletişime geçin.

## 👥 Yazar

- **Geliştirici** - [GitHub Profili]([https://github.com/kullaniciadi](https://github.com/MuratElberKayaa?tab=repositories))

## 🙏 Teşekkürler

- Flutter ekibine harika framework için
- .NET ekibine güçlü backend framework için
- Dify AI ekibine AI entegrasyonu için

## 📞 İletişim

[Linkedin Profili](https://www.linkedin.com/in/murat-elber-kaya-18b6311b3/)

[Portfolyo](http://muratelberkaya.com.tr/)

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

