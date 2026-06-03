import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  // Servisi tek bir çatıdan yönetmek için Singleton mimarisi kuruyoruz
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Tarama durumunu kontrol etmek için bir StreamController
  final StreamController<bool> _isScanningController = StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningController.stream;

  /// Etraftaki Bluetooth cihazlarını tarar ve hocanın cihazını (RSSI değeriyle) bulur.
  /// [targetDeviceName]: Hocanın telefonunun Bluetooth adı (Örn: "Hoca_S24")
  /// [timeoutSeconds]: Taramanın kaç saniye süreceği
  Future<ScanResult?> scanForTeacherDevice({
    required String targetDeviceName,
    int timeoutSeconds = 10,
  }) async {
    // 1. Bluetooth'un açık olup olmadığını kontrol et
    if (await FlutterBluePlus.isSupported == false) {
      print("❌ Bu cihaz Bluetooth desteklemiyor.");
      return null;
    }

    // Bluetooth kapalıysa açılmasını bekle/iste (Sadece Android'de otomatik tetiklenebilir)
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      print("⚠️ Bluetooth kapalı, lütfen açın.");
      // Bazı cihazlarda izin durumuna göre direkt açılması için istek atar
      await FlutterBluePlus.turnOn();
    }

    ScanResult? foundDevice;
    Completer<ScanResult?> completer = Completer<ScanResult?>();

    // 2. Tarama sonuçlarını dinlemeye başla
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Log ekranında etraftaki cihazları görmek için yazdırıyoruz
        print('📱 Cihaz Bulundu: [${r.device.platformName}] - Sinyal Gücü (RSSI): [${r.rssi} dBm]');

        // Eğer aradığımız hoca cihazını ismiyle yakaladıysak:
        if (r.device.platformName.trim() == targetDeviceName.trim()) {
          print('🎯 Hoca Cihazı Yakalandı! RSSI: ${r.rssi}');
          foundDevice = r;
          if (!completer.isCompleted) {
            FlutterBluePlus.stopScan();
            completer.complete(r);
          }
        }
      }
    }, onError: (e) {
      print("❌ Tarama hatası: $e");
      if (!completer.isCompleted) completer.complete(null);
    });

    // 3. Taramayı başlat
    _isScanningController.add(true);
    print('🔍 Bluetooth taraması başlatıldı... ($timeoutSeconds saniye sürecek)');

    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: timeoutSeconds),
        androidUsesFineLocation: true, // Android konum doğrulaması için şart
      );
    } catch (e) {
      print("❌ Taramayı başlatırken hata oluştu: $e");
      _isScanningController.add(false);
      subscription.cancel();
      return null;
    }

    // Tarama bittiğinde (timeout olduğunda) tetiklenir
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    _isScanningController.add(false);
    print('⏹️ Tarama süresi doldu veya durduruldu.');

    // Aboneliği temizle
    await subscription.cancel();

    if (!completer.isCompleted) {
      completer.complete(foundDevice);
    }

    return completer.future;
  }
}