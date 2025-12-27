import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class ProductService extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      _products = (response as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> addProduct({
    required String storeId,
    required String name,
    String? barcode,
    required int boxQuantity,
    required int initialStock,
  }) async {
    try {
      const uuid = Uuid();
      final id = uuid.v4();

      final product = Product(
        id: id,
        storeId: storeId,
        name: name,
        barcode: barcode,
        boxQuantity: boxQuantity,
        initialStock: initialStock,
      );

      await SupabaseConfig.client
          .from('products')
          .insert(product.toMap());

      _products.insert(0, product);
      notifyListeners();
      return product;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required String storeId,
    required String name,
    String? barcode,
    required int boxQuantity,
    required int initialStock,
  }) async {
    try {
      final updatedProduct = Product(
        id: id,
        storeId: storeId,
        name: name,
        barcode: barcode,
        boxQuantity: boxQuantity,
        initialStock: initialStock,
      );

      await SupabaseConfig.client
          .from('products')
          .update(updatedProduct.toMap())
          .eq('id', id);

      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await SupabaseConfig.client
          .from('products')
          .delete()
          .eq('id', id);

      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return _products;

    return _products
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.barcode?.contains(query) ?? false))
        .toList();
  }
}
