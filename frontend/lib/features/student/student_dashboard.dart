import 'package:flutter/material.dart';
import 'package:akilli_yoklama/core/services/bluetooth_service.dart' as custom;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:akilli_yoklama/features/student/camera_screen.dart';

class StudentDashboard extends StatefulWidget {
  // ✅ DÜZELTME: studentId artık login'den parametre olarak geliyor
  final String studentId;

  const StudentDashboard({super.key, required this.studentId});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final custom.BluetoothService _bluetoothService = custom.BluetoothService();
  String _statusMessage = "Yoklama işlemini başlatmak için aşağıdaki butona basın.";
  bool _isLoading = false;
  int _foundRssi = 0;

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
      _foundRssi = rssi;

      if (rssi >= -75) {
        setState(() {
          _statusMessage = "🎯 Sınıf doğrulandı! Sinyal Gücü: $rssi dBm\nŞimdi yüz tanıma için kameraya yönlendiriliyorsunuz...";
        });
        _showSuccessDialog(rssi);
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

  void _showSuccessDialog(int rssi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text("🛡️ Konum Doğrulandı", style: TextStyle(color: Colors.white)),
        content: Text(
          "Bluetooth ile sınıf içi varlığınız doğrulandı (RSSI: $rssi dBm).\n\nSıradaki adım: Yüz tanıma.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ✅ DÜZELTME: RSSI ve studentId kamera ekranına parametre olarak geçiliyor
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(
                    rssiValue: rssi,
                    studentId: widget.studentId,
                  ),
                ),
              );
            },
            child: const Text("Kamerayı Aç",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
        title: const Text('Öğrenci Yoklama Paneli',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            // Öğrenci bilgi kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: Colors.blueAccent, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    "Öğrenci No: ${widget.studentId}",
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Durum kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _isLoading ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent),
              ),
              child: Column(
                children: [
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.blueAccent)
                      : Icon(
                          _statusMessage.contains("❌")
                              ? Icons.gpp_bad_rounded
                              : Icons.bluetooth_searching_rounded,
                          size: 48,
                          color: _statusMessage.contains("❌")
                              ? Colors.redAccent
                              : Colors.blueAccent,
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
              label: Text(_isLoading ? "Sınıf Aranıyor..." : "Yoklama Ver"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
