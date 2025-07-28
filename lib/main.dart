import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';
import 'firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flogi',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }
          
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String? _error;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await _firebaseService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        // Başarılı giriş - StreamBuilder otomatik olarak HomePage'e yönlendirecek
      } on FirebaseAuthException catch (e) {
        setState(() {
          _error = _getErrorMessage(e.code);
        });
      } catch (e) {
        setState(() {
          _error = 'Bir hata oluştu: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Şifre yanlış';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'invalid-credential':
        return 'E-posta veya şifre yanlış';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen biraz bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      default:
        return 'Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.';
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.account_circle, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text('Flogi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  validator: (value) => value == null || value.isEmpty ? 'E-posta giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Şifre giriniz' : null,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Giriş Yap'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _goToRegister,
                  child: const Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String? _info;
  String? _error;
  bool _isLoading = false;
  bool _registrationSuccess = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _info = null;
        _error = null;
      });

      try {
        // Kayıt işlemi
        final userCredential = await _firebaseService.createUserWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        
        print('Kayıt başarılı: ${userCredential.user?.email}');
        
        // Başarı mesajını göster
        setState(() {
          _info = 'Kayıt başarılı! Ana sayfaya yönlendiriliyorsunuz...';
        });
        
        // 2 saniye sonra ana sayfaya git
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        });
        
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Hatası: ${e.code}');
        setState(() {
          _error = _getRegisterErrorMessage(e.code);
        });
      } catch (e) {
        print('Genel Hata: $e');
        // Eğer kayıt başarılı olduysa hata gösterme
        if (e.toString().contains('user-not-found') || e.toString().contains('invalid-credential')) {
          setState(() {
            _error = 'Kayıt olurken bir hata oluştu. Lütfen tekrar deneyin.';
          });
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRegisterErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'operation-not-allowed':
        return 'Email/şifre ile kayıt devre dışı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'invalid-credential':
        return 'Geçersiz bilgiler.';
      default:
        return 'Kayıt olurken bir hata oluştu: $code';
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      default:
        return 'Kayıt yapılamadı: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.person_add, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text('Kayıt Ol', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  validator: (value) => value == null || value.isEmpty ? 'E-posta giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Şifre giriniz' : null,
                ),
                const SizedBox(height: 16),
                if (_info != null)
                  Text(_info!, style: const TextStyle(color: Colors.green)),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kayıt Ol'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Sadece giriş sayfasına dön
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Girişe Dön',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final void Function(ThemeMode)? changeTheme;
  final ThemeMode? themeMode;
  const HomePage({super.key, this.changeTheme, this.themeMode});

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Container(
          color: Colors.deepPurple.shade50,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.account_circle, size: 48, color: Colors.deepPurple.shade400),
                    ),
                    const SizedBox(height: 12),
                    Text('Flogi', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Ön Muhasebe', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.deepPurple),
                title: Text('Ana Sayfa'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.deepPurple),
                title: Text('Gelir/Gider'),
                onTap: () => _navigate(context, const IncomeExpensePage()),
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.deepPurple),
                title: Text('Müşteriler'),
                onTap: () => _navigate(context, const CustomersPage()),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.deepPurple),
                title: Text('Faturalar'),
                onTap: () => _navigate(context, const InvoicesPage()),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.deepPurple),
                title: Text('Raporlar'),
                onTap: () => _navigate(context, const ReportsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.deepPurple),
                title: Text('Ürün/Hizmetler'),
                onTap: () => _navigate(context, const ProductsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
                title: Text('Kasa/Banka'),
                onTap: () => _navigate(context, const CashBankPage()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                title: Text('Hakkında'),
                onTap: () => _navigate(context, const AboutPage()),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.deepPurple),
                title: Text('Destek'),
                onTap: () => _navigate(context, const SupportPage()),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.deepPurple),
                title: Text('Ayarlar'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.dashboard, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text('Flogi Ön Muhasebe'),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade50,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.deepPurple.shade200,
              child: const Icon(Icons.account_circle, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text('Hoşgeldiniz!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
            const SizedBox(height: 8),
            Text('Flogi Ön Muhasebe', style: TextStyle(color: Colors.deepPurple.shade400)),
            const SizedBox(height: 4),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: TextStyle(color: Colors.deepPurple.shade500, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _HomeCard(
                    icon: Icons.attach_money,
                    label: 'Gelir/Gider',
                    color: Colors.purple.shade200,
                    onTap: () => _navigate(context, const IncomeExpensePage()),
                  ),
                  _HomeCard(
                    icon: Icons.people,
                    label: 'Müşteriler',
                    color: Colors.purple.shade300,
                    onTap: () => _navigate(context, const CustomersPage()),
                  ),
                  _HomeCard(
                    icon: Icons.receipt_long,
                    label: 'Faturalar',
                    color: Colors.purple.shade400,
                    onTap: () => _navigate(context, const InvoicesPage()),
                  ),
                  _HomeCard(
                    icon: Icons.bar_chart,
                    label: 'Raporlar',
                    color: Colors.purple.shade200,
                    onTap: () => _navigate(context, const ReportsPage()),
                  ),
                  _HomeCard(
                    icon: Icons.shopping_bag,
                    label: 'Ürün/Hizmetler',
                    color: Colors.purple.shade300,
                    onTap: () => _navigate(context, const ProductsPage()),
                  ),
                  _HomeCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Kasa/Banka',
                    color: Colors.purple.shade400,
                    onTap: () => _navigate(context, const CashBankPage()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HomeCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// Modül sayfa iskeletleri
// Gelir/Gider veri modeli
class GelirGider {
  final int id;
  final String aciklama;
  final double tutar;
  final DateTime tarih;
  final bool gelirMi;

  GelirGider({
    required this.id,
    required this.aciklama,
    required this.tutar,
    required this.tarih,
    required this.gelirMi,
  });
}

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});
  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  final List<GelirGider> _kayitlar = [];
  final FirebaseService _firebaseService = FirebaseService();

  final _aciklamaController = TextEditingController();
  final _tutarController = TextEditingController();
  bool _gelirMi = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    try {
      final veriler = await _firebaseService.getGelirGider();
      setState(() {
        _kayitlar.clear();
        for (var veri in veriler) {
          try {
            _kayitlar.add(GelirGider(
              id: int.parse(veri['id']),
              aciklama: veri['aciklama'] ?? '',
              tutar: (veri['miktar'] ?? 0).toDouble(),
              tarih: veri['createdAt'] != null 
                ? (veri['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
              gelirMi: veri['tur'] == 'Gelir',
            ));
          } catch (e) {
            print('Veri parse hatası: $e');
          }
        }
      });
    } catch (e) {
      print('Veri yükleme hatası: $e');
    }
  }

  Future<void> _kayitEkle() async {
    if (_aciklamaController.text.isNotEmpty && _tutarController.text.isNotEmpty) {
      try {
        final yeniKayit = {
          'tur': _gelirMi ? 'Gelir' : 'Gider',
          'kategori': _gelirMi ? 'Gelir' : 'Gider',
          'miktar': double.tryParse(_tutarController.text) ?? 0,
          'aciklama': _aciklamaController.text,
        };

        await _firebaseService.addGelirGider(yeniKayit);
        _aciklamaController.clear();
        _tutarController.clear();
        
        // Verileri yenile
        await _verileriYukle();
        
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_gelirMi ? 'Gelir' : 'Gider'} başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Dropdown'u sıfırla
        setState(() {
          _gelirMi = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri eklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _kayitSil(int index) async {
    final kayit = _kayitlar[index];
    await _firebaseService.deleteGelirGider(kayit.id.toString());
    _verileriYukle();
  }

  void _kayitGuncelle(int index) async {
    final kayit = _kayitlar[index];
    final aciklamaController = TextEditingController(text: kayit.aciklama);
    final tutarController = TextEditingController(text: kayit.tutar.toString());
    bool gelirMi = kayit.gelirMi;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: aciklamaController,
                decoration: InputDecoration(labelText: 'Açıklama'),
              ),
              TextField(
                controller: tutarController,
                decoration: InputDecoration(labelText: 'Tutar'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<bool>(
                value: gelirMi,
                items: [
                  DropdownMenuItem(value: true, child: Text('Gelir')),
                  DropdownMenuItem(value: false, child: Text('Gider')),
                ],
                onChanged: (v) {
                  gelirMi = v ?? true;
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guncelKayit = {
                  'tur': gelirMi ? 'Gelir' : 'Gider',
                  'kategori': gelirMi ? 'Gelir' : 'Gider',
                  'miktar': double.tryParse(tutarController.text) ?? 0,
                  'aciklama': aciklamaController.text,
                };
                await _firebaseService.updateGelirGider(kayit.id.toString(), guncelKayit);
                Navigator.pop(context);
                _verileriYukle();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gelir/Gider')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aciklamaController,
                    decoration: InputDecoration(labelText: 'Açıklama'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tutarController,
                    decoration: InputDecoration(labelText: 'Tutar'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<bool>(
                  value: _gelirMi,
                  items: [
                    DropdownMenuItem(value: true, child: Text('Gelir')),
                    DropdownMenuItem(value: false, child: Text('Gider')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _gelirMi = v ?? true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _kayitEkle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _kayitlar.length,
                itemBuilder: (context, index) {
                  final kayit = _kayitlar[index];
                  return ListTile(
                    leading: Icon(kayit.gelirMi ? Icons.arrow_downward : Icons.arrow_upward, color: kayit.gelirMi ? Colors.green : Colors.red),
                    title: Text(kayit.aciklama),
                    subtitle: Text('${kayit.tutar.toStringAsFixed(2)} TL - ${kayit.tarih.day}.${kayit.tarih.month}.${kayit.tarih.year} - ${kayit.gelirMi ? 'Gelir' : 'Gider'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _kayitGuncelle(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _kayitSil(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Müşteri veri modeli
class Musteri {
  final String id;
  final String ad;
  final String telefon;
  final String email;

  Musteri({
    required this.id,
    required this.ad,
    required this.telefon,
    required this.email,
  });
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final List<Musteri> _musteriler = [];
  final FirebaseService _firebaseService = FirebaseService();
  final _adController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final veriler = await _firebaseService.getMusteriler();
    setState(() {
      _musteriler.clear();
      for (var veri in veriler) {
        _musteriler.add(Musteri(
          id: veri['id'] ?? '',
          ad: veri['ad'] ?? '',
          telefon: veri['telefon'] ?? '',
          email: veri['email'] ?? '',
        ));
      }
    });
  }

  Future<void> _musteriEkle() async {
    if (_adController.text.isNotEmpty) {
      try {
        final yeniMusteri = {
          'ad': _adController.text,
          'telefon': _telefonController.text,
          'email': _emailController.text,
        };

        await _firebaseService.addMusteri(yeniMusteri);
        _adController.clear();
        _telefonController.clear();
        _emailController.clear();
        
        // Verileri yenile
        await _verileriYukle();
        
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müşteri başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müşteri eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _musteriSil(int index) async {
    final musteri = _musteriler[index];
    await _firebaseService.deleteMusteri(musteri.id);
    _verileriYukle();
  }

  void _musteriGuncelle(int index) async {
    final musteri = _musteriler[index];
    final adController = TextEditingController(text: musteri.ad);
    final telefonController = TextEditingController(text: musteri.telefon);
    final emailController = TextEditingController(text: musteri.email);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adController,
                decoration: InputDecoration(labelText: 'Ad'),
              ),
              TextField(
                controller: telefonController,
                decoration: InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guncelMusteri = {
                  'ad': adController.text,
                  'telefon': telefonController.text,
                  'email': emailController.text,
                };
                await _firebaseService.updateMusteri(musteri.id, guncelMusteri);
                Navigator.pop(context);
                _verileriYukle();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Müşteriler')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adController,
                    decoration: InputDecoration(labelText: 'Ad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _telefonController,
                    decoration: InputDecoration(labelText: 'Telefon'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _musteriEkle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _musteriler.length,
                itemBuilder: (context, index) {
                  final musteri = _musteriler[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(musteri.ad),
                    subtitle: Text('${musteri.telefon} - ${musteri.email} - Müşteri ID: ${musteri.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _musteriGuncelle(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _musteriSil(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fatura veri modeli
class Fatura {
  final int id;
  final String faturaNo;
  final String musteriAdi;
  final double tutar;
  final DateTime tarih;

  Fatura({
    required this.id,
    required this.faturaNo,
    required this.musteriAdi,
    required this.tutar,
    required this.tarih,
  });
}

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final List<Fatura> _faturalar = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _faturaNoController = TextEditingController();
  final _musteriAdiController = TextEditingController();
  final _tutarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final veriler = await _dbHelper.getFaturalar();
    setState(() {
      _faturalar.clear();
      for (var veri in veriler) {
        _faturalar.add(Fatura(
          id: veri['id'],
          faturaNo: veri['aciklama'] ?? '',
          musteriAdi: veri['musteri_adi'] ?? '',
          tutar: veri['tutar']?.toDouble() ?? 0,
          tarih: DateTime.parse(veri['tarih']),
        ));
      }
    });
  }

  Future<void> _faturaEkle() async {
    if (_faturaNoController.text.isNotEmpty && _musteriAdiController.text.isNotEmpty && _tutarController.text.isNotEmpty) {
      final yeniFatura = {
        'musteri_id': null, // Şimdilik null, ileride müşteri seçimi eklenebilir
        'tur': 'Satış',
        'tutar': double.tryParse(_tutarController.text) ?? 0,
        'tarih': DateTime.now().toIso8601String(),
        'aciklama': _faturaNoController.text,
      };

      await _dbHelper.insertFatura(yeniFatura);
      _faturaNoController.clear();
      _musteriAdiController.clear();
      _tutarController.clear();
      _verileriYukle();
    }
  }

  Future<void> _faturaSil(int index) async {
    final fatura = _faturalar[index];
    await _dbHelper.deleteFatura(fatura.id);
    _verileriYukle();
  }

  void _faturaGuncelle(int index) async {
    final fatura = _faturalar[index];
    final faturaNoController = TextEditingController(text: fatura.faturaNo);
    final musteriAdiController = TextEditingController(text: fatura.musteriAdi);
    final tutarController = TextEditingController(text: fatura.tutar.toString());
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: faturaNoController,
                decoration: InputDecoration(labelText: 'Fatura No'),
              ),
              TextField(
                controller: musteriAdiController,
                decoration: InputDecoration(labelText: 'Müşteri Adı'),
              ),
              TextField(
                controller: tutarController,
                decoration: InputDecoration(labelText: 'Tutar'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guncelFatura = {
                  'id': fatura.id,
                  'musteri_id': null,
                  'tur': 'Satış',
                  'tutar': double.tryParse(tutarController.text) ?? 0,
                  'tarih': fatura.tarih.toIso8601String(),
                  'aciklama': faturaNoController.text,
                };
                await _dbHelper.updateFatura(guncelFatura);
                Navigator.pop(context);
                _verileriYukle();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Faturalar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _faturaNoController,
                    decoration: InputDecoration(labelText: 'Fatura No'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _musteriAdiController,
                    decoration: InputDecoration(labelText: 'Müşteri Adı'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tutarController,
                    decoration: InputDecoration(labelText: 'Tutar'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _faturaEkle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _faturalar.length,
                itemBuilder: (context, index) {
                  final fatura = _faturalar[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Fatura No: ${fatura.faturaNo}'),
                    subtitle: Text('${fatura.musteriAdi} - ${fatura.tutar.toStringAsFixed(2)} TL - ${fatura.tarih.day}.${fatura.tarih.month}.${fatura.tarih.year}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _faturaGuncelle(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _faturaSil(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  double _gelirToplami = 0;
  double _giderToplami = 0;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final gelir = await _firebaseService.getGelirToplami();
    final gider = await _firebaseService.getGiderToplami();
    setState(() {
      _gelirToplami = gelir;
      _giderToplami = gider;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fark = _gelirToplami - _giderToplami;
    final seed = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(title: Text('Raporlar')),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [seed.shade100, seed.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ReportCard(
                    icon: Icons.arrow_downward,
                    label: 'Toplam Gelir',
                    value: '${_gelirToplami.toStringAsFixed(2)} TL',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _ReportCard(
                    icon: Icons.arrow_upward,
                    label: 'Toplam Gider',
                    value: '${_giderToplami.toStringAsFixed(2)} TL',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ReportCard(
                icon: fark >= 0 ? Icons.trending_up : Icons.trending_down,
                label: 'Fark',
                value: '${fark.toStringAsFixed(2)} TL',
                color: fark >= 0 ? Colors.blue : Colors.red,
                big: true,
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                color: seed.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text('Aylık ve Günlük Raporlar', style: TextStyle(fontWeight: FontWeight.bold, color: seed)),
                      const SizedBox(height: 8),
                      Text('Bu bölümde ileride grafik ve detaylı raporlar yer alacak.', style: TextStyle(color: seed.shade400)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool big;
  const _ReportCard({required this.icon, required this.label, required this.value, required this.color, this.big = false});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: big ? 32 : 20, vertical: big ? 28 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: big ? 40 : 28, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: big ? 22 : 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// Ürün/Hizmet veri modeli
class UrunHizmet {
  final int id;
  final String ad;
  final double fiyat;
  final String birim;

  UrunHizmet({
    required this.id,
    required this.ad,
    required this.fiyat,
    required this.birim,
  });
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final List<UrunHizmet> _urunler = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _adController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _birimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final veriler = await _dbHelper.getUrunHizmet();
    setState(() {
      _urunler.clear();
      for (var veri in veriler) {
        _urunler.add(UrunHizmet(
          id: veri['id'],
          ad: veri['ad'] ?? '',
          fiyat: veri['fiyat']?.toDouble() ?? 0,
          birim: veri['kategori'] ?? '',
        ));
      }
    });
  }

  Future<void> _urunEkle() async {
    if (_adController.text.isNotEmpty && _fiyatController.text.isNotEmpty) {
      final yeniUrun = {
        'ad': _adController.text,
        'kategori': _birimController.text,
        'fiyat': double.tryParse(_fiyatController.text) ?? 0,
        'aciklama': '',
      };

      await _dbHelper.insertUrunHizmet(yeniUrun);
      _adController.clear();
      _fiyatController.clear();
      _birimController.clear();
      _verileriYukle();
    }
  }

  Future<void> _urunSil(int index) async {
    final urun = _urunler[index];
    await _dbHelper.deleteUrunHizmet(urun.id);
    _verileriYukle();
  }

  void _urunGuncelle(int index) async {
    final urun = _urunler[index];
    final adController = TextEditingController(text: urun.ad);
    final fiyatController = TextEditingController(text: urun.fiyat.toString());
    final birimController = TextEditingController(text: urun.birim);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adController,
                decoration: InputDecoration(labelText: 'Ad'),
              ),
              TextField(
                controller: fiyatController,
                decoration: InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: birimController,
                decoration: InputDecoration(labelText: 'Birim'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guncelUrun = {
                  'id': urun.id,
                  'ad': adController.text,
                  'kategori': birimController.text,
                  'fiyat': double.tryParse(fiyatController.text) ?? 0,
                  'aciklama': '',
                };
                await _dbHelper.updateUrunHizmet(guncelUrun);
                Navigator.pop(context);
                _verileriYukle();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ürün/Hizmetler')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adController,
                    decoration: InputDecoration(labelText: 'Ad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fiyatController,
                    decoration: InputDecoration(labelText: 'Fiyat'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _birimController,
                    decoration: InputDecoration(labelText: 'Birim'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _urunEkle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _urunler.length,
                itemBuilder: (context, index) {
                  final urun = _urunler[index];
                  return ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(urun.ad),
                    subtitle: Text('${urun.fiyat.toStringAsFixed(2)} TL / ${urun.birim}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _urunGuncelle(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _urunSil(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kasa/Banka veri modeli
class KasaBanka {
  final int id;
  final String ad;
  final double bakiye;
  final String tur; // Kasa veya Banka

  KasaBanka({
    required this.id,
    required this.ad,
    required this.bakiye,
    required this.tur,
  });
}

class CashBankPage extends StatefulWidget {
  const CashBankPage({super.key});
  @override
  State<CashBankPage> createState() => _CashBankPageState();
}

class _CashBankPageState extends State<CashBankPage> {
  final List<KasaBanka> _hesaplar = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _adController = TextEditingController();
  final _bakiyeController = TextEditingController();
  String _tur = 'Kasa';

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final veriler = await _dbHelper.getKasaBanka();
    setState(() {
      _hesaplar.clear();
      for (var veri in veriler) {
        _hesaplar.add(KasaBanka(
          id: veri['id'],
          ad: veri['hesap_adi'] ?? '',
          bakiye: veri['bakiye']?.toDouble() ?? 0,
          tur: veri['tur'] ?? 'Kasa',
        ));
      }
    });
  }

  Future<void> _hesapEkle() async {
    if (_adController.text.isNotEmpty && _bakiyeController.text.isNotEmpty) {
      final yeniHesap = {
        'tur': _tur,
        'hesap_adi': _adController.text,
        'bakiye': double.tryParse(_bakiyeController.text) ?? 0,
        'aciklama': '',
      };

      await _dbHelper.insertKasaBanka(yeniHesap);
      _adController.clear();
      _bakiyeController.clear();
      _tur = 'Kasa';
      _verileriYukle();
    }
  }

  Future<void> _hesapSil(int index) async {
    final hesap = _hesaplar[index];
    await _dbHelper.deleteKasaBanka(hesap.id);
    _verileriYukle();
  }

  void _hesapGuncelle(int index) async {
    final hesap = _hesaplar[index];
    final adController = TextEditingController(text: hesap.ad);
    final bakiyeController = TextEditingController(text: hesap.bakiye.toString());
    String tur = hesap.tur;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adController,
                decoration: InputDecoration(labelText: 'Ad'),
              ),
              TextField(
                controller: bakiyeController,
                decoration: InputDecoration(labelText: 'Bakiye'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: tur,
                items: [
                  DropdownMenuItem(value: 'Kasa', child: Text('Kasa')),
                  DropdownMenuItem(value: 'Banka', child: Text('Banka')),
                ],
                onChanged: (v) {
                  tur = v ?? 'Kasa';
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guncelHesap = {
                  'id': hesap.id,
                  'tur': tur,
                  'hesap_adi': adController.text,
                  'bakiye': double.tryParse(bakiyeController.text) ?? 0,
                  'aciklama': '',
                };
                await _dbHelper.updateKasaBanka(guncelHesap);
                Navigator.pop(context);
                _verileriYukle();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kasa/Banka')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adController,
                    decoration: InputDecoration(labelText: 'Ad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _bakiyeController,
                    decoration: InputDecoration(labelText: 'Bakiye'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _tur,
                  items: [
                    DropdownMenuItem(value: 'Kasa', child: Text('Kasa')),
                    DropdownMenuItem(value: 'Banka', child: Text('Banka')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _tur = v ?? 'Kasa';
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _hesapEkle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _hesaplar.length,
                itemBuilder: (context, index) {
                  final hesap = _hesaplar[index];
                  return ListTile(
                    leading: Icon(hesap.tur == 'Kasa' ? Icons.account_balance_wallet : Icons.account_balance),
                    title: Text(hesap.ad),
                    subtitle: Text('${hesap.bakiye.toStringAsFixed(2)} TL - ${hesap.tur}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _hesapGuncelle(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _hesapSil(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hakkında')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text('Flogi Ön Muhasebe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
              const SizedBox(height: 12),
              Text('Uygulama Hakkında'),
              const SizedBox(height: 24),
              Text('Sürüm', style: TextStyle(color: Colors.deepPurple.shade300)),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Destek')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text('Destek', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
              const SizedBox(height: 12),
              Text('Her türlü soru ve destek için: support@flogi.com'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Destek'),
                    content: Text('Destek ekibimize e-posta gönderebilirsiniz.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal'))],
                  ),
                ),
                child: Text('Bize Ulaşın'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(32.0),
        children: [
          Center(child: Icon(Icons.settings, size: 64, color: Colors.deepPurple)),
          const SizedBox(height: 16),
          Center(child: Text('Ayarlar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700))),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.deepPurple),
            title: const Text('Dil'),
            subtitle: const Text('Türkçe'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.deepPurple),
            title: const Text('Bildirimler'),
            subtitle: const Text('Açık'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
            title: const Text('Uygulama Hakkında'),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Uygulama Hakkında'),
                content: Text('Flogi Ön Muhasebe\nSürüm: 1.0.0'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
