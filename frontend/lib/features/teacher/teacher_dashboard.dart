import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _isAdvertising = false;
  String _statusMessage = "Yoklamayı başlatmak ve sınıfa yayın yapmak için aşağıdaki butona basın.";
  final String _teacherDeviceName = "Hoca_S24";

  // Test amaçlı sahte (mock) yoklama listesi verisi
  final List<Map<String, String>> _attendanceList = [
    {"name": "Ben B.", "no": "2021123001", "status": "Geldi", "time": "14:32"},
    {"name": "Fırat Ebiri", "no": "2021123002", "status": "Geldi", "time": "14:35"},
    {"name": "Mehmet Toprak", "no": "2021123003", "status": "Geldi", "time": "14:36"},
    {"name": "Sabriye Görücü", "no": "2021123004", "status": "Geldi", "time": "14:40"},
  ];

  Future<void> _toggleAttendanceBroadcast() async {
    if (_isAdvertising) {
      try {
        await FlutterBluePlus.stopScan();
        setState(() {
          _isAdvertising = false;
          _statusMessage = "Yoklama başarıyla kapatıldı. Yayın durduruldu.";
        });
      } catch (e) {
        print("❌ Yayın durdurulurken hata: $e");
      }
    } else {
      setState(() {
        _statusMessage = "Bluetooth donanımı kontrol ediliyor...";
      });

      if (await FlutterBluePlus.isSupported == false) {
        setState(() { _statusMessage = "❌ Cihaz BLE desteklemiyor."; });
        return;
      }

      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      setState(() {
        _isAdvertising = true;
        _statusMessage = "🔊 Yoklama Aktif!\n\nSınıf şu an \"$_teacherDeviceName\" ismiyle Bluetooth yayını yapıyor.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text('Hoca Yoklama Paneli', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView( // Ekranın taşmasını önlemek için kaydırılabilir yaptık
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Yayın Durum Kartı
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isAdvertising ? Colors.greenAccent.withOpacity(0.5) : Colors.transparent, width: 2),
              ),
              child: Column(
                children: [
                  if (_isAdvertising)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 4)),
                    )
                  else
                    const Icon(Icons.radar_rounded, size: 56, color: Colors.amberAccent),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _isAdvertising ? Colors.greenAccent : Colors.white70, fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Yoklamayı Başlat / Bitir Butonu
            ElevatedButton.icon(
              onPressed: _toggleAttendanceBroadcast,
              icon: Icon(_isAdvertising ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded, size: 26),
              label: Text(_isAdvertising ? "Yoklamayı Bitir" : "Yoklamayı Başlat"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAdvertising ? Colors.redAccent : Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            // 🌟 AÇILABİLİR BUTON (EXPANSION TILE) - YOKLAMA LİSTESİ
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Çizgileri gizler
              child: ExpansionTile(
                backgroundColor: const Color(0xFF1E1E2E),
                collapsedBackgroundColor: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.assignment_turned_in_rounded, color: Colors.blueAccent),
                title: const Text("Mevcut Yoklama Listesi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("${_attendanceList.length} Öğrenci Giriş Yaptı", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300), // Doğru kullanım budur dostum
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _attendanceList.length,
                      itemBuilder: (context, index) {
                        final student = _attendanceList[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121218),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student["name"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  Text(student["no"]!, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(student["time"]!, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                    child: Text(student["status"]!, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}