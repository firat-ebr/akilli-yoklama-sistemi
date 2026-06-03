import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:akilli_yoklama/core/services/api_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Cihazdaki kullanılabilir kameraları alıyoruz
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      // Yüz tanıma olacağı için ön kamerayı (front) seçiyoruz
      CameraDescription frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        print("❌ Kamera başlatma hatası: $e");
      }
    }
  }

  Future<void> _takePictureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Fotoğrafı çek
      final XFile image = await _controller!.takePicture();
      print("📸 Fotoğraf çekildi: ${image.path}");

      // 2. Sunucuya gönder (Örnek olarak student_id: "12345" yolluyoruz)
      bool isMatched = await _apiService.verifyAttendance(
        imagePath: image.path,
        studentId: "12345",
      );

      if (mounted) {
        _showResultDialog(isMatched);
      }
    } catch (e) {
      print("❌ Fotoğraf işleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf çekilirken bir hata oluştu.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showResultDialog(bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          isSuccess ? "✅ Yoklama Başarılı" : "❌ Eşleşme Başarısız",
          style: TextStyle(color: isSuccess ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isSuccess
              ? "Yüzünüz başarıyla tanındı ve derse katılımınız sisteme işlendi."
              : "Yüzünüz sistemdeki referans fotoğrafla eşleşmedi. Lütfen tekrar deneyin.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              if (isSuccess) {
                Navigator.pop(context); // Kamera ekranını kapat
                Navigator.pop(context); // Dashboard'a dön
              }
            },
            child: const Text("Tamam", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF121218),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text("Yüz Tanıma Bölümü", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Kamera Önizlemesi
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Yüz hizalama halkası maskesi (Tasarım şıklığı için)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withOpacity(0.8), width: 4),
              ),
            ),
          ),

          // Alt kısımdaki Fotoğraf Çekme Butonu
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.blueAccent)
                  : FloatingActionButton(
                onPressed: _takePictureAndVerify,
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}