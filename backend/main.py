from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import cv2
import numpy as np
import shutil
import os
import glob

app = FastAPI(title="Akıllı Yoklama Sistemi API")

# ✅ DÜZELTME 1: CORS Middleware eklendi (Flutter mobil uygulama erişebilsin diye şart)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "gecici_resimler"
KAYITLI_DIR = "kayitli_resimler"  # ✅ DÜZELTME 2: Kayıtlı resimlerin klasörü sabit hale getirildi
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(KAYITLI_DIR, exist_ok=True)

# OpenCV Yüz Tanıma Bileşenleri
cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
face_cascade = cv2.CascadeClassifier(cascade_path)
recognizer = cv2.face.LBPHFaceRecognizer_create()


def yuz_kirp_ve_hazirla(resim_yolu):
    """Görüntüden yüz bölgesini kırpar ve yüz tanıma için hazırlar."""
    img = cv2.imread(resim_yolu)
    if img is None:
        return None
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=3, minSize=(30, 30))
    if len(faces) == 0:
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=1)
        if len(faces) == 0:
            return None
    x, y, w, h = faces[0]
    return cv2.resize(gray[y:y+h, x:x+w], (200, 200))


@app.get("/")
def ana_sayfa():
    return {"mesaj": "Akıllı Yoklama Sistemi API Aktif!", "versiyon": "2.0"}


# ✅ DÜZELTME 3: Öğrenci kayıt endpoint'i eklendi (daha önce yoktu!)
# Öğrencinin referans fotoğrafını kaydetmek için kullanılır
@app.post("/ogrenci-kaydet/")
async def ogrenci_kaydet(
    ogrenci_id: str = Form(...),
    foto: UploadFile = File(...)
):
    """Öğrencinin referans fotoğrafını sisteme kaydeder."""
    kayit_yolu = os.path.join(KAYITLI_DIR, f"{ogrenci_id}.jpeg")
    try:
        with open(kayit_yolu, "wb") as buffer:
            shutil.copyfileobj(foto.file, buffer)

        # Yüz algılanıp algılanmadığını kontrol et
        yuz = yuz_kirp_ve_hazirla(kayit_yolu)
        if yuz is None:
            os.remove(kayit_yolu)
            return JSONResponse(
                status_code=400,
                content={"durum": "HATA", "mesaj": "Fotoğrafta yüz algılanamadı! Net ve aydınlık bir fotoğraf yükleyin."}
            )

        return {"durum": "BAŞARILI", "mesaj": f"Öğrenci {ogrenci_id} başarıyla kaydedildi.", "ogrenci_id": ogrenci_id}

    except Exception as e:
        if os.path.exists(kayit_yolu):
            os.remove(kayit_yolu)
        return JSONResponse(status_code=500, content={"durum": "HATA", "mesaj": f"Kayıt hatası: {str(e)}"})


# ✅ DÜZELTME 4: Ana yoklama endpoint'i — Flutter'ın gönderdiği alan adları düzeltildi
# Flutter'da "student_id" ve "file" gönderiliyordu, backend "ogrenci_id" ve "anlik_foto" bekliyordu
@app.post("/yoklama-kontrol/")
async def yoklama_kontrol(
    student_id: str = Form(...),          # Flutter'daki alan adıyla eşleştirildi
    mobil_olculen_rssi: int = Form(...),
    file: UploadFile = File(...)           # Flutter'daki alan adıyla eşleştirildi
):
    """Bluetooth RSSI ve yüz tanıma ile yoklama doğrular."""

    # ==========================================
    # KONTROL 1: BLUETOOTH RSSI SINIRI
    # ==========================================
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
    gecici_yol = os.path.join(UPLOAD_DIR, f"anlik_{student_id}.jpeg")
    try:
        with open(gecici_yol, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # ✅ DÜZELTME 5: Kayıtlı fotoğraf artık sabit klasörden ogrenci_id ile aranıyor
        kayitli_yol = os.path.join(KAYITLI_DIR, f"{student_id}.jpeg")
        if not os.path.exists(kayitli_yol):
            return JSONResponse(
                status_code=404,
                content={"durum": "HATA", "mesaj": f"Öğrenci {student_id} için kayıtlı fotoğraf bulunamadı! Önce kayıt yaptırın."}
            )

        face1 = yuz_kirp_ve_hazirla(kayitli_yol)
        face2 = yuz_kirp_ve_hazirla(gecici_yol)

        if os.path.exists(gecici_yol):
            os.remove(gecici_yol)

        if face1 is None or face2 is None:
            return JSONResponse(
                status_code=400,
                content={"durum": "HATA", "mesaj": "Fotoğraftan yüz analizi yapılamadı! Daha net ve aydınlık bir fotoğraf çekin."}
            )

        # LBPH Yüz Tanıma Karşılaştırması
        recognizer.train([face1], np.array([1]))
        label, distance = recognizer.predict(face2)

        if distance < 135.0:
            guven_yuzdesi = max(0, min(100, (1 - (distance / 135.0)) * 100))
            # ✅ DÜZELTME 6: Flutter'ın beklediği "success" alanı eklendi
            return {
                "durum": "BAŞARILI",
                "success": True,
                "mesaj": "RSSI ve Yüz Tanıma doğrulamaları başarıyla geçildi. Yoklama alındı!",
                "dogrulanan_rssi": f"{mobil_olculen_rssi} dBm",
                "yuz_guven_yuzdesi": f"%{guven_yuzdesi:.2f}"
            }
        else:
            return JSONResponse(
                status_code=400,
                content={
                    "durum": "BAŞARISIZ",
                    "success": False,
                    "mesaj": "Sınıftasınız (RSSI Doğru) fakat yüz eşleşmesi başarısız!",
                    "mesafe_skoru": f"{distance:.2f}"
                }
            )

    except Exception as e:
        if os.path.exists(gecici_yol):
            os.remove(gecici_yol)
        return JSONResponse(status_code=500, content={"durum": "HATA", "mesaj": f"Sistem hatası: {str(e)}"})
