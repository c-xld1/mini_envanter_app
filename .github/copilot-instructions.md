# Copilot Instructions for Envanter Sayım (Inventory Management) App

## Project Overview

**Envanter Sayım** is a Flutter mobile app for retail store inventory management, built with Supabase backend. It supports multi-store operations with role-based access (admin, manager, staff, regional manager).

**Key Tech Stack:**
- Flutter 3.0+, Dart 3.0+
- Supabase (PostgreSQL + Auth)
- Provider pattern for state management
- flutter_dotenv for environment config
- Mobile Scanner for barcode support
- Local Auth + Flutter Secure Storage for authentication

---

## Architecture & Data Flow

### Service Layer (Single Responsibility)
Three main services in `lib/services/`:
- **AuthService** (`auth_service.dart`): User auth state, role management, loaded from Supabase `profiles` table
- **ProductService** (`product_service.dart`): CRUD operations on products, extends ChangeNotifier for reactive updates
- **InventoryService** (`inventory_service.dart`): Inventory counting, daily sales logging, report generation (inventory counts vs daily_sales tables)

Each service is a ChangeNotifier; screens consume them via Provider pattern.

### Data Models (lib/models/models.dart)
- **AppUser**: id, email, role (admin/mudur/personel/bolge_sorumlusu), storeId, fullName
- **Product**: id, storeId, name, barcode, boxQuantity (box item count), initialStock
- **Store**: id, name, storeCode
- **InventoryReportItem**: product data with counted_quantity, status tracking (pending/missing/excess/suspicious/normal)

**Key convention:** Models have `.fromJson()` factory and `.toMap()` for Supabase sync.

### Database Schema (supabase_setup.sql)
Critical tables:
- `profiles` (user role/store assignment)
- `products` (store inventory)
- `stores` (multi-store support)
- `inventory_counts` (manual count records with date tracking)
- `daily_sales` (sales/deductions logged by staff)
- `inventory_logs` (change history)

**Important:** All tables include `store_id` for multi-store isolation. Count date is ISO string (`YYYY-MM-DD`), used for daily reports.

---

## UI Architecture & Screen Patterns

### Screen Hierarchy (lib/screens/)
- **SplashScreen**: Initial load, auth check
- **LoginScreen**: Role-based login, token storage
- **Admin/Manager/StaffDashboard**: Role-specific views (role checked in AuthService.user.role)
- Dynamic screens swapped based on `AppUser.role`

### Theme & Styling (lib/main.dart, theme_notifier.dart)
Dark theme enforced (brightness: Brightness.dark). Primary: blueAccent, Secondary: amber. Reusable ElevatedButton styling with borderRadius:12.

### State Management Pattern
```dart
// Services as ChangeNotifiers in main.dart Provider setup
ChangeNotifierProvider(create: (_) => ProductService()),
ChangeNotifierProvider(create: (_) => AuthService()),

// In screens:
final products = context.watch<ProductService>().products;
await context.read<ProductService>().fetchProducts(storeId);
```

---

## Critical Workflows

### 1. App Initialization
1. `main()` → `WidgetsFlutterBinding.ensureInitialized()`
2. Load `.env` via `flutter_dotenv`
3. `Supabase.initialize()` with URL/anonKey from env
4. Set up Provider(s), launch SplashScreen
5. SplashScreen calls `AuthService.loadUser()` to fetch Supabase auth + profile

### 2. Product Sync Pattern
```dart
// Services use SupabaseConfig.client singleton
ProductService.fetchProducts(storeId) // SELECT all products for store
  → filter by store_id
  → map response to Product models
  → notifyListeners() → UI rebuilds
```

### 3. Inventory Counting Flow
1. Staff counts items → calls `InventoryService.addInventoryCount(storeId, productId, quantity, note)`
2. Recorded in `inventory_counts` table with date, user ID, product ID
3. Daily report compares counted vs. expected (last count) using dates
4. Status field auto-calculated: missing (count < expected), excess, suspicious (> box qty), normal

### 4. Multi-Store Context
Every query filters by `storeId`. User's assigned store from `AppUser.storeId`. Never query globally.

---

## Project-Specific Conventions

### Naming & File Organization
- **Services**: Extend ChangeNotifier, named `*Service` (AuthService, ProductService)
- **Models**: Single file `models.dart` with all data classes
- **Screens**: PascalCase, e.g. `AdminDashboard`, `StaffDashboard`
- **Strings**: Use Turkish labels in UI (e.g., "Envanter Sayımı", "Ürün Adı")

### Error Handling
Services store `_error` field (String?), expose via getter. Catch Supabase exceptions and assign to `_error`, notify listeners. UI displays via snackbars or error messages.

### Environment Config
- `.env` file (not in git) with `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Loaded in `main()` before Supabase init
- Config accessed via `SupabaseConfig.client` static getter

### Localization
Setup: `l10n.yaml` → `lib/l10n/app_en.arb` (English template)
- Turkish labels in code (not yet extracted to ARB)
- Future: Use `AppLocalizations.of(context)?.label` for i18n

---

## Integration Points & Common Pitfalls

### Supabase Integration
- Always check `Supabase.instance.client.auth.currentUser` for logged-in user
- Use `.eq('store_id', storeId)` to isolate multi-store data
- Dates in `YYYY-MM-DD` format for date filtering (see `getDailyReport`)
- Avoid raw SQL; use Supabase PostgREST API

### Role-Based Access
Check `AuthService.user?.role` in services before returning data. Admin/Mudur see all stores; Personel see only assigned store.

### CSV Export (assets/ürün_listesi.csv)
Currently static asset. Future: Generate dynamically from products table via `csv` package in `pubspec.yaml`.

### Barcode Scanning
`mobile_scanner` package integrated. Scan event → search product by barcode → populate Product field.

---

## Build & Run

```bash
# Setup
flutter pub get
cp .env.example .env  # Add SUPABASE_URL, SUPABASE_ANON_KEY

# Run
flutter run

# Build release (Android/iOS)
flutter build apk  # or: ios
```

**Note:** Requires Flutter SDK 3.0+, Dart 3.0+. Supabase project + credentials required.

---

## Key Files for Reference

| File | Purpose |
|------|---------|
| [lib/main.dart](lib/main.dart) | App entry, Provider setup, theme |
| [lib/services/auth_service.dart](lib/services/auth_service.dart) | User state, role loading |
| [lib/services/product_service.dart](lib/services/product_service.dart) | CRUD, Supabase sync |
| [lib/services/inventory_service.dart](lib/services/inventory_service.dart) | Counting, daily reports |
| [lib/models/models.dart](lib/models/models.dart) | Data schemas |
| [lib/config/supabase_config.dart](lib/config/supabase_config.dart) | Supabase client singleton |
| [supabase_setup.sql](supabase_setup.sql) | Database schema |

---

## Common Tasks

**Add a new product field:**
1. Update `Product` model & `.fromJson()`/`.toMap()` in `models.dart`
2. Add column to Supabase `products` table
3. Update `ProductService.addProduct()` & `fetchProducts()`
4. Add UI field to product screens

**Add a new screen for a role:**
1. Create screen file (e.g., `supervisor_dashboard.dart`)
2. Check user role in `SplashScreen` → route to new screen
3. In new screen, use `context.read<ProductService>()` to fetch role-specific data

**Debug Supabase queries:**
- Logs show in console. Enable debug in SupabaseConfig if needed.
- Test queries directly in Supabase SQL Editor before implementing in service.
