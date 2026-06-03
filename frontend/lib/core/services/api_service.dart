import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Bilgisayarınız aynı Wi-Fi'ye bağlıysa backend çalışan bilgisayarın yerel IP'sini yazmalısın.
  // Emülatör için varsayılan localhost IP'si: "10.0.0.2" veya gerçek telefon için bilgisayarının IP'si (örn: "192.168.1.35")
  static const String baseUrl = "http://10.0.2.2:8000";

  /// Çekilen fotoğrafı yüz tanıma için backend sunucusuna gönderir
  Future<bool> verifyAttendance({required String imagePath, required String studentId}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/attendance/verify'));

      // Form verilerini ekliyoruz (Arkadaşının backend modeline göre gerekirse güncellenebilir)
      request.fields['student_id'] = studentId;

      // Fotoğraf dosyasını ekliyoruz
      var file = await http.MultipartFile.fromPath('file', imagePath);
      request.files.add(file);

      print("🚀 Sunucuya istek gönderiliyor... URL: $baseUrl/attendance/verify");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Sunucu Cevap Kodu: ${response.statusCode}");
      print("📥 Sunucu Gövdesi: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // Arkadaşın geriye muhtemelen "success: true" veya benzeri bir eşleşme sonucu dönüyordur
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print("❌ API Hatası: $e");
      return false;
    }
  }
}