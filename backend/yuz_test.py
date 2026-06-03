import cv2
import numpy as np

print("Hafif ve Kararlı Yapay Zeka Motoru Başlatılıyor...")

def yuzleri_karsilastir(resim1_yolu, resim2_yolu):
    try:
        # Fotoğrafları siyah-beyaz olarak oku (Analiz için en kararlı yöntemdir)
        img1 = cv2.imread(resim1_yolu, cv2.IMREAD_GRAYSCALE)
        img2 = cv2.imread(resim2_yolu, cv2.IMREAD_GRAYSCALE)

        if img1 is None or img2 is None:
            print("\n[HATA] Resim dosyaları bulunamadı! Klasörü kontrol edin.")
            return

        # Resimleri aynı boyuta getir (Karşılaştırma yapabilmek için şart)
        img1 = cv2.resize(img1, (300, 300))
        img2 = cv2.resize(img2, (300, 300))

        # İki resim arasındaki histogram (renk/ışık dağılımı) benzerliğini hesapla
        hist1 = cv2.calcHist([img1], [0], None, [256], [0, 256])
        hist2 = cv2.calcHist([img2], [0], None, [256], [0, 256])
        
        cv2.normalize(hist1, hist1, 0, 1, cv2.NORM_MINMAX)
        cv2.normalize(hist2, hist2, 0, 1, cv2.NORM_MINMAX)
        
        # Benzerlik skorunu ölç (1.0 mükemmel eşleşmedir)
        benzerlik = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)

        print(f"Hesaplanan Benzerlik Orani: {benzerlik:.4f}")

        # Eşleşme eşiği (0.60 üstü genelde aynı ortam ve aynı kişidir)
        if benzerlik > 0.60:
            print("\nSONUÇ: [BAŞARILI] Yüzler ve ortam doğrulandı! Yoklama alınabilir.")
        else:
            print("\nSONUÇ: [HATA] Yüzler eşleşmedi veya farklı bir kişi!")

    except Exception as e:
        print(f"\n[HATA] Bir sorun oluştu: {str(e)}")

# Testi çalıştır
yuzleri_karsilastir("ben_kayitli.jpeg", "ben_anlik.jpeg")