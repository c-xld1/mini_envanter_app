@echo off
REM Envanter Sayım Uygulaması - Windows Setup Script

setlocal enabledelayedexpansion

cls
echo ================================
echo Envanter Sayim Uygulamasi Setup
echo ================================
echo.

REM Step 1: Flutter pub get
echo [1/3] Bagimliliklar yukleniyor...
call flutter pub get
if !errorlevel! equ 0 (
    echo [OK] Bagimliliklar basarıyla yuklendi
) else (
    echo [HATA] Bagimlilik yukleme basarisiz
    pause
    exit /b 1
)

echo.

REM Step 2: Analiz
echo [2/3] Kod analizi yapiliyor...
call flutter analyze
if !errorlevel! equ 0 (
    echo [OK] Kod analizi basarili
) else (
    echo [UYARI] Bazı uyarılar var (devam ediyoruz)
)

echo.

REM Step 3: Başarı mesajı
cls
echo ================================
echo Hepsi tamam!
echo ================================
echo.
echo Sonraki Adimlar:
echo.
echo 1. Supabase projesi olusturun:
echo    https://supabase.com
echo.
echo 2. Supabase bilgilerini girin:
echo    lib\config\supabase_config.dart
echo.
echo 3. Veritabanini olusturun:
echo    supabase_setup.sql dosyasini Supabase'de calistirin
echo.
echo 4. Uygulamayı başlatin:
echo    flutter run
echo.
echo Detaylar icin: KURULUM.md dosyasini okuyun
echo.
pause
