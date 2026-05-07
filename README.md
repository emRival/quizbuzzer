<p align="center">
  <img src="assets/logo.png" width="180" alt="Quiz Buzzer Logo" style="border-radius: 20%;">
</p>

<h1 align="center">Quiz Buzzer</h1>

<p align="center">
  Aplikasi bel kuis interaktif luring (offline) berbasis jaringan lokal yang menghubungkan juri dan peserta secara instan melalui protokol WebSocket.
</p>

<p align="center">
  <a href="https://github.com/emRival/quizbuzzer/releases/latest/download/Quiz-Buzzer-Android.apk">
    <img src="https://img.shields.io/badge/Download-Android%20%28APK%29-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Download Android APK">
  </a>
  <a href="https://github.com/emRival/quizbuzzer/releases/latest/download/Quiz-Buzzer-MacOS.dmg">
    <img src="https://img.shields.io/badge/Download-macOS%20%28DMG%29-000000?style=for-the-badge&logo=apple&logoColor=white" alt="Download macOS DMG">
  </a>
  <a href="https://github.com/emRival/quizbuzzer/releases/latest/download/Quiz-Buzzer-Windows.zip">
    <img src="https://img.shields.io/badge/Download-Windows%20%28ZIP%29-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Download Windows ZIP">
  </a>
</p>

---

## 📋 Deskripsi Proyek

**Quiz Buzzer** adalah solusi penyelenggaraan kuis interaktif dan cerdas cermat yang dapat berjalan sepenuhnya tanpa koneksi internet. Menggunakan model arsitektur **Host-Client**, aplikasi juri bertindak sebagai pusat server lokal (Host) yang menyebarkan jaringan luring, sementara para peserta dapat terhubung langsung (Client) hanya dengan membuka peramban web (*web browser*) di HP masing-masing melalui alamat IP host atau pemindaian kode QR.

---

## ✨ Fitur Unggulan

- **Konektivitas Mandiri (100% Offline):** Menghubungkan perangkat juri dan HP peserta secara luring melalui infrastruktur jaringan lokal tanpa memerlukan paket data seluler atau internet.
- **Client Tanpa Instalasi:** Peserta dapat langsung berkompetisi cukup dengan membuka browser bawaan HP mereka (Chrome, Safari, Edge, dll.).
- **Dashboard Juri Komprehensif:** Antarmuka kontrol penuh untuk memulai ronde, melakukan reset bel kuis secara berkala, mengunci pemenang tercepat, serta memantau perolehan skor peserta secara langsung.
- **Sistem Keamanan Keanggotaan (Kick Player):** Memberikan wewenang penuh kepada Juri untuk mengeluarkan peserta yang tidak sah dari lobi kuis melalui satu klik mudah.
- **Navigasi IP & QR Code Dinamis:** Membaca alamat IP aktif Host secara otomatis dan menampilkannya dalam format teks dan QR Code siap pindai.
- **Pengoptimalan Kinerja Jaringan:** Dilengkapi pencegah tabrakan interval timer (*overlapping countdown*) untuk menjaga stabilitas lalu lintas data WebSocket selama pertandingan berlangsung.

---

## 💻 Spesifikasi Sistem

- **Sisi Host (Aplikasi Juri):** Berjalan pada sistem operasi macOS, Windows, atau Linux.
- **Sisi Client (Aplikasi Peserta):** Kompatibel dengan semua perangkat pintar (Android, iOS, iPadOS, Laptop) yang memiliki peramban web modern.
- **Persyaratan Jaringan:** Seluruh perangkat wajib berada di dalam satu subnet jaringan lokal yang sama (Wi-Fi lokal atau tethering Hotspot Pribadi).

---

## 🚀 Panduan Memulai Cepat (Development)

1. Pastikan lingkungan pengembangan Anda telah terinstal **Flutter SDK**.
2. Dapatkan salinan repositori dan masuk ke folder proyek:
   ```bash
   git clone https://github.com/emRival/quizbuzzer.git
   cd quizbuzzer
   ```
3. Pasang semua dependensi Flutter yang dibutuhkan:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi Host sesuai platform target:
   - **macOS:** `flutter run -d macos`
   - **Windows:** `flutter run -d windows`

---

## 📶 Pemecahan Masalah Koneksi (Troubleshooting)

### 1. Hambatan AP Isolation pada Router Wi-Fi
Beberapa router Wi-Fi publik (di sekolah, kantor, atau kafe) mengaktifkan fitur *AP Isolation* yang membatasi perangkat agar tidak dapat saling berkomunikasi langsung.
- **Solusi Praktis:** Aktifkan **Hotspot Pribadi** pada perangkat HP, sambungkan Wi-Fi laptop Host ke Hotspot tersebut, dan arahkan HP peserta untuk terhubung ke jaringan Hotspot yang sama. Langkah ini membebaskan seluruh lalu lintas data dari pembatasan router eksternal secara instan.

### 2. Izin Keamanan Jaringan Lokal macOS Sequoia
macOS Sequoia menerapkan pengawasan ketat terhadap port jaringan lokal.
- Aplikasi ini telah disematkan deskripsi keamanan `NSLocalNetworkUsageDescription`. Pastikan Anda memberikan persetujuan akses (*Allow/Izinkan*) pada kotak dialog popup yang muncul saat pertama kali membuka aplikasi dari folder `/Applications`.

---

## 📦 Kompilasi Berkas Rilis Resmi

Untuk membangun berkas rilis final secara mandiri pada perangkat komputer lokal Anda:

- **Android (APK):**
  ```bash
  flutter build apk --release
  ```
- **macOS (App Bundle / DMG):**
  ```bash
  flutter build macos --release
  ```
- **Windows (Executable):**
  ```bash
  flutter build windows --release
  ```
