import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:csv/csv.dart'; // Admin panelinde CSV kullanılmıyorsa kaldırılabilir
import '../models/models.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Tasarım Renkleri (HTML'den alındı)
  static const Color bgDark = Color(0xFF101622);
  static const Color cardDark = Color(0xFF192233);
  static const Color primary = Color(0xFF135BEC);
  static const Color textSecondary = Color(0xFF92A4C9);
  static const Color borderDark = Color(0xFF324467);

  final _storeNameController = TextEditingController();
  final _storeCodeController = TextEditingController();
  final _filterController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _employeeEmailController = TextEditingController();
  final _employeePasswordController = TextEditingController();
  String? _selectedRole = 'personel';
  String? _selectedStoreId;

  bool _isLoading = false;
  int _currentIndex = 0;

  List<Store> _stores = [];
  List<AppUser> _employees = [];
  List<Store> _filteredStores = [];
  Map<String, AppUser> _storeManagers = {}; // StoreID -> Müdür

  @override
  void initState() {
    super.initState();
    _fetchData().then((_) {
      _fetchEmployees();
    });
    _filterController.addListener(() {
      _filterStores();
    });
  }

  void _filterStores() {
    final query = _filterController.text.toLowerCase();
    setState(() {
      _filteredStores = _stores.where((store) {
        return store.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchEmployees() async {
    if (!mounted) return;
    // setState(() => _isLoading = true); // RefreshIndicator zaten loading gösterir
    try {
      final employeesData = await Supabase.instance.client.from('profiles').select().order('created_at');
      if (mounted) {
        setState(() {
          _employees = (employeesData as List).map((e) => AppUser.fromJson(e)).toList();
        });
      }
    } catch (e) {
      if (mounted) _showError('Çalışanlar getirilirken hata: $e');
    } finally {
      // if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchData() async {
    // setState(() => _isLoading = true); // RefreshIndicator zaten loading gösterir
    try {
      final client = Supabase.instance.client;

      // 1. Mağazaları Çek
      final storesData = await client.from('stores').select().order('created_at');
      final stores = (storesData as List).map((e) => Store.fromJson(e)).toList();

      // 2. Müdürleri Çek (Tüm müdürleri alıp eşleştireceğiz)
      final managersData = await client
          .from('profiles')
          .select()
          .eq('role', 'mudur');
      
      final managers = (managersData as List).map((e) => AppUser.fromJson(e)).toList();
      
      // Eşleştirme Map'i oluştur
      final Map<String, AppUser> managerMap = {};
      for (var manager in managers) {
        if (manager.storeId != null) {
          managerMap[manager.storeId!] = manager;
        }
      }

      if (mounted) {
        setState(() {
          _stores = stores;
          _filteredStores = stores;
          _storeManagers = managerMap;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      // if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEmployee() async {
    final name = _employeeNameController.text.trim();
    final regNumber = _employeeEmailController.text.trim();
    final password = _employeePasswordController.text.trim();
    final role = _selectedRole;
    final storeId = _selectedStoreId;

    if (name.isEmpty || regNumber.isEmpty || password.isEmpty || role == null) {
      _showError('Lütfen tüm zorunlu alanları doldurun.');
      return;
    }
    
    // Admin harici roller için mağaza seçimi zorunlu
    if (role != 'admin' && storeId == null) {
      _showError('Müdür ve Personel için mağaza seçimi zorunludur.');
      return;
    }

    final email = '$regNumber@magaza.app';

    setState(() => _isLoading = true);
    try {
      // Adım 1: Supabase Auth ile kullanıcı oluştur (metadata ile isim ekle)
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name}, // Metaveriye isim ekle
      );
      
      final user = response.user;
      if (user == null) {
        throw Exception('Kullanıcı oluşturulamadı.');
      }

      // Adım 2: Profiles tablosuna kaydet (store_id ve full_name dahil)
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'email': email,
        'role': role,
        'store_id': role == 'admin' ? null : storeId, // Admin ise null, değilse seçili mağaza
      });

      // Formu temizle
      _employeeNameController.clear();
      _employeeEmailController.clear();
      _employeePasswordController.clear();
      
      if (mounted) {
        setState(() {
          _selectedRole = 'personel';
          _selectedStoreId = null;
        });
      }

      _showSuccessSnackBar('Çalışan başarıyla eklendi: $name ($role)');
      await _fetchEmployees(); // Listeyi yenile

    } on AuthException catch (e) {
      if (e.statusCode == '422') {
        _showError('Bu sicil numarası ile zaten bir kullanıcı mevcut.');
      } else {
        _showError('Yetkilendirme hatası: ${e.message}');
      }
    } catch (e) {
      _showError('Çalışan eklenirken hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addStore() async {
    if (_storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen Mağaza Adı giriniz.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final storeCode = _storeCodeController.text.trim();
      await Supabase.instance.client.from('stores').insert({
        'name': _storeNameController.text.trim(),
        // 'store_code': storeCode.isEmpty ? null : storeCode, // Veritabanında store_code yoksa kapat
      });

      _storeNameController.clear();
      _storeCodeController.clear();
      
      await _fetchData(); // Listeyi yenile
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mağaza başarıyla eklendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekleme Hatası: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStore(String storeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardDark,
          title: const Text('Mağazayı Sil', style: TextStyle(color: Colors.white)),
          content: const Text('Bu mağazayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.', style: TextStyle(color: textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal', style: TextStyle(color: primary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client.from('stores').delete().eq('id', storeId);
        await _fetchData(); // Listeyi yenile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mağaza başarıyla silindi!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme Hatası: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _assignManager(String storeId) async {
    // 1. Fetch unassigned managers
    setState(() => _isLoading = true);
    List<AppUser> unassignedManagers;
    try {
      final unassignedManagersData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'mudur')
          .filter('store_id', 'is', null);

      unassignedManagers = (unassignedManagersData as List)
          .map((e) => AppUser.fromJson(e))
          .toList();
    } catch (e) {
      if (mounted) _showError('Müdürler getirilirken hata: $e');
      setState(() => _isLoading = false);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (unassignedManagers.isEmpty) {
      _showError('Atanacak uygun müdür bulunamadı.');
      return;
    }

    // 2. Show a dialog to select a manager
    final selectedManager = await showDialog<AppUser>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardDark,
          title: const Text('Müdür Ata', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: unassignedManagers.length,
              itemBuilder: (context, index) {
                final manager = unassignedManagers[index];
                return ListTile(
                  title: Text(manager.fullName, style: const TextStyle(color: textSecondary)),
                  onTap: () {
                    Navigator.of(context).pop(manager);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: primary)),
            ),
          ],
        );
      },
    );

    // 3. If a manager was selected, update their profile
    if (selectedManager != null) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'store_id': storeId})
            .eq('id', selectedManager.id);
        
        await _fetchData(); // Refresh data
        
        if (mounted) {
          _showSuccessSnackBar('${selectedManager.fullName} mağazaya atandı.');
        }
      } catch (e) {
        if (mounted) _showError('Atama sırasında hata: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _logout() {
    Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      // Custom AppBar benzeri yapı
      appBar: AppBar(
        backgroundColor: bgDark.withOpacity(0.95),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderDark.withOpacity(0.5), height: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings, color: primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Paneli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_currentIndex == 0 ? 'Mağaza Yönetimi' : 'Çalışan Yönetimi', style: const TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: textSecondary),
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      floatingActionButton: null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildStoresPage(),
          _buildEmployeesPage(),
        ],
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
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Mağazalar'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Çalışanlar'),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresPage() {
    return RefreshIndicator(
      onRefresh: () => _fetchData().then((_) => _fetchEmployees()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Pull to refresh için her zaman kaydırılabilir olmalı
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Yeni Mağaza Ekle Bölümü ---
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderDark.withOpacity(0.3))),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_business, color: primary),
                      SizedBox(width: 8),
                      Text('Yeni Mağaza Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Mağaza Adı'),
                  _buildInput(_storeNameController, 'Örn: Osmangazi'),
                  const SizedBox(height: 12),
                  _buildLabel('Mağaza Kodu'),
                  _buildInput(_storeCodeController, '1751'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addStore,
                      icon: const Icon(Icons.save),
                      label: const Text('Mağaza Ekle'),
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

            // --- Mağaza Listesi Bölümü ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mağaza Listesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: _buildInput(_filterController, 'Filtrele', icon: Icons.search),
                    ),
                  ),
                ],
              ),
            ),

            _isLoading && _filteredStores.isEmpty 
              ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Scroll SingleChildScrollView'a ait
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredStores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final store = _filteredStores[index];
                    final manager = _storeManagers[store.id];
                    return _buildStoreCard(store, manager);
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesPage() {
    return RefreshIndicator(
      onRefresh: _fetchEmployees,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Yeni Çalışan Ekle Bölümü ---
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderDark.withOpacity(0.3))),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add, color: primary),
                      SizedBox(width: 8),
                      Text('Yeni Çalışan Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Tam Ad'),
                  _buildInput(_employeeNameController, 'Örn: Ahmet Yılmaz'),
                  const SizedBox(height: 12),
                  _buildLabel('Sicil No / Email'),
                  _buildInput(_employeeEmailController, '123456', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  const SizedBox(height: 12),
                  _buildLabel('Şifre'),
                  _buildInput(_employeePasswordController, '••••••'),
                  const SizedBox(height: 12),
                  _buildLabel('Rol'),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        items: ['personel', 'mudur'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                            if (_selectedRole == 'admin') {
                              _selectedStoreId = null; // Admin ise mağaza seçimi olmamalı
                            }
                          });
                        },
                        dropdownColor: cardDark,
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLabel('Mağaza'),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole == 'admin' ? null : _selectedStoreId,
                        hint: const Text('Mağaza Seçin', style: TextStyle(color: textSecondary)),
                        isExpanded: true,
                        items: _stores.map((store) => DropdownMenuItem(value: store.id, child: Text(store.name))).toList(),
                        onChanged: _selectedRole == 'admin' ? null : (value) => setState(() => _selectedStoreId = value),
                        dropdownColor: cardDark,
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addEmployee,
                      icon: const Icon(Icons.add),
                      label: const Text('Çalışan Ekle'),
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
            // --- Çalışan Listesi ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: const Text('Tüm Çalışanlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            if (_isLoading && _employees.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  final employee = _employees[index];
                  // Find store name, safely
                  final store = _stores.firstWhere((s) => s.id == employee.storeId, orElse: () => Store(id: '', name: 'Atanmamış', storeCode: null));final storeName = store.name;
                  
                  return Card(
                    color: cardDark,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.2),
                        child: Text(employee.role.isNotEmpty ? employee.role.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(employee.fullName, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${employee.role} - $storeName', style: const TextStyle(color: textSecondary)),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {IconData? icon, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderDark),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: TextAlign.left,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
          prefixIcon: icon != null ? Icon(icon, color: textSecondary, size: 20) : null,
        ),
      ),
    );
  }

  Widget _buildStoreCard(Store store, AppUser? manager) {
    final bool hasManager = manager != null;
    
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDark),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Üst Kısım
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Colors.blue.shade900, Colors.blueGrey.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.storefront, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                          // Store code yoksa ID'nin ilk 4 hanesini göster
                          // (store.storeCode?.isNotEmpty ?? false)
                          //     ? '#${store.storeCode!}'
                          //     : '#${store.id.substring(0, 4).toUpperCase()}',
                          '#${store.id.substring(0, 4).toUpperCase()}',
                          style: const TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text('AKTİF', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(color: borderDark, height: 24),
          
          // Alt Kısım
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MAĞAZA MÜDÜRÜ', style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  if (hasManager)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          child: Text(manager.fullName.substring(0, 1).toUpperCase(), 
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ),
                        const SizedBox(width: 6),
                        Text(manager.fullName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text('Atanmadı', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
              Row(
                children: [
                  if (!hasManager)
                    InkWell(
                      onTap: () => _assignManager(store.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.person_add, size: 16, color: primary),
                            SizedBox(width: 4),
                            Text('Ata', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, color: textSecondary, size: 20),
                      tooltip: 'Düzenle',
                    ),
                  IconButton(
                    onPressed: () => _deleteStore(store.id),
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    tooltip: 'Sil',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}