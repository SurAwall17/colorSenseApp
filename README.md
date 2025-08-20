# 🎨 ColorSense

**ColorSense** adalah aplikasi mobile berbasis **Flutter** yang membantu pengguna mendeteksi warna secara **realtime** melalui kamera, menganalisis warna pada gambar, serta memberikan **rekomendasi warna** untuk desain grafis.  
Aplikasi ini dirancang khusus untuk mendukung pengguna umum dan desainer grafis agar lebih mudah dalam memilih warna.

---

## ✨ Fitur Utama

- 📸 **Deteksi Warna Realtime**
  - Menggunakan kamera dengan titik fokus di tengah layar untuk mendeteksi warna secara langsung.
  - Menampilkan kode warna dalam format **Hex** dan **RGB**.

- 🖼️ **Scan Warna dari Gambar**
  - Ambil gambar dari kamera atau galeri, lalu analisis warna dominan menggunakan **K-Means Clustering**.

- 🎨 **Rekomendasi Warna**
  - Rekomendasi warna berdasarkan dataset `DataSet_Warna.csv` dengan pendekatan **Content-Based Filtering (CBF)**.
  - Input: Mood, Tema, Suasana, Kontras, Popularitas, dan Gaya Desain.

- 🎛️ **Palet Warna Kustom**
  - Pengguna dapat membuat dan menyimpan palet warna sendiri untuk kebutuhan desain.

- 👤 **Autentikasi**
  - Fitur **register** dan **login** agar setiap pengguna memiliki palet dan preferensi warna masing-masing.

---

## 🛠️ Tech Stack

### Mobile
- [Flutter](https://flutter.dev/) (Dart)
- Kamera Realtime

### Backend
- [Flask](https://flask.palletsprojects.com/) (Python)
- Algoritma:
  - **K-Means Clustering** (deteksi warna pada gambar)
  - **Content-Based Filtering (CBF)** (rekomendasi warna)

### Dataset
- **`DataSet_Warna.csv`**
  - Atribut: `Nama Warna`, `Kode Warna`, `Mood`, `Tema`, `Suasana`, `Kontras`, `Popularitas`, `Kecerahan`, `Gaya Desain`.

### Database
- Firebase

---

## 🚀 Instalasi & Menjalankan

### 1. Clone Repository
```bash
git clone https://github.com/SurAwall17/colorSenseApp.git
cd colorsense
