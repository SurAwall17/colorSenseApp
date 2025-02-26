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


app = Flask(__name__)

# Fungsi untuk mengonversi RGB ke HEX
def rgb_to_hex(rgb_color):
    return "#{:02x}{:02x}{:02x}".format(int(rgb_color[0]), int(rgb_color[1]), int(rgb_color[2]))

############### ALGORITMA K-MEANS CLUSTERING ####################
@app.route('/analyze', methods=['POST'])
def analyze_image():
    file = request.files['image']
    img = cv2.imdecode(np.fromstring(file.read(), np.uint8), cv2.IMREAD_COLOR)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    # Mengubah ukuran gambar untuk mempercepat proses
    image = resize_image(img)
    
    # Melakukan sampling piksel untuk mempercepat K-Means
    sampled_pixels = sample_pixels(image)

    # Tentukan jumlah cluster
    optimal_k = find_best_k_using_silhouette(sampled_pixels, max_k=6)
    print(f"k optimal yang terdeteksi: {optimal_k}")

    # Analisis warna menggunakan K-Means
    reshaped_image = image.reshape((-1, 3))
    kmeans = KMeans(n_clusters=optimal_k, random_state=42)
    kmeans.fit(reshaped_image)

    colors = kmeans.cluster_centers_
    labels = kmeans.labels_
    label_counts = Counter(labels)

    total_count = sum(label_counts.values())
    color_percentages = {rgb_to_hex(colors[i]): count / total_count for i, count in label_counts.items()}

    return jsonify(color_percentages)

# Fungsi untuk mengubah ukuran gambar
def resize_image(image, max_size=200):
    height, width = image.shape[:2]
    if max(height, width) > max_size:
        scaling_factor = max_size / max(height, width)
        image = cv2.resize(image, (int(width * scaling_factor), int(height * scaling_factor)))
    return image

# Fungsi untuk sampling piksel
def sample_pixels(image, sample_size=2000):
    reshaped_image = image.reshape((-1, 3))
    if reshaped_image.shape[0] > sample_size:
        indices = np.random.choice(reshaped_image.shape[0], sample_size, replace=False)
        reshaped_image = reshaped_image[indices]
    return reshaped_image

# Fungsi untuk menentukan nilai k terbaik berdasarkan Silhouette Score
def find_best_k_using_silhouette(image, max_k=10):
    best_k = 2
    best_score = -1

    for k in range(2, max_k + 1):
        kmeans = KMeans(n_clusters=k, random_state=42)
        labels = kmeans.fit_predict(image)
        score = silhouette_score(image, labels)

        print(f"k={k}, Silhouette Score={score:.4f}")
        if score > best_score:
            best_k = k
            best_score = score

    print(f"Nilai k terbaik berdasarkan Silhouette Score adalah {best_k} dengan skor {best_score:.4f}")
    return best_k

############### ALGORITMA C-BF ####################
# Membaca dataset dari CSV
df = pd.read_csv('DataSet_Warna.csv', sep=';')
df['deskripsi'] = df['Mood'] + ' ' + df['Tema'] + ' ' + df['Suasana'] + ' ' + df['Kontras']
# Fungsi untuk rekomendasi warna
def rekomendasi_warna(mood_input, tema_input, suasana_input, kontras_input):
    input_deskripsi = f"{mood_input} {tema_input} {suasana_input} {kontras_input}"
    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(df['deskripsi'].tolist() + [input_deskripsi])
    cosine_similarities = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1])
    similar_indices = cosine_similarities.argsort()[0][-5:][::-1]
    recommended_colors = df.iloc[similar_indices][['Nama Warna', 'Kode Warna']]
    return recommended_colors.to_dict(orient='records')

# Route untuk API rekomendasi warna
@app.route('/rekomendasi', methods=['POST'])
def rekomendasi():
    data = request.get_json()
    rekomendasi = rekomendasi_warna(
        data['mood'], data['tema'], data['suasana'], data['kontras']
    )
    return jsonify(rekomendasi)

if __name__ == "__main__":
    # app.run(host='0.0.0.0', port=5000)
    app.run()
