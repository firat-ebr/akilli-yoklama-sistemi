import 'package:flutter/material.dart';
import 'package:akilli_yoklama/features/student/student_dashboard.dart';
import 'package:akilli_yoklama/features/teacher/teacher_dashboard.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _studentFormKey = GlobalKey<FormState>();
  final _teacherFormKey = GlobalKey<FormState>();

  // Öğrenci Giriş Kontrolcüleri
  final _studentTcController = TextEditingController();
  final _studentNoController = TextEditingController();

  // Eğitmen Giriş Kontrolcüleri
  final _teacherTcController = TextEditingController();
  final _teacherPasswordController = TextEditingController();

  @override
  void dispose() {
    _studentTcController.dispose();
    _studentNoController.dispose();
    _teacherTcController.dispose();
    _teacherPasswordController.dispose();
    super.dispose();
  }

  // Giriş Alanları İçin Ortak Tasarım Şablonu
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: const Color(0xFF1E1E2E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  // Öğrenci Giriş Formu (BottomSheet / Açılır Pencere)
  // ÖĞRENCİ GİRİŞ FORMU (Güncellenmiş - Taşma Engellenmiş Versiyon)
  void _showStudentLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea( // Cihazın alt bar/çentik alanını korur
        child: Padding(
          // Üstten 24, yanlardan 24 ve alttan tam klavye yüksekliği kadar + 24 piksel boşluk bırakır
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView( // Klavye açıldığında içeriğin kaydırılabilmesini sağlar
            child: Form(
              key: _studentFormKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Küçük bir tutamaç çizgisi (Tasarım için)
                    // Küçük bir tutamaç çizgisi (Tasarım için)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20), // Doğru kullanım budur dostum
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
          const Text("Öğrenci Girişi", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _studentTcController,
            keyboardType: TextInputType.number,
            maxLength: 11,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration("T.C. Kimlik No", Icons.badge_rounded),
            validator: (val) => (val == null || val.length != 11) ? "Geçerli bir T.C. giriniz" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentNoController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration("Öğrenci Numarası", Icons.pin_rounded),
            validator: (val) => (val == null || val.isEmpty) ? "Öğrenci numarası boş bırakılamaz" : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_studentFormKey.currentState!.validate()) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ],
        ),
      ),
    ),
    ),
    ),
    );
  }

  // EĞİTMEN GİRİŞ FORMU (Güncellenmiş - Taşma Engellenmiş Versiyon)
  void _showTeacherLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _teacherFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text("Eğitmen Girişi", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _teacherTcController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration("T.C. Kimlik No", Icons.badge_rounded),
                    validator: (val) => (val == null || val.length != 11) ? "Geçerli bir T.C. giriniz" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _teacherPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration("Şifre", Icons.lock_rounded),
                    validator: (val) => (val == null || val.length < 4) ? "Şifre en az 4 karakter olmalıdır" : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_teacherFormKey.currentState!.validate()) {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherDashboard()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fingerprint_rounded, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text("Akıllı Yoklama", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),

              // Öğrenci Kartı
              _buildRoleButton("Öğrenci Girişi", Icons.school_rounded, Colors.blueAccent, _showStudentLoginSheet),
              const SizedBox(height: 16),

              // Eğitmen Kartı
              _buildRoleButton("Eğitmen Girişi", Icons.supervisor_account_rounded, Colors.teal, _showTeacherLoginSheet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}