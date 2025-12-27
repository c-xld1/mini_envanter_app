import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'manager_dashboard.dart';
import 'staff_dashboard.dart';
import 'admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  double _progress = 0.0;

  // Tasarım Renkleri (HTML'den alındı)
  final Color bgDark = const Color(0xFF101622);
  final Color primary = const Color(0xFF135BEC);
  final Color surfaceDark = const Color(0xFF1E293B);
  final Color textSlate = const Color(0xFF94A3B8); // slate-400
  final Color textSlateDark = const Color(0xFF475569); // slate-600

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _startLoadingProcess();
  }

  Future<void> _startLoadingProcess() async {
    // 1. Simüle edilmiş yükleme
    for (var i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        setState(() => _progress = i / 20);
      }
    }

    // 2. Oturum Kontrolü
    if (!mounted) return;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _checkRoleAndRedirect(session.user.id);
      } else {
        _navigateToLogin();
      }
    } catch (_) {
      _navigateToLogin();
    }
  }

  Future<void> _checkRoleAndRedirect(String userId) async {
    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = AppUser.fromJson(profileData);
      if (!mounted) return;

      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminDashboard(user: user)));
      } else if (user.role == 'mudur') {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ManagerDashboard(user: user)));
      } else if (user.role == 'personel') {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => StaffDashboard(user: user)));
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      // Stack: Arka plan efektleri için
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Arka Plan Glow Efekti (Ortalanmış)
          Positioned(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // 2. Ana İçerik (Kaydırılabilir ve Orantılı)
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Esnek kaydırma
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight, // Ekranın tamamını kapla
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Üst boşluk (Spacer görevi görür)
                          const Spacer(),

                          // --- ORTA KISIM: LOGO & BAŞLIK ---
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo Yapısı
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Dış Halka
                                      Container(
                                        width: 128,
                                        height: 128,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: primary.withOpacity(0.2), width: 1),
                                        ),
                                      ),
                                      // İç Kutu ve İkon
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: primary.withOpacity(0.2)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: Icon(Icons.inventory_2_outlined,
                                            size: 60, color: primary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Başlık
                                const Text(
                                  'Stok Takip',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Alt Başlık
                                Text(
                                  'KURUMSAL ENVANTER ÇÖZÜMLERİ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textSlate,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Alt boşluk (Orta kısmı yukarı iter)
                          const Spacer(),

                          // --- ALT KISIM: LOADING & SÜRÜM ---
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Loading Alanı (Maksimum genişlik sınırlaması ile)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 320),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Veriler Senkronize Ediliyor...',
                                            style: TextStyle(
                                                color: textSlate,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '${(_progress * 100).toInt()}%',
                                            style: TextStyle(
                                                color: primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Progress Bar
                                      Container(
                                        height: 6,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: surfaceDark,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: primary,
                                              borderRadius: BorderRadius.circular(999),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primary.withOpacity(0.5),
                                                  blurRadius: 10,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Sürüm Bilgisi
                                Column(
                                  children: [
                                    Icon(Icons.verified_user_outlined,
                                        size: 24, color: textSlateDark),
                                    const SizedBox(height: 4),
                                    Text(
                                      'v1.0.2 • Build 2409',
                                      style: TextStyle(
                                          color: textSlateDark,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                // Güvenli alan için alt boşluk
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}