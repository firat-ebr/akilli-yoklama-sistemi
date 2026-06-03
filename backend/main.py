from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
import cv2
import numpy as np
import shutil
import os
import glob

app = FastAPI(title="Akıllı Yoklama Sistemi API - Tersine RSSI Sürümü")

UPLOAD_DIR = "gecici_resimler"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# OpenCV Kararlı Yüz Tanıma Bileşenleri
cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
face_cascade = cv2.CascadeClassifier(cascade_path)
recognizer = cv2.face.LBPHFaceRecognizer_create()

def yuz_krip_ve_hazirla(resim_yolu):
    img = cv2.imread(resim_yolu)
    if img is None: return None
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=3, minSize=(30, 30))
    if len(faces) == 0:
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=1)
        if len(faces) == 0: return None
    x, y, w, h = faces[0]
    return cv2.resize(gray[y:y+h, x:x+w], (200, 200))

@app.get("/")
def ana_sayfa():
    return {"mesaj": "Mobil RSSI Tabanlı Yoklama Sunucusu Aktif!"}

@app.post("/yoklama-kontrol/")
async def yoklama_kontrol(
    ogrenci_id: str = Form(...),
    mobil_olculen_rssi: int = Form(...),  # Mobil uygulamanın ölçüp gönderdiği sinyal gücü (Örn: -60)
    anlik_foto: UploadFile = File(...)
):
    # ==========================================
    # KONTROL 1: BLUETOOTH RSSI SINIRI
    # ==========================================
    # Sınıf içi mesafe sınırı: -75 dBm (0'a yaklaştıkça yakın, -90'a gittikçe uzaktır)
    ESIK_RSSI = -75 
    
    if mobil_olculen_rssi < ESIK_RSSI:
        return JSONResponse(
            status_code=400,
            content={
                "durum": "BAŞARISIZ",
                "mesaj": f"Bluetooth sinyal gücü yetersiz! Sınıf dışında olduğunuz tespit edildi. (Ölçülen: {mobil_olculen_rssi} dBm)",
                "gerekli_en_az": f"{ESIK_RSSI} dBm"
            }
        )

    # ==========================================
    # KONTROL 2: YÜZ TANIMA SÜZGECİ
    # ==========================================
    gecici_anlik_yol = os.path.join(UPLOAD_DIR, f"anlik_{ogrenci_id}.jpeg")
    try:
        with open(gecici_anlik_yol, "wb") as buffer:
            shutil.copyfileobj(anlik_foto.file, buffer)

        # Sistemdeki kayıtlı öğrenci resmini bulur
        kayitli_dosya_listesi = glob.glob("ben_kayitli.*") + glob.glob("ben_firat.*")
        if not kayitli_dosya_listesi:
            return JSONResponse(status_code=444, content={"durum": "HATA", "mesaj": "Klasörde kayıtlı ana fotoğraf bulunamadı!"})
        
        kayitli_foto_yolu = kayitli_dosya_listesi[0]
        face1 = yuz_krip_ve_hazirla(kayitli_foto_yolu)
        face2 = yuz_krip_ve_hazirla(gecici_anlik_yol)

        if face1 is None or face2 is None:
            return JSONResponse(status_code=400, content={"durum": "HATA", "mesaj": "Fotoğraftan yüz analizi yapılamadı! Daha net bir fotoğraf yükleyin."})

        if os.path.exists(gecici_anlik_yol): os.remove(gecici_anlik_yol)

        # LBPH Yapay Zeka Karşılaştırması
        recognizer.train([face1], np.array([1]))
        label, distance = recognizer.predict(face2)
        
        if distance < 135.0:
            guven_yuzdesi = max(0, min(100, (1 - (distance / 135.0)) * 100))
            return {
                "durum": "BAŞARILI",
                "mesaj": "Fiziksel mesafe (RSSI) ve Yüz Tanıma doğrulamaları başarıyla geçildi. Yoklama alındı!",
                "dogrulanan_rssi": f"{mobil_olculen_rssi} dBm",
                "yuz_guven_yuzdesi": f"%{guven_yuzdesi:.2f}"
            }
        else:
            return JSONResponse(
                status_code=400,
                content={"durum": "BAŞARISIZ", "mesaj": "Sınıftasınız (RSSI Doğru) fakat yüz eşleşmesi başarısız!", "mesafe_skoru": f"{distance:.2f}"}
            )

    except Exception as e:
        if os.path.exists(gecici_anlik_yol): os.remove(gecici_anlik_yol)
        return JSONResponse(status_code=500, content={"durum": "HATA", "mesaj": f"Sistem hatası: {str(e)}"})