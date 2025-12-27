import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class InventoryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> getProducts(String storeId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('store_id', storeId);
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<void> addDailySales(String storeId, String productId, int quantity) async {
    final user = _client.auth.currentUser;
    await _client.from('daily_sales').insert({
      'store_id': storeId,
      'product_id': productId,
      'sales_quantity': quantity,
      'sale_date': DateTime.now().toIso8601String().split('T')[0],
      'recorded_by': user!.id,
    });
  }

  Future<void> addInventoryCount(String storeId, String productId, int quantity, String? note) async {
    final user = _client.auth.currentUser;
    await _client.from('inventory_counts').insert({
      'store_id': storeId,
      'product_id': productId,
      'counted_quantity': quantity,
      'count_date': DateTime.now().toIso8601String().split('T')[0],
      'note': note,
      'counted_by': user!.id
    });
  }

  Future<List<InventoryReportItem>> getDailyReport(String storeId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final products = await getProducts(storeId);
    
    List<InventoryReportItem> report = [];

    for (var product in products) {
      final countRes = await _client
          .from('inventory_counts')
          .select('counted_quantity')
          .eq('product_id', product.id)
          .eq('count_date', today)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final count = countRes != null ? countRes['counted_quantity'] as int : null;

      final lastStockRes = await _client
          .from('inventory_counts')
          .select('counted_quantity')
          .eq('product_id', product.id)
          .lt('count_date', today)
          .order('count_date', ascending: false)
          .limit(1)
          .maybeSingle();
          
      final lastStock = lastStockRes != null ? lastStockRes['counted_quantity'] as int : product.initialStock;

      String status = 'pending';
      if (count != null) {
        int expected = lastStock;
        if (count < expected) {
          status = 'missing';
        } else if (count > (expected + product.boxQuantity)) {
          status = 'suspicious';
        } else if (count > expected) {
          status = 'excess';
        } else {
          status = 'normal';
        }
      }

      report.add(InventoryReportItem(
        product: product,
        yesterdayStock: lastStock,
        todayCount: count,
        status: status,
      ));
    }
    return report;
  }
}