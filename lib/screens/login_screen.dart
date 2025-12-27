import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'manager_dashboard.dart';
import 'staff_dashboard.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _sicilNoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _isObscure = true;
  final String _appDomain = "@magaza.app";

  // Renkler
  final Color _bgDark = const Color(0xFF101622);
  final Color _surfaceDark = const Color(0xFF192233);
  final Color _primaryColor = const Color(0xFF135BEC);
  final Color _textSecondary = const Color(0xFF92A4C9);
  final Color _surfaceBorder = const Color(0xFF324467);

  @override
  void dispose() {
    _sicilNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        _showError('Cihazınızda biyometrik özellik bulunamadı.');
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Giriş yapmak için parmak izinizi okutun',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _loginWithBiometrics();
      }
    } on PlatformException catch (e) {
      _showError('Biyometrik Hata: ${e.message}');
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _isLoading = true);
    try {
      final storedSicil = await _storage.read(key: 'sicil_no');
      final storedPass = await _storage.read(key: 'password');

      // NULL KONTROLÜ EKLENDİ
      if (storedSicil != null && storedPass != null) {
        // Form alanlarını doldur (Opsiyonel, kullanıcı görsün diye)
        _sicilNoController.text = storedSicil;
        _passwordController.text = storedPass;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kimlik doğrulandı, giriş yapılıyor...'), duration: Duration(seconds: 1)),
        );
        
        // _signIn'i controller'daki değerlerle değil, doğrudan storage'dan gelenlerle çağırıyoruz
        // Çünkü setState asenkron çalışabilir ve controller hemen güncellenmeyebilir.
        await _signInWithCredentials(storedSicil, storedPass);
      } else {
        _showError('Lütfen güvenli giriş için önce bir kez şifrenizle giriş yapın.');
      }
    } catch (e) {
      _showError('Güvenli depolama hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // YENİ METOD: Parametre ile giriş
  Future<void> _signInWithCredentials(String sicilNo, String password) async {
    final email = "$sicilNo$_appDomain";

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _navigateToRole(response.user!.id);
      }
    } on AuthException catch (e) {
      _showError('Giriş Başarısız: ${e.message}');
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<void> _signIn({bool isBiometric = false}) async {
    final sicilNo = _sicilNoController.text.trim();
    final password = _passwordController.text.trim();

    if (sicilNo.isEmpty || password.isEmpty) {
      _showError('Lütfen sicil no ve şifre girin.');
      return;
    }

    if (!isBiometric) {
      if (sicilNo.length != 6 || int.tryParse(sicilNo) == null) {
        _showError('Sicil numarası 6 haneli bir sayı olmalıdır.');
        return;
      }
    }

    setState(() => _isLoading = true);
    // Bu metod formdan okuyarak _signInWithCredentials'ı çağırır
    await _signInWithCredentials(sicilNo, password);
    
    // Başarılı giriş sonrası kaydetme işlemi _signInWithCredentials içinde değil burada yapılır
    // Çünkü _signInWithCredentials'ın başarılı olup olmadığını o metodun içinde kontrol ediyoruz
    // Ancak daha temiz bir yapı için kaydetme işlemini _navigateToRole öncesinde yapmak daha mantıklı.
    // Düzeltme: Kaydetme işlemini _signInWithCredentials başarılı olursa yapalım.
    
    // NOT: _signInWithCredentials içinde başarılı olursa _navigateToRole çağrılıyor.
    // O yüzden kaydetmeyi oraya taşıyorum.
    
    if (mounted) setState(() => _isLoading = false);
  }
  
  // _navigateToRole metodunda küçük bir değişiklik: storage'a yazma
  Future<void> _navigateToRole(String userId) async {
    try {
        // Başarılı giriş sonrası bilgileri güncelle
        if (_sicilNoController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
             await _storage.write(key: 'sicil_no', value: _sicilNoController.text.trim());
             await _storage.write(key: 'password', value: _passwordController.text.trim());
        }

      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = AppUser.fromJson(profileData);
      
      if (!mounted) return;
      
      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
        );
        return;
      }

      if (user.storeId == null) {
        _showError('HATA: Kullanıcıya atanmış bir mağaza bulunamadı!');
        return;
      }

      if (user.role == 'mudur') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ManagerDashboard(user: user)),
        );
      } else if (user.role == 'personel') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => StaffDashboard(user: user)),
        );
      } else {
        _showError('Yetkisiz Rol: ${user.role}');
      }
    } catch (e) {
      _showError('Profil verisi alınamadı: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [_primaryColor.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: _surfaceDark,
                          border: Border.all(color: _surfaceBorder),
                          boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: Icon(Icons.inventory_2_outlined, size: 48, color: _primaryColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Personel Girişi', textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Lütfen 6 haneli sicil numaranızı giriniz', textAlign: TextAlign.center,
                      style: TextStyle(color: _textSecondary)),
                    const SizedBox(height: 48),

                    _buildLabel('Sicil No'),
                    _buildInputContainer(
                      child: TextField(
                        controller: _sicilNoController,
                        style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: _buildInputDecoration(
                          hint: '123456',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Şifre'),
                    _buildInputContainer(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          hint: '••••••',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _textSecondary),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _signIn(isBiometric: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _authenticate,
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: const Text('Parmak İzi ile Giriş'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: _textSecondary,
                        side: BorderSide(color: _surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
    child: Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500)),
  );

  Widget _buildInputContainer({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: _surfaceDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _surfaceBorder),
    ),
    child: child,
  );

  InputDecoration _buildInputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) => InputDecoration(
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: Icon(icon, color: _textSecondary),
    suffixIcon: suffixIcon,
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[600]),
  );
}