#!/bin/bash

# Envanter Sayım Uygulaması - Proje Yapısı Oluşturucu
# Bu script projeyi hızlıca ayarlamaya yardımcı olur

echo "================================"
echo "Envanter Sayım Uygulaması Setup"
echo "================================"
echo ""

# Step 1: Flutter pub get
echo "📦 Adım 1: Bağımlılıklar yükleniyor..."
flutter pub get
if [ $? -eq 0 ]; then
    echo "✅ Bağımlılıklar başarıyla yüklendi"
else
    echo "❌ Bağımlılık yükleme başarısız"
    exit 1
fi

echo ""

# Step 2: Analiz
echo "🔍 Adım 2: Kod analizi yapılıyor..."
flutter analyze
if [ $? -eq 0 ]; then
    echo "✅ Kod analizi başarılı"
else
    echo "⚠️  Bazı uyarılar var (devam ediyoruz)"
fi

echo ""

# Step 3: Bilgi mesajı
echo "================================"
echo "✨ Setup Tamamlandı!"
echo "================================"
echo ""
echo "Sonraki Adımlar:"
echo "1. Supabase projesini oluşturun: https://supabase.com"
echo "2. lib/config/supabase_config.dart dosyasını düzenleyin"
echo "3. supabase_setup.sql dosyasındaki SQL kodu çalıştırın"
echo "4. flutter run komutu ile uygulamayı başlatın"
echo ""
echo "Detaylı kurulum için: KURULUM.md dosyasını okuyun"
echo ""
