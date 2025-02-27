from flask import Flask, request, jsonify
import cv2
import numpy as np
from sklearn.cluster import KMeans
from collections import Counter
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import matplotlib.pyplot as plt
from sklearn.metrics import silhouette_score

# Inisialisasi aplikasi Flask
app = Flask(__name__)

# Fungsi untuk mengonversi warna RGB ke format HEX
def rgb_to_hex(rgb_color):
    return "#{:02x}{:02x}{:02x}".format(int(rgb_color[0]), int(rgb_color[1]), int(rgb_color[2]))

############### ALGORITMA K-MEANS CLUSTERING ####################
@app.route('/analyze', methods=['POST'])  # Endpoint untuk analisis warna dari gambar

def analyze_image():
    file = request.files['image']  # Mengambil file gambar dari request
    img = cv2.imdecode(np.fromstring(file.read(), np.uint8), cv2.IMREAD_COLOR)  # Membaca gambar dalam format OpenCV
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)  # Mengubah format BGR ke RGB

    # Mengubah ukuran gambar untuk mempercepat proses analisis
    image = resize_image(img)
    
    # Melakukan sampling piksel agar pemrosesan lebih cepat (mengurangi jumlah data yang diproses)
    sampled_pixels = sample_pixels(image)

    # Menentukan jumlah cluster optimal menggunakan Silhouette Score
    optimal_k = find_best_k_using_silhouette(sampled_pixels, max_k=6)
    print(f"k optimal yang terdeteksi: {optimal_k}")

    # Melakukan clustering warna menggunakan K-Means
    reshaped_image = image.reshape((-1, 3))  # Mengubah bentuk gambar menjadi array 2D
    kmeans = KMeans(n_clusters=optimal_k, random_state=42)  # Inisialisasi model K-Means
    kmeans.fit(reshaped_image)  # Melatih model dengan data warna gambar

    colors = kmeans.cluster_centers_  # Mendapatkan warna hasil clustering
    labels = kmeans.labels_  # Mendapatkan label hasil clustering untuk setiap piksel
    label_counts = Counter(labels)  # Menghitung jumlah kemunculan setiap warna

    total_count = sum(label_counts.values())  # Total piksel yang dianalisis
    color_percentages = {rgb_to_hex(colors[i]): count / total_count for i, count in label_counts.items()}  # Menghitung persentase tiap warna

    return jsonify(color_percentages)  # Mengembalikan hasil dalam format JSON

# Fungsi untuk mengubah ukuran gambar agar analisis lebih cepat
def resize_image(image, max_size=200):
    height, width = image.shape[:2]  # Mendapatkan dimensi gambar
    if max(height, width) > max_size:  # Jika dimensi gambar lebih besar dari batas maksimal
        scaling_factor = max_size / max(height, width)  # Menghitung faktor skala
        image = cv2.resize(image, (int(width * scaling_factor), int(height * scaling_factor)))  # Mengubah ukuran gambar
    return image  # Mengembalikan gambar yang telah diubah ukurannya

# Fungsi untuk mengambil sampel piksel dari gambar
def sample_pixels(image, sample_size=2000):
    reshaped_image = image.reshape((-1, 3))  # Mengubah gambar menjadi array 2D
    if reshaped_image.shape[0] > sample_size:  # Jika jumlah piksel lebih besar dari sample_size
        indices = np.random.choice(reshaped_image.shape[0], sample_size, replace=False)  # Memilih sejumlah piksel secara acak
        reshaped_image = reshaped_image[indices]  # Mengambil piksel yang dipilih
    return reshaped_image  # Mengembalikan sampel piksel

# Fungsi untuk menentukan nilai k terbaik berdasarkan Silhouette Score
def find_best_k_using_silhouette(image, max_k=10):
    best_k = 2  # Inisialisasi nilai k minimal
    best_score = -1  # Inisialisasi nilai score

    for k in range(2, max_k + 1):  # Iterasi mencari k terbaik
        kmeans = KMeans(n_clusters=k, random_state=42)  # Inisialisasi model K-Means dengan k yang sedang diuji
        labels = kmeans.fit_predict(image)  # Melakukan clustering dan mendapatkan label
        score = silhouette_score(image, labels)  # Menghitung Silhouette Score

        print(f"k={k}, Silhouette Score={score:.4f}")  # Menampilkan hasil Silhouette Score untuk setiap k
        if score > best_score:  # Jika score lebih baik dari sebelumnya
            best_k = k  # Simpan nilai k terbaik
            best_score = score  # Simpan nilai score terbaik

    print(f"Nilai k terbaik berdasarkan Silhouette Score adalah {best_k} dengan skor {best_score:.4f}")  # Menampilkan hasil akhir
    return best_k  # Mengembalikan nilai k terbaik

############### ALGORITMA C-BF ####################
# Membaca dataset dari CSV untuk rekomendasi warna
df = pd.read_csv('DataSet_Warna.csv', sep=';')  # Membaca dataset warna
# Menggabungkan kolom deskripsi untuk analisis teks
df['deskripsi'] = df['Mood'] + ' ' + df['Tema'] + ' ' + df['Suasana'] + ' ' + df['Kontras']

# Fungsi untuk rekomendasi warna berdasarkan deskripsi
def rekomendasi_warna(mood_input, tema_input, suasana_input, kontras_input):
    input_deskripsi = f"{mood_input} {tema_input} {suasana_input} {kontras_input}"  # Gabungkan input pengguna
    vectorizer = TfidfVectorizer()  # Inisialisasi TF-IDF
    tfidf_matrix = vectorizer.fit_transform(df['deskripsi'].tolist() + [input_deskripsi])  # Transformasi teks ke vektor
    cosine_similarities = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1])  # Menghitung kesamaan kosinus
    similar_indices = cosine_similarities.argsort()[0][-5:][::-1]  # Mengambil 5 warna dengan kesamaan tertinggi
    recommended_colors = df.iloc[similar_indices][['Nama Warna', 'Kode Warna']]  # Mendapatkan warna rekomendasi
    return recommended_colors.to_dict(orient='records')  # Mengembalikan hasil sebagai dictionary

# Route untuk API rekomendasi warna
@app.route('/rekomendasi', methods=['POST'])  # Endpoint untuk rekomendasi warna
def rekomendasi():
    data = request.get_json()  # Mendapatkan data dari request JSON
    rekomendasi = rekomendasi_warna(
        data['mood'], data['tema'], data['suasana'], data['kontras']  # Mengambil input pengguna
    )
    return jsonify(rekomendasi)  # Mengembalikan hasil dalam format JSON

# Menjalankan aplikasi Flask
if __name__ == "__main__":
    app.run()  # Menjalankan server Flask
