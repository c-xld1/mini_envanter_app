-- #############################################################################
-- #                                                                           #
-- #                      MINI ENVANTER VERITABANI KURULUMU                     #
-- #                                                                           #
-- #############################################################################

-- ##############################
-- # TABLOLARIN OLUŞTURULMASI
-- ##############################

-- Mağazaların tutulacağı tablo
CREATE TABLE IF NOT EXISTS public.stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    store_code TEXT UNIQUE, -- Mağaza kodu (opsiyonel ve benzersiz)
    created_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.stores IS 'Mağazaların bilgilerini tutar.';

-- Ürünlerin tutulacağı tablo
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    barcode TEXT UNIQUE NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE public.products IS 'Mağazalardaki ürünlerin bilgilerini tutar.';

-- Kullanıcı rollerini tanımlayan ENUM tipi
CREATE TYPE public.app_role AS ENUM ('admin', 'mudur', 'personel');

-- Kullanıcı profillerinin tutulacağı tablo (auth.users tablosuna ek bilgiler)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    role app_role NOT NULL,
    store_id UUID REFERENCES public.stores(id) ON DELETE SET NULL -- Mağaza silinirse personelin bağlantısı kopar
);
COMMENT ON TABLE public.profiles IS 'Kullanıcıların rol ve mağaza gibi ek bilgilerini tutar.';

-- Sayım oturumlarının tutulacağı tablo
CREATE TABLE IF NOT EXISTS public.inventory_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    start_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_time TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'in_progress' -- in_progress, completed
);
COMMENT ON TABLE public.inventory_counts IS 'Mağazalarda yapılan sayım oturumlarını yönetir.';

-- Sayılan ürünlerin tutulacağı tablo
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    count_id UUID NOT NULL REFERENCES public.inventory_counts(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL, -- Ürün silinirse sayım kaydı kalır
    barcode TEXT NOT NULL,
    counted_quantity INT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.inventory_items IS 'Bir sayım oturumunda sayılan bireysel ürünleri kaydeder.';


-- ##############################
-- # GÜVENLİK (ROW LEVEL SECURITY)
-- ##############################

-- RLS'i tüm tablolarda etkinleştir
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

-- Mevcut eski/genel politikaları temizle (varsa)
DROP POLICY IF EXISTS "Public read access" ON public.stores;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.stores;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.inventory_counts;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON public.inventory_items;
DROP POLICY IF EXISTS "Admin can see all inventory items" ON public.inventory_items;


-- ##############################
-- # YARDIMCI FONKSİYONLAR
-- ##############################

-- Mevcut kullanıcının rolünü getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS app_role
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT role::app_role FROM public.profiles WHERE id = auth.uid();
$$;

-- Mevcut kullanıcının mağaza ID'sini getiren fonksiyon
CREATE OR REPLACE FUNCTION public.get_my_store_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT store_id FROM public.profiles WHERE id = auth.uid();
$$;

-- ##############################
-- # PROFILES TABLOSU POLİTİKALARI
-- ##############################

-- Adminler tüm profilleri görebilir ve yönetebilir.
CREATE POLICY "Admin full access on profiles" ON public.profiles FOR ALL
    USING (public.get_my_role() = 'admin')
    WITH CHECK (public.get_my_role() = 'admin');

-- Müdürler kendi mağazalarındaki personelleri görebilir.
CREATE POLICY "Managers can see their staff" ON public.profiles FOR SELECT
    USING (store_id = public.get_my_store_id());

-- Herkes kendi profilini görebilir ve güncelleyebilir.
CREATE POLICY "Users can view and update their own profile" ON public.profiles FOR ALL
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());


-- ##############################
-- # STORES TABLOSU POLİTİKALARI
-- ##############################

-- Adminler tüm mağazaları yönetebilir.
CREATE POLICY "Admin full access on stores" ON public.stores FOR ALL
    USING (public.get_my_role() = 'admin')
    WITH CHECK (public.get_my_role() = 'admin');

-- Müdür ve personel, kendi mağaza bilgilerini görebilir.
CREATE POLICY "Staff and managers can see their own store" ON public.stores FOR SELECT
    USING (id = public.get_my_store_id());


-- ##############################
-- # PRODUCTS TABLOSU POLİTİKALARI
-- ##############################

-- Adminler tüm ürünleri yönetebilir.
CREATE POLICY "Admin full access on products" ON public.products FOR ALL
    USING (public.get_my_role() = 'admin')
    WITH CHECK (public.get_my_role() = 'admin');

-- Müdür ve personel, kendi mağazalarındaki ürünleri yönetebilir.
CREATE POLICY "Staff and managers can manage products in their store" ON public.products FOR ALL
    USING (store_id = public.get_my_store_id())
    WITH CHECK (store_id = public.get_my_store_id());


-- ##############################
-- # INVENTORY_COUNTS TABLOSU POLİTİKALARI
-- ##############################

-- Adminler tüm sayım oturumlarını yönetebilir.
CREATE POLICY "Admin full access on inventory counts" ON public.inventory_counts FOR ALL
    USING (public.get_my_role() = 'admin')
    WITH CHECK (public.get_my_role() = 'admin');

-- Müdür ve personel, kendi mağazalarındaki sayım oturumlarını yönetebilir.
CREATE POLICY "Staff and managers can manage counts in their store" ON public.inventory_counts FOR ALL
    USING (store_id = public.get_my_store_id())
    WITH CHECK (store_id = public.get_my_store_id());


-- ##############################
-- # INVENTORY_ITEMS TABLOSU POLİTİKALARI
-- ##############################

-- Adminler tüm sayım kalemlerini yönetebilir.
CREATE POLICY "Admin full access on inventory items" ON public.inventory_items FOR ALL
    USING (public.get_my_role() = 'admin')
    WITH CHECK (public.get_my_role() = 'admin');

-- Kullanıcılar, kendi mağazalarındaki sayımlara ait kalemleri görebilir.
CREATE POLICY "Users can see items from counts in their store" ON public.inventory_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.inventory_counts
            WHERE id = inventory_items.count_id AND store_id = public.get_my_store_id()
        )
    );

-- Kullanıcılar, devam eden ve kendi mağazalarındaki sayımlara ürün ekleyebilir.
CREATE POLICY "Users can insert items into active counts in their store" ON public.inventory_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.inventory_counts
            WHERE id = inventory_items.count_id
              AND status = 'in_progress'
              AND store_id = public.get_my_store_id()
        )
    );


-- ##############################
-- # BAŞLANGIÇ VERİLERİ VE TETİKLEYİCİLER
-- ##############################

-- profiles tablosuna yeni kullanıcı eklendiğinde çalışan tetikleyici fonksiyonu
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.email,
    'personel' -- Varsayılan rol
  );
  RETURN NEW;
END;
$$;

-- auth.users'a her yeni kayıt eklendiğinde handle_new_user fonksiyonunu çalıştır
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ##############################
-- # SÜPER ADMIN KULLANICISI
-- ##############################

-- Not: Bu blok çalışmadan önce, Supabase projenizin "Authentication"
-- bölümünde '000000' sicil numarasına karşılık gelen ('000000@magaza.app') 
-- bir kullanıcı oluşturduğunuzdan emin olun. Bu script, o kullanıcıya 'admin' rolünü atayacaktır.
DO $$
DECLARE
    admin_email TEXT := '000000@magaza.app';
    admin_user_id UUID;
BEGIN
    -- Önce auth.users tablosundan admin'in ID'sini al
    SELECT id INTO admin_user_id FROM auth.users WHERE email = admin_email;

    -- Eğer admin kullanıcısı auth.users'da bulunduysa, profiles tablosunu güncelle/ekle
    IF admin_user_id IS NOT NULL THEN
        INSERT INTO public.profiles (id, full_name, email, role)
        VALUES (admin_user_id, 'Süper Admin', admin_email, 'admin')
        ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            full_name = 'Süper Admin',
            email = admin_email;
        RAISE NOTICE 'Süper Admin profili başarıyla oluşturuldu veya güncellendi.';
    ELSE
        RAISE WARNING '''%s''' email adresine sahip kullanıcı bulunamadı. Lütfen önce bu sicil numarası ile bir kullanıcı oluşturun.', admin_email;
    END IF;
END $$;
