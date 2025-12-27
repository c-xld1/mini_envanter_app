class AppUser {
  final String id;
  final String email;
  final String role; // 'admin', 'mudur', 'personel', 'bolge_sorumlusu'
  final String? storeId;
  final String fullName;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.storeId,
    required this.fullName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'personel',
      storeId: json['store_id'],
      fullName: json['full_name'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String storeId;
  final String name;
  final String? barcode;
  final int boxQuantity; // Koli içi adet
  final int initialStock;

  Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.barcode,
    required this.boxQuantity,
    required this.initialStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['store_id'],
      name: json['name'],
      barcode: json['barcode'],
      boxQuantity: json['box_quantity'] ?? 1,
      initialStock: json['initial_stock'] ?? 0,
    );
  }
}

// GÜNCELLENEN STORE MODELİ
class Store {
  final String id;
  final String name;
  final String? storeCode; // City kaldırıldı, StoreCode eklendi

  Store({
    required this.id,
    required this.name,
    this.storeCode,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      storeCode: json['store_code'], // DB sütun adı: store_code
    );
  }
}

class InventoryReportItem {
  final Product product;
  final int? yesterdayStock; // Önceki günün sayımı veya başlangıç stoğu
  final int todaySales;      // Bugün girilen satış
  final int? todayCount;     // Bugün girilen sayım
  final String status;       // 'missing', 'excess', 'suspicious', 'normal', 'pending'

  InventoryReportItem({
    required this.product,
    this.yesterdayStock,
    this.todaySales = 0,
    this.todayCount,
    this.status = 'pending',
  });
  
  // Beklenen stok = Dünkü Stok - Bugünkü Satış
  int get expectedStock => (yesterdayStock ?? product.initialStock) - todaySales;
  
  // Fark = Sayılan - Beklenen
  int get diff => (todayCount ?? 0) - expectedStock;
}