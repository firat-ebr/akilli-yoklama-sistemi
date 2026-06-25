import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:akilli_yoklama/core/services/api_service.dart';

class CameraScreen extends StatefulWidget {
  // ✅ DÜZELTME: RSSI değeri artık parametre olarak geçiliyor
  final int rssiValue;
  final String studentId;

  const CameraScreen({
    super.key,
    required this.rssiValue,
    required this.studentId,
  });

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
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
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
      final XFile image = await _controller!.takePicture();
      print("📸 Fotoğraf çekildi: ${image.path}");

      // ✅ DÜZELTME: RSSI ve studentId artık doğru şekilde gönderiliyor
      final result = await _apiService.verifyAttendance(
        imagePath: image.path,
        studentId: widget.studentId,
        rssi: widget.rssiValue,
      );

      if (mounted) {
        _showResultDialog(result['success'] as bool, result['mesaj'] as String);
      }
    } catch (e) {
      print("❌ Fotoğraf işleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf çekilirken bir hata oluştu.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showResultDialog(bool isSuccess, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          isSuccess ? "✅ Yoklama Başarılı" : "❌ Eşleşme Başarısız",
          style: TextStyle(
            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                Navigator.pop(context); // Kamera ekranını kapat
                Navigator.pop(context); // Dashboard'a dön
              }
            },
            child: const Text("Tamam",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
        title: const Text("Yüz Tanıma", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          // RSSI bilgisi üstte gösteriliyor
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "📶 RSSI: ${widget.rssiValue} dBm",
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Yüz hizalama halkası
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withOpacity(0.8), width: 3),
              ),
            ),
          ),
          // Fotoğraf çekme butonu
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _isProcessing
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.blueAccent),
                        SizedBox(height: 12),
                        Text("Yüz analiz ediliyor...",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : FloatingActionButton.extended(
                      onPressed: _takePictureAndVerify,
                      backgroundColor: Colors.blueAccent,
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                      label: const Text("Yoklama Ver",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
