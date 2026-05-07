# Quiz Buzzer

Aplikasi bel kuis interaktif berbasis jaringan lokal (offline) yang dirancang untuk kebutuhan edukasi, kuis interaktif, maupun acara cerdas cermat. Sistem ini menggunakan arsitektur **Host-Client** di mana laptop juri bertindak sebagai server lokal, dan peserta kuis dapat terhubung secara instan menggunakan browser di HP mereka tanpa perlu menginstal aplikasi tambahan.

---

## 🚀 Fitur Utama

- **Offline 100% (Local Network):** Berjalan sepenuhnya di jaringan lokal tanpa memerlukan koneksi internet aktif.
- **Client Berbasis Web:** Peserta hanya perlu memindai QR Code atau mengetik alamat IP host di browser HP untuk masuk ke lobi kuis.
- **Dashboard Juri (Host UI):** Kontrol penuh untuk memulai ronde baru, mereset bel, mengunci pemenang bel tercepat, serta melihat urutan skor.
- **Fitur Kick Player:** Host dapat mengeluarkan pemain yang tidak sah secara langsung dari daftar lobi peserta.
- **Deteksi Jaringan Otomatis:** Menampilkan alamat IP host aktif dan membuat QR Code secara dinamis untuk memudahkan koneksi peserta.
- **Efek Suara & Visual:** Dilengkapi dengan timer countdown yang stabil dan efek confetti animasi saat pemenang bel terkunci.

---

## 🛠️ Persyaratan Sistem

- **Sistem Operasi Host:** Windows, macOS, atau Linux (untuk menjalankan aplikasi Juri).
- **Client (Peserta):** Perangkat apa pun (Android, iOS, laptop) yang memiliki web browser modern (Chrome, Safari, Edge).
- **Jaringan:** Seluruh perangkat harus terhubung dalam satu jaringan lokal yang sama (Wi-Fi atau Hotspot pribadi).

---

## 🏃 Cara Menjalankan Proyek (Development)

1. Pastikan Anda telah menginstal **Flutter SDK** di komputer Anda.
2. Clone repositori ini dan masuk ke direktori proyek:
   ```bash
   git clone https://github.com/emRival/quizbuzzer.git
   cd quizbuzzer
   ```
3. Unduh dependensi proyek:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi Host/Juri:
   - **macOS:** `flutter run -d macos`
   - **Windows:** `flutter run -d windows`
   - **Android:** `flutter run -d android`

---

## 📶 Panduan Koneksi & Pemecahan Masalah (Troubleshooting)

Agar HP peserta dapat terhubung ke laptop Host, pastikan hal-hal berikut terpenuhi:

### 1. Masalah AP Isolation (Isolasi Klien) pada Wi-Fi Publik
Banyak jaringan Wi-Fi sekolah, kantor, atau tempat umum mengaktifkan fitur keamanan **AP Isolation (Access Point Isolation)** yang memblokir komunikasi antar-perangkat di satu Wi-Fi.
- **Solusi Terbaik & Tercepat:** Aktifkan **Hotspot Pribadi (Personal Hotspot)** pada salah satu HP, hubungkan laptop Mac/Windows Anda ke Hotspot tersebut, lalu biarkan HP peserta terhubung ke Hotspot yang sama. Ini menjamin komunikasi langsung (*peer-to-peer*) berjalan sukses 100%.

### 2. Keamanan Jaringan Lokal macOS Sequoia
Pada macOS Sequoia, aplikasi membutuhkan izin manual untuk mengakses jaringan lokal.
- Proyek ini telah dilengkapi konfigurasi `NSLocalNetworkUsageDescription` di file `Info.plist`. Pastikan untuk memilih **Allow (Izinkan)** saat aplikasi meminta akses Jaringan Lokal saat pertama kali dibuka dari folder `/Applications`.

---

## 📦 Panduan Kompilasi Rilis Resmi (Komputer Lokal)

Gunakan perintah berikut untuk men-compile aplikasi ke versi rilis produksi final secara lokal:

- **Android (APK):**
  ```bash
  flutter build apk --release
  ```
- **macOS (App Bundle & DMG):**
  ```bash
  flutter build macos --release
  ```
- **Windows (Executable):**
  ```bash
  flutter build windows --release
  ```

---

## 🤖 Rilis Otomatis Multi-Platform (GitHub Actions)

Proyek ini telah dilengkapi dengan sistem otomatisasi **GitHub Actions** (`.github/workflows/release.yml`). Anda dapat membuat file installer untuk **Android, macOS, dan Windows sekaligus** secara otomatis tanpa perlu melakukan kompilasi manual di masing-masing perangkat:

1. Buat versi tag baru di Git dan push ke GitHub (misal: `v1.0.0`):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Server GitHub akan otomatis menjalankan proses build secara paralel dan mengunggah hasilnya (`.apk`, `.dmg`, `.zip` Windows) langsung ke halaman **Releases** repositori GitHub Anda.
