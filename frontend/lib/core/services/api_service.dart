import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ DÜZELTME: Emülatör için 10.0.2.2, gerçek telefon için bilgisayarının yerel IP'si
  // Gerçek telefon testi için: "http://192.168.X.X:8000" şeklinde değiştir
  static const String baseUrl = "http://10.0.2.2:8000";

  /// Çekilen fotoğrafı ve RSSI değerini backend'e göndererek yoklama doğrular.
  Future<Map<String, dynamic>> verifyAttendance({
    required String imagePath,
    required String studentId,
    required int rssi, // ✅ DÜZELTME: RSSI artık parametre olarak alınıyor
  }) async {
    try {
      // ✅ DÜZELTME: Endpoint ve alan adları backend ile eşleştirildi
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/yoklama-kontrol/'),
      );

      // Backend'in beklediği form alanları
      request.fields['student_id'] = studentId;
      request.fields['mobil_olculen_rssi'] = rssi.toString();

      // Fotoğraf dosyası — backend "file" adıyla bekliyor
      var file = await http.MultipartFile.fromPath('file', imagePath);
      request.files.add(file);

      print("🚀 Yoklama isteği gönderiliyor... Öğrenci: $studentId, RSSI: $rssi");

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Sunucu Cevap Kodu: ${response.statusCode}");
      print("📥 Sunucu Gövdesi: ${response.body}");

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "mesaj": data['mesaj'] ?? "Yoklama başarılı!"};
      } else {
        return {"success": false, "mesaj": data['mesaj'] ?? "Yoklama başarısız."};
      }
    } on SocketException {
      print("❌ Bağlantı Hatası: Sunucuya ulaşılamıyor.");
      return {"success": false, "mesaj": "Sunucuya bağlanılamadı. IP adresini ve sunucunun çalıştığını kontrol edin."};
    } catch (e) {
      print("❌ API Hatası: $e");
      return {"success": false, "mesaj": "Beklenmeyen bir hata oluştu: $e"};
    }
  }

  /// Öğrencinin referans fotoğrafını sisteme kaydeder.
  Future<Map<String, dynamic>> registerStudent({
    required String studentId,
    required String imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ogrenci-kaydet/'),
      );
      request.fields['ogrenci_id'] = studentId;
      var file = await http.MultipartFile.fromPath('foto', imagePath);
      request.files.add(file);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      return {
        "success": response.statusCode == 200,
        "mesaj": data['mesaj'] ?? "İşlem tamamlandı."
      };
    } catch (e) {
      return {"success": false, "mesaj": "Kayıt hatası: $e"};
    }
  }
}
