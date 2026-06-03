import 'package:flutter/material.dart';
import 'package:akilli_yoklama/core/services/bluetooth_service.dart' as custom;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:akilli_yoklama/features/student/camera_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final custom.BluetoothService _bluetoothService = custom.BluetoothService();
  String _statusMessage = "Yoklama işlemini başlatmak için aşağıdaki butona basın.";
  bool _isLoading = false;

  // Test amaçlı hocanın telefonunun Bluetooth adını buraya yazıyoruz.
  final String _teacherDeviceName = "Hoca_S24";

  Future<void> _startAttendanceProcess() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Sınıf aranıyor... Lütfen Bluetooth ve Konum servislerinizin açık olduğundan emin olun.";
    });

    ScanResult? result = await _bluetoothService.scanForTeacherDevice(
      targetDeviceName: _teacherDeviceName,
      timeoutSeconds: 8,
    );

    setState(() {
      _isLoading = false;
    });


    if (result != null) {
      int rssi = result.rssi;
      if (rssi >= -75) {
        setState(() {
          _statusMessage = "🎯 Sınıf doğrulandı! Sinyal Gücü (RSSI): $rssi dBm\nŞimdi yüz tanıma için kameraya yönlendiriliyorsunuz...";
        });
        _showSuccessDialog();
      } else {
        setState(() {
          _statusMessage = "❌ Sınıf sinyali çok zayıf ($rssi dBm).\nLütfen hocaya daha yakın bir yere geçip tekrar deneyin.";
        });
      }
    } else {
      setState(() {
        _statusMessage = "❌ Sınıf bulunamadı!\n\"$_teacherDeviceName\" isimli Bluetooth yayını algılanamadı.";
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text("🛡️ Konum Doğrulandı", style: TextStyle(color: Colors.white)),
        content: const Text("Bluetooth tabanlı sınıf içi varlığınız başarıyla doğrulandı. Bir sonraki aşama olan yüz tanıma işlemine geçebilirsiniz.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapatır
              // Kamera ekranına geçiş yapar:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            child: const Text("Kamerayı Aç", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text('Öğrenci Yoklama Paneli', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isLoading ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent),
              ),
              child: Column(
                children: [
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.blueAccent)
                      : Icon(
                      _statusMessage.contains("❌") ? Icons.gpp_bad_rounded : Icons.bluetooth_searching_rounded,
                      size: 48,
                      color: _statusMessage.contains("❌") ? Colors.redAccent : Colors.blueAccent
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startAttendanceProcess,
              icon: const Icon(Icons.fingerprint_rounded, size: 24),
              label: Text(_isLoading ? "Sınıf Aranıyor..." : "Yoklama Ver (Konum Doğrula)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Doğru kullanım budur
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                disabledBackgroundColor: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}