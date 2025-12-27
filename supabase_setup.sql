-- Temizlik (Dikkat: Verileri siler)
DROP TABLE IF EXISTS inventory_counts CASCADE;
DROP TABLE IF EXISTS daily_sales CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS stores CASCADE;

-- 1. Mağazalar Tablosu (GÜNCELLENDİ: city kalktı, store_code geldi)
CREATE TABLE stores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    store_code TEXT, -- Mağaza Kodu (Örn: 1751)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Kullanıcı Profilleri
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT,
    role TEXT CHECK (role IN ('admin', 'mudur', 'personel', 'bolge_sorumlusu')),
    store_id UUID REFERENCES stores(id),
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Ürünler Tablosu
CREATE TABLE products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES stores(id) NOT NULL,
    name TEXT NOT NULL,
    barcode TEXT,
    box_quantity INTEGER DEFAULT 1,
    initial_stock INTEGER DEFAULT 0,
    assigned_to TEXT, -- 'mudur' veya 'personel'
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Günlük Satışlar (Opsiyonel, kullanılmıyorsa kaldırılabilir)
CREATE TABLE daily_sales (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES stores(id) NOT NULL,
    product_id UUID REFERENCES products(id) NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    quantity INTEGER DEFAULT 0,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(store_id, product_id, date)
);

-- 5. Envanter Sayımları
CREATE TABLE inventory_counts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES stores(id) NOT NULL,
    product_id UUID REFERENCES products(id) NOT NULL,
    count_date DATE DEFAULT CURRENT_DATE,
    counted_quantity INTEGER NOT NULL,
    note TEXT,
    counted_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Güvenlik Politikaları (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Okuma İzinleri (Genel)
CREATE POLICY "Public read access" ON profiles FOR SELECT USING (true);
CREATE POLICY "Public read access" ON products FOR SELECT USING (true);
CREATE POLICY "Public read access" ON inventory_counts FOR SELECT USING (true);
CREATE POLICY "Public read access" ON daily_sales FOR SELECT USING (true);
CREATE POLICY "Public read access" ON stores FOR SELECT USING (true);

-- Yazma İzinleri (Sadece giriş yapmış kullanıcılar)
CREATE POLICY "Authenticated insert profiles" ON profiles FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated update profiles" ON profiles FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated insert stores" ON stores FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated delete stores" ON stores FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated insert products" ON products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated insert counts" ON inventory_counts FOR INSERT WITH CHECK (auth.role() = 'authenticated');DO $$
DECLARE
    -- Sicil No + Domain yapısı
    target_email TEXT := '123456@magaza.app'; 
    v_user_id UUID;
BEGIN
    -- 1. Kullanıcının ID'sini bul
    SELECT id INTO v_user_id FROM auth.users WHERE email = target_email;

    IF v_user_id IS NOT NULL THEN
        -- 2. Profiles tablosunu güncelle
        INSERT INTO public.profiles (id, email, role, full_name, store_id)
        VALUES (
            v_user_id, 
            target_email, 
            'admin', 
            'Sistem Yöneticisi',
            NULL
        )
        ON CONFLICT (id) DO UPDATE
        SET 
            role = 'admin',
            full_name = 'Sistem Yöneticisi';
            
        RAISE NOTICE 'Admin (123456) başarıyla yetkilendirildi.';
    ELSE
        RAISE NOTICE 'Kullanıcı bulunamadı! Lütfen panele gidip 123456@magaza.app kullanıcısını ekleyin.';
    END IF;
END $$;

-- 1. Önce örnek bir mağaza oluşturalım (Eğer yoksa)
WITH new_store AS (
  INSERT INTO stores (name) 
  VALUES ('Merkez Şube') 
  RETURNING id
)
-- 2. Ardından, mağazası olmayan 'mudur' veya 'personel' rollerindeki kullanıcılara bu mağazayı atayalım
UPDATE profiles
SET store_id = (SELECT id FROM new_store)
WHERE store_id IS NULL 
AND role IN ('mudur', 'personel');

-- Not: Eğer kullanıcıyı 'admin' olarak oluşturduysanız store_id'ye ihtiyacı yoktur, 
-- yukarıdaki Flutter kodu zaten admin için bu kontrolü atlayacaktır.

-- Mağazalar tablosuna 'store_code' sütununu ekler
ALTER TABLE stores ADD COLUMN IF NOT EXISTS store_code TEXT;