# Envanter Sayım Uygulaması

Flutter ve Supabase ile geliştirilmiş, mağaza ürünlerinin envanterini yönetmek için tasarlanmış bir mobil uygulama.

## Özellikler

- ✅ Ürün ekleme, düzenleme ve silme
- ✅ Ürün kategorize etme
- ✅ Ürün sayımı (manuel envanter)
- ✅ Barkod desteği
- ✅ Envanter değişim kaydı
- ✅ Dashboard (istatistikler)
- ✅ Ürün arama ve filtreleme
- ✅ Offline desteği (Provider pattern)

## Kurulum

### 1. Supabase Projesi Oluşturun

1. [supabase.com](https://supabase.com) adresine gidin
2. Yeni bir proje oluşturun
3. Proje URL ve Anon Key'i kopyalayın

### 2. Veritabanını Yapılandırın

Supabase SQL Editor'da aşağıdaki SQL kodunu çalıştırın:

```sql
-- Ürünler tablosu
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  barcode TEXT,
  price DECIMAL(10, 2) NOT NULL,
  quantity INTEGER NOT NULL,
  category TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Envanter değişim kaydı tablosu
CREATE TABLE inventory_logs (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  old_quantity INTEGER NOT NULL,
  new_quantity INTEGER NOT NULL,
  reason TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- İndeksler
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_inventory_logs_product_id ON inventory_logs(product_id);
```

### 3. Konfigürasyonu Güncelleyin

`lib/config/supabase_config.dart` dosyasını açın ve aşağıdaki değerleri değiştirin:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 5. Uygulamayı Çalıştırın

```bash
flutter run
```

## Proje Yapısı

```
lib/
├── main.dart              # Ana giriş noktası
├── config/
│   └── supabase_config.dart    # Supabase konfigürasyonu
├── models/
│   └── models.dart        # Veri modelleri
├── services/
│   └── product_service.dart    # İş mantığı ve API çağrıları
└── screens/
    ├── home_screen.dart   # Ana ekran ve sekmeler
    └── product_screen.dart # Ürün ekleme/düzenleme
```

## Ekranlar

### 1. Dashboard (Ana Sayfa)
- Toplam ürün sayısı
- Toplam envanter miktarı
- Toplam envanter değeri
- Son eklenen ürünler

### 2. Ürünler Sekmesi
- Tüm ürünlerin listesi
- Arama ve filtreleme
- Ürün düzenleme
- Ürün silme

### 3. Sayım Sekmesi
- Manuel sayım yapma
- Sayım sebeplerini kaydetme
- Envanter farkını görüntüleme
- Değişim geçmişi (logs)

## Teknolojiler

- **Flutter**: UI Framework
- **Supabase**: Backend Database
- **Provider**: State Management
- **UUID**: Unique ID Generation

## Lisans

MIT License

## Destek

Sorularınız veya sorunlarınız için GitHub Issues'u kullanın.
