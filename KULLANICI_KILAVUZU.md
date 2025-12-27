# 📱 Envanter Sayım Uygulaması - Kullanıcı Kılavuzu

## İçindekiler
1. [Başlangıç](#başlangıç)
2. [Ekran Rehberi](#ekran-rehberi)
3. [Ürün Yönetimi](#ürün-yönetimi)
4. [Envanter Sayımı](#envanter-sayımı)
5. [Sık Sorulan Sorular](#sık-sorulan-sorular)

---

## Başlangıç

### İlk Açılışta

1. Uygulamayı açtığınızda otomatik olarak Dashboard açılır
2. İnternet bağlantısı gereklidir
3. Supabase'den verileri yüklüyor ise biraz bekleyin

### Ana Menü

Uygulamanın altında 3 sekme vardır:
- 📊 **Dashboard** - İstatistikler
- 📦 **Ürünler** - Ürün listesi
- 🧮 **Sayım** - Envanter sayımı

---

## Ekran Rehberi

### 1. Dashboard (Ana Sayfa) 📊

#### Üst Bölüm - İstatistikler

```
┌─────────────────────────────────────┐
│ Toplam Ürün  │  Toplam Adet        │
│      5       │        250          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Toplam Değer (₺)                    │
│     5,432.50                        │
└─────────────────────────────────────┘
```

**Ne anlama gelir?**
- **Toplam Ürün**: Sisteme kayıtlı ürün sayısı
- **Toplam Adet**: Envanterinizdeki toplam parça sayısı
- **Toplam Değer**: Tüm envanterinin parasal değeri

#### Alt Bölüm - Son Eklenen Ürünler

Son 5 ürünün listesi gösterilir. Her ürün için:
- Ürün adı
- Mevcut miktarı
- Birim fiyatı

---

### 2. Ürünler Sekmesi 📦

#### Arama
Sayfanın üstündeki arama çubuğuna tıklayarak:
- Ürün adı ile ara (örn: "T-Shirt")
- Barkod numarası ile ara (örn: "8680000000001")

#### Ürün Listesi
Her ürün kartında:
```
┌──────────────────────────────────┐
│ Ürün Adı                         │
│ Barkod: XXX | Kategori: Giyim   │
│ Miktar: 50 adet    Fiyat: ₺49.99│
└──────────────────────────────────┘
```

#### İşlemler

**Ürünü Düzenlemek**
1. Ürün kartına tıklayın
2. Bilgileri değiştirin
3. "Güncelle" butonuna tıklayın

**Ürünü Silmek**
1. Düzenle sayfasında sağ üstteki 🗑️ ikonuna tıklayın
2. Onay vermek için "Sil" butonuna tıklayın
3. **Uyarı**: Silinen ürün geri alınamaz!

---

### 3. Sayım Sekmesi 🧮

#### Ürün Seçimi

1. Arama çubuğuna ürün adı yaz (örn: "Kahve")
2. Açılan listeden istediğini seç
3. Seçilen ürün altta görünür

#### Sayım Yapma

```
┌──────────────────────────────────┐
│ Ürün Adı: Kahve                  │
│ Mevcut Miktar: 100 adet          │
│                                  │
│ Yeni Miktar:                     │
│ [____________________________]    │
│                                  │
│ Fark: +50                        │
│                                  │
│ Değişiklik Sebebi (opsiyonel):   │
│ [____________________________]    │
│                                  │
│ [   SAYIMI KAYDET   ]            │
└──────────────────────────────────┘
```

**Adım Adım:**
1. **Yeni Miktar**: Sayım sırasında bulduğunuz toplam miktarı girin
2. **Fark**: Otomatik olarak hesaplanır (Yeni - Eski)
3. **Sebep**: Değişiklik sebebini yazın (opsiyonel):
   - Örn: "Fiziki sayım"
   - Örn: "Satış sonrası"
   - Örn: "Hasar"
4. **Kaydet**: "Sayımı Kaydet" butonuna tıklayın

**Başarı Mesajı Alınırsa**
- Sayım kaydedilmiştir ✅
- Ürün miktarı güncellendi
- Değişiklik loglanmıştır

---

## Ürün Yönetimi

### Yeni Ürün Ekleme

1. "Ürünler" sekmesine gidin
2. Sağ-alt köşedeki **[+]** butonuna tıklayın
3. Aşağıdaki bilgileri doldurun:

```
Ürün Adı *              : T-Shirt Mavi
Barkod                 : 8680000000001
Fiyat *                : 49.99
İlk Miktar *           : 50
Kategori               : Giyim
```

**Not**: * işareti olan alanlar zorunludur

### Ürün Kategorileri

Uygulama aşağıdaki kategorileri destekler:
- 👕 **Giyim** - Kıyafetler, ayakkabılar
- 💻 **Elektronik** - Cihazlar, aksesuarlar
- 🍔 **Gıda** - Yiyecekler, içecekler
- 🏠 **Ev Eşyası** - Mobilya, dekorasyon
- 💄 **Kişisel Bakım** - Kozmetik, hijyen ürünleri
- 📦 **Diğer** - Diğer ürünler

### Barkod Kullanımı

**Barkod Nedir?**
Ürünün üzerindeki çizgi kodudur. Örnek: 8680000000001

**Barkod Girmek**
- El ile yazabilirsiniz
- Barkod tarayıcı varsa sorun yok (ileri sürümde camera desteği eklenecek)

**Barkod Araması**
- Sayım sekmesinde barkod numarasını yazarak ürünü bulabilirsiniz

---

## Envanter Sayımı

### Sayım Nedir?

Deponuzdaki ürünleri tek tek sayarak, sistemde kayıtlı olan miktarla karşılaştırma işlemidir.

### Sayım Türleri

#### 1. İlk Sayım
Sistemi yeni kurduğunuzda, mağazadaki miktarları girin.

```
Sistem: 0 adet
Sayım: 50 adet
Fark: +50 adet
```

#### 2. Düzenli Sayım
Haftada bir veya ayda bir yapılan rutin sayım.

#### 3. Spot Sayım
Belirli bir ürünün sayımı (örn: Hasarlı ürün, imha)

### Sayım İpuçları

✅ **Yapılması Gerekenler:**
- Sayımı temiz bir ortamda yapın
- Aynı kişi (tercihen) yapmalı
- Sayımı tamamladıktan sonra sisteme girin
- Notu uygun şekilde doldur

❌ **Yapılmayacaklar:**
- Çabuk çabuk saymayın
- Sayımı kesintisiz yapın
- Benzer ürünleri karıştırmayın

### Sayım Raporları

Sistem tüm değişiklikleri kaydeder ve log tutulur. İleri versiyonda:
- 📊 Günlük/Aylık raporlar
- 📈 Grafik analizler
- 📥 Excel/PDF indirme

---

## Sık Sorulan Sorular

### S: Ürünü yanlışlıkla sildim. Geri alabilir miyim?
**C:** Maalesef hayır. Çok önemli ürünleri silmeden önce dikkat edin.

### S: Barkod zorunlu mu?
**C:** Hayır, barkod opsiyonel. Ama sıklıkla sayım yapacaksanız barkod eklemeniz önerilir.

### S: Sayım bilgilerini düzenleyebilir miyim?
**C:** Hayır, sayım kaydedildikten sonra değiştiremezsiniz. Yeni bir sayım yapabilirsiniz.

### S: İnternet bağlantısı kesilirse ne olur?
**C:** Şu an uygulamanın online çalışması gereklidir. Gelecek versiyonda offline desteği eklenecek.

### S: Kaç ürüne kadar destek var?
**C:** Teknik olarak sınırlama yok. Ancak 1000+ ürün için özel optimizasyon gerekebilir.

### S: Telefonu değiştirirsem verileri kaybedeceğim mi?
**C:** Hayır, veriler Supabase'de bulunduğu için değiştirmez. Yeni telefonda login yapabilirsiniz.

### S: Birden fazla kullanıcı aynı anda kullanabilir mi?
**C:** Mevcut versiyonda hayır. İleri versiyonda multi-user desteği eklenecek.

### S: Ürün fiyatlarını güncellemek istiyorum.
**C:** Ürüne tıklayarak düzenleme ekranında fiyatı değiştirebilirsiniz.

### S: Kategori ekleyebilir miyim?
**C:** Mevcut versiyonda önceden belirlenmiş kategoriler vardır. İleri sürümde özel kategori desteği eklenecek.

---

## 🎯 İyi Kullanım Alışkanlıkları

### Günlük
- ✅ Satılan ürünleri güncelleyin
- ✅ Yeni gelen ürünleri ekleyin

### Haftalık
- ✅ Hızlı bir sayım yapın
- ✅ Fiyat değişikliklerini yapın

### Aylık
- ✅ Detaylı envanter sayımı yapın
- ✅ Raporları inceleyin
- ✅ Eksik ürünleri belirleyin

---

## 📞 Destek ve Geri Bildirim

Sorun yaşıyorsanız veya öneri varsa:
1. KURULUM.md dosyasını kontrol edin
2. "No internet" hatasında bağlantıyı test edin
3. Uygulamayı kapatıp açmayı deneyin

---

**Son Güncelleme**: December 2024  
**Versiyon**: 1.0.0  
**Durum**: ✅ Tam Çalışır
