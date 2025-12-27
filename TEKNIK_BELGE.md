# Envanter Sayım Uygulaması - Proje Özeti

## 📱 Uygulamaya Genel Bakış

Flutter ve Supabase ile geliştirilmiş **mağaza ürünlerinin envanterini yönetmek** için profesyonel bir mobil uygulama.

### Ana Özellikler

| Özellik | Açıklama |
|---------|----------|
| 📦 **Ürün Yönetimi** | Ürün ekleme, düzenleme, silme |
| 🏷️ **Barkod Desteği** | Barkod ile ürün tanımlama |
| 📊 **Dashboard** | Toplam ürün, miktar ve değer istatistikleri |
| 📈 **Envanter Sayımı** | Manuel sayım ve değişim kaydı |
| 🔍 **Arama ve Filtreleme** | Ürün adı veya barkod ile arama |
| 📂 **Kategorize Etme** | Ürünleri kategorilere ayırma |
| 📝 **Değişim Kaydı** | Her sayım değişikliğinin loglanması |

## 📂 Proje Yapısı

```
sayım_app/
│
├── lib/
│   ├── config/
│   │   └── supabase_config.dart      # Supabase bağlantı ayarları
│   │
│   ├── models/
│   │   └── models.dart               # Product ve InventoryLog modelleri
│   │
│   ├── services/
│   │   └── product_service.dart      # İş mantığı (CRUD + Sayım)
│   │
│   ├── screens/
│   │   ├── home_screen.dart          # Ana ekran (Dashboard + Tabs)
│   │   └── product_screen.dart       # Ürün ekleme/düzenleme
│   │
│   └── main.dart                     # Uygulama giriş noktası
│
├── pubspec.yaml                      # Bağımlılıklar ve konfigürasyon
├── supabase_setup.sql               # Supabase veritabanı SQL
├── README.md                         # Proje açıklaması
├── KURULUM.md                        # Kurulum adım-adım kılavuzu
└── .env.example                      # Ortam değişkenleri şablonu
```

## 🛠️ Kullanılan Teknolojiler

### Frontend
- **Flutter** 3.0+ - Cross-platform UI framework
- **Provider** 6.0+ - State management
- **Material 3** - Modern tasarım dili

### Backend
- **Supabase** - Firebase alternatifi (PostgreSQL + Real-time)
- **PostgreSQL** - Veritabanı

### Ek Kütüphaneler
- **go_router** - Navigasyon
- **uuid** - Unique ID üretimi
- **intl** - Uluslararası destek

## 📊 Veritabanı Şeması

### Products Tablosu
```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  barcode TEXT UNIQUE,
  price DECIMAL(10, 2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  category TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Inventory Logs Tablosu
```sql
CREATE TABLE inventory_logs (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL (FK),
  old_quantity INTEGER NOT NULL,
  new_quantity INTEGER NOT NULL,
  reason TEXT,
  created_at TIMESTAMP
);
```

## 🎯 Ekranlar ve Özellikler

### 1️⃣ Dashboard (Ana Sayfa)
- **İstatistik Kartları**
  - Toplam ürün sayısı
  - Toplam envanter miktarı
  - Toplam envanter değeri (₺)
- **Son Eklenen Ürünler** listesi (5 ürün)

### 2️⃣ Ürünler Sekmesi
- Tüm ürünlerin listesi
- Arama fonksiyonu (ad/barkod)
- Ürüne tıklayarak düzenleme
- Sağ-alt butondan yeni ürün ekleme

### 3️⃣ Sayım Sekmesi
- Ürün seçimi (arama ile)
- Mevcut miktar gösterimi
- Yeni miktar girişi
- Değişiklik sebebi notu
- Fark hesaplaması otomatik
- Sayım kaydı ve log oluşturma

## 🚀 Hızlı Başlangıç

### 1. Supabase Projesi Oluşturun
- supabase.com'a gidin
- Yeni proje oluşturun
- URL ve Anon Key kopyalayın

### 2. Veritabanını Oluşturun
```bash
# supabase_setup.sql dosyasındaki kodu çalıştırın
```

### 3. Konfigürasyonu Yapın
```dart
// lib/config/supabase_config.dart
static const String supabaseUrl = 'YOUR_URL';
static const String supabaseAnonKey = 'YOUR_KEY';
```

### 4. Çalıştırın
```bash
flutter pub get
flutter run
```

## 📱 Platform Desteği

- ✅ **Android** 5.0+ (API Level 21+)
- ✅ **iOS** 11.0+
- ✅ **Web** (isteğe bağlı)

## 🔐 Güvenlik Notları

### Yapılması Gerekenler
- [ ] Supabase'de Row Level Security (RLS) etkinleştirin
- [ ] Authentication sistemi ekleyin
- [ ] API Key'leri güvenli saklayın
- [ ] HTTPS kullanın

### .gitignore
```
.env
lib/config/supabase_config.dart  # Özel konfigürasyonlar
```

## 🤝 Genişletme Önerileri

### Yakın Vadede
1. **Kullanıcı Authentication**
   - Login/Register ekranları
   - RLS politikaları

2. **Raporlama**
   - CSV/PDF export
   - Günlük/aylık rapor

3. **Bildirimler**
   - Düşük stok uyarıları
   - Sayım tamamlanma bildirimi

### Uzun Vadede
1. **Çevrimdışı Desteği**
   - Hive veya SQLite yerel depolama
   - Senkronizasyon

2. **Barkod Scanner**
   - Camera entegrasyonu
   - Batch scanning

3. **Multi-user Support**
   - Rol bazlı erişim kontrol (RBAC)
   - Değişiklik geçmişi

4. **Analytics**
   - Satış analitiği
   - Kategori performansı

## 📞 Sorun Giderme

### Sık Yapılan Hatalar

**Hata**: "Connection timed out"
```dart
// Çözüm: Supabase URL'ini kontrol edin ve internet bağlantısını yenileyin
```

**Hata**: "Authentication failed"
```dart
// Çözüm: Anon Key'in geçerli olduğunu kontrol edin
```

**Hata**: "Table not found"
```sql
-- Çözüm: supabase_setup.sql dosyasını çalıştırın
```

## 📚 Referanslar

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Provider Pattern](https://pub.dev/packages/provider)
- [Material Design 3](https://m3.material.io/)

## 📄 Lisans

MIT License

## 👨‍💻 Geliştirici

Envanter Sayım Uygulaması - Flutter ile geliştirilmiştir.

---

**Sürüm**: 1.0.0  
**Son Güncelleme**: December 2024  
**Durumu**: ✅ Production Ready
