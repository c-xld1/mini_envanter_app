import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';
import 'login_screen.dart';

class StaffDashboard extends StatefulWidget {
  final AppUser user;
  const StaffDashboard({super.key, required this.user});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final InventoryService _service = InventoryService();
  
  // Tasarım Renkleri (HTML'den alındı)
  static const Color bgLight = Color(0xFFF6F6F8);
  static const Color bgDark = Color(0xFF101622);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF192233);
  static const Color primary = Color(0xFF135BEC);
  static const Color textSecondary = Color(0xFF92A4C9);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF324467);

  // İstatistik Verileri
  int _criticalStockCount = 0;
  int _completedTasks = 0;
  List<Product> _pendingTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final storeId = widget.user.storeId;
      if (storeId == null) return;

      // 1. Kritik Stokları Bul (Örnek: Stoğu 5'in altında olanlar)
      final lowStockRes = await Supabase.instance.client
          .from('products') // Burada inventory_counts ile join yapılabilir, şimdilik statik
          .select() // Basitlik için tüm ürünleri çekip local filtreliyoruz
          .eq('store_id', storeId);
      
      // Not: Gerçek senaryoda bu sorgu daha optimize olmalı
      final allProducts = (lowStockRes as List).map((e) => Product.fromJson(e)).toList();
      // Örnek filtre: Kritik stok < 5 varsayalım
      final criticals = allProducts.where((p) => p.initialStock < 5).toList();

      // 2. Bugünün Tamamlanan Görevleri (Sayımı Yapılanlar)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final completedRes = await Supabase.instance.client
          .from('inventory_counts')
          .select()
          .eq('store_id', storeId)
          .eq('count_date', today)
          .eq('counted_by', widget.user.id);
      
      final completedCount = (completedRes as List).length;

      // 3. Bekleyen Görevler (Sayılmamış Ürünler)
      // Basitleştirilmiş mantık: Toplam Ürün - Sayılanlar
      final countedProductIds = (completedRes).map((e) => e['product_id'] as String).toSet();
      final pending = allProducts.where((p) => !countedProductIds.contains(p.id)).take(5).toList();

      if (mounted) {
        setState(() {
          _criticalStockCount = criticals.length;
          _completedTasks = completedCount;
          _pendingTasks = pending;
        });
      }
    } catch (e) {
      debugPrint('Dashboard Veri Hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCountDialog(Product product) {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 32
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Barkod: ${product.barcode ?? "-"}', style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration(
                hintText: '0',
                labelText: 'Sayım Adedi',
                labelStyle: const TextStyle(color: textSecondary),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary)),
                filled: true,
                fillColor: bgDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Not (Opsiyonel)',
                labelStyle: const TextStyle(color: textSecondary),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary)),
                filled: true,
                fillColor: bgDark,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _service.addInventoryCount(
                    widget.user.storeId!,
                    product.id,
                    int.parse(controller.text),
                    noteController.text,
                  );
                  Navigator.pop(context);
                  _fetchDashboardData(); // Verileri yenile
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} kaydedildi.'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('KAYDET', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderDark.withOpacity(0.5), height: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: bgDark,
                child: Text(
                  widget.user.fullName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mağaza Personeli', style: TextStyle(fontSize: 12, color: textSecondary)),
                Text(widget.user.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: textSecondary, size: 28),
                Positioned(top: 2, right: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ],
            ),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: textSecondary)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Hoşgeldin Mesajı ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('İyi çalışmalar, ${widget.user.fullName.split(' ')[0]}', 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Bugünün envanter hedeflerine odaklanalım.', style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),

                  // --- Hero Card (Günlük Sayım) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderDark),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0, left: 0, right: 0, height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [primary.withOpacity(0.1), Colors.transparent],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('ÖNCELİKLİ', style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Günlük Sayım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const Text('Gıda Reyonu - Koridor 4', style: TextStyle(color: textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.inventory_2, color: primary, size: 32),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('İlerleme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                    Text('$_completedTasks / ${_completedTasks + _pendingTasks.length} Tamamlandı', style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (_completedTasks + _pendingTasks.length) > 0 
                                        ? _completedTasks / (_completedTasks + _pendingTasks.length) 
                                        : 0,
                                    backgroundColor: bgDark,
                                    color: primary,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // İlk bekleyen görevi aç
                                      if (_pendingTasks.isNotEmpty) {
                                        _showCountDialog(_pendingTasks.first);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm görevler tamamlandı!')));
                                      }
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Sayıma Devam Et'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Hızlı İstatistikler ---
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Kritik Stok',
                            value: '$_criticalStockCount',
                            subtitle: 'Acil kontrol gerekli',
                            icon: Icons.warning_amber_rounded,
                            iconColor: Colors.redAccent,
                            bgColor: Colors.redAccent.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tamamlanan',
                            value: '$_completedTasks',
                            subtitle: 'Bugünkü görevler',
                            icon: Icons.check_circle_outline,
                            iconColor: Colors.greenAccent,
                            bgColor: Colors.greenAccent.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Bekleyen Görevler Listesi ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bekleyen Görevler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        TextButton(onPressed: () {}, child: const Text('Tümünü Gör', style: TextStyle(color: primary))),
                      ],
                    ),
                  ),

                  if (_pendingTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Harika! Bekleyen görev yok.', style: TextStyle(color: textSecondary))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _pendingTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = _pendingTasks[index];
                        return GestureDetector(
                          onTap: () => _showCountDialog(product),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderDark),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: bgDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderDark),
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, color: textSecondary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      const Text('Son Güncelleme: --', style: TextStyle(color: textSecondary, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Bekliyor', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: bgDark,
          border: Border(top: BorderSide(color: borderDark)),
        ),
        child: BottomNavigationBar(
          backgroundColor: bgDark,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          currentIndex: 1, // Envanter (veya Ana Sayfa) seçili
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Envanter'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: ''), // FAB yeri
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Uyarılar'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Barkod tarayıcı açılabilir
        },
        backgroundColor: primary,
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}