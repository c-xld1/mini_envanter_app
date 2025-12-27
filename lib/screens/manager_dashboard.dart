import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';

class ManagerDashboard extends StatefulWidget {
  final AppUser user;
  const ManagerDashboard({super.key, required this.user});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final InventoryService _service = InventoryService();
  late Future<List<InventoryReportItem>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _refreshReport();
  }

  void _refreshReport() {
    setState(() {
      _reportFuture = _service.getDailyReport(widget.user.storeId!);
    });
  }

  // Renk Mantığı
  Color _getStatusColor(String status) {
    switch (status) {
      case 'missing': return Colors.red.shade900; // Hırsızlık/Eksik
      case 'suspicious': return Colors.redAccent; // Şüpheli Fazlalık
      case 'excess': return Colors.orange.shade900; // Koli içi fazla
      case 'normal': return Colors.green.shade800; // Normal
      default: return Colors.grey.shade800; // Sayılmadı
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'missing': return 'EKSİK / FİRE';
      case 'suspicious': return 'AŞIRI FAZLA';
      case 'excess': return 'FAZLA';
      case 'normal': return 'TAM';
      default: return 'SAYIM BEKLENİYOR';
    }
  }

  // Satış Giriş Dialog'u
  void _showSalesDialog(InventoryReportItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.product.name} Satışı Gir'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Adet', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _service.addDailySales(
                  widget.user.storeId!, 
                  item.product.id, 
                  int.parse(controller.text)
                );
                Navigator.pop(context);
                _refreshReport();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müdür Paneli: ${widget.user.fullName}'),
        actions: [
          IconButton(onPressed: _refreshReport, icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<List<InventoryReportItem>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: _getStatusColor(item.status), // Arka plan rengi duruma göre
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(item.status),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn('Dünkü', item.yesterdayStock.toString()),
                          _buildInfoColumn('Satış', item.todaySales.toString()),
                          _buildInfoColumn('Beklenen', item.expectedStock.toString()),
                          _buildInfoColumn('Sayılan', item.todayCount?.toString() ?? '-'),
                          _buildInfoColumn('Fark', item.diff.toString(), isBold: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (item.status == 'pending' || item.todaySales == 0)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Satış Gir / Düzenle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            onPressed: () => _showSalesDialog(item),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Ürün Ekleme Sayfasına Git
        },
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: Colors.white
          ),
        ),
      ],
    );
  }
}
