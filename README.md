# 🌊 SiagaBanjir
### AI-Powered Community Flood Reporting & Monitoring Platform

**SiagaBanjir** adalah platform digital berbasis komunitas yang dirancang untuk membantu masyarakat melaporkan, memantau, dan memahami kondisi banjir melalui teknologi digital dan kecerdasan buatan (Artificial Intelligence).

SiagaBanjir mengintegrasikan aplikasi Android dan dashboard admin berbasis web untuk menghubungkan laporan masyarakat dengan proses pemantauan dan verifikasi. Dengan dukungan AI, sistem juga dikembangkan untuk membantu menganalisis informasi laporan banjir sehingga admin memperoleh informasi tambahan dalam proses peninjauan.

> **From Community Reports to AI-Assisted Flood Insights.**

---

## 🚀 Keunggulan Utama SiagaBanjir

### 1. 🤖 AI-Powered Flood Report Analysis

SiagaBanjir mengintegrasikan Gemini AI untuk membantu proses analisis laporan kondisi banjir.

Kemampuan analisis berbantuan AI dirancang untuk:
- Menganalisis informasi laporan banjir yang dikirimkan pengguna.
- Menghasilkan ringkasan kondisi berdasarkan informasi yang tersedia.
- Memberikan insight tambahan untuk membantu admin memahami laporan.
- Mendukung proses peninjauan laporan secara lebih terstruktur.

AI berfungsi sebagai alat bantu analisis, bukan pengganti verifikasi manusia atau keputusan resmi instansi kebencanaan.

### 2. 📍 Community-Based Flood Reporting

Masyarakat dapat berpartisipasi dalam menyampaikan informasi kondisi banjir melalui aplikasi Android.

Informasi laporan dapat mencakup:
- Lokasi kejadian.
- Dokumentasi foto.
- Ketinggian air.
- Deskripsi kondisi banjir.

### 3. 🗺️ Interactive Flood Map

Laporan kejadian dapat ditampilkan dalam peta digital sehingga persebaran informasi kondisi banjir lebih mudah dipahami.

### 4. 🛡️ Admin Verification System

Dashboard admin menyediakan fasilitas untuk:
- Memantau laporan yang masuk.
- Memeriksa detail dan dokumentasi laporan.
- Meninjau hasil analisis berbantuan AI.
- Melakukan verifikasi laporan.
- Memperbarui status laporan.

### 5. 📊 Integrated Monitoring Platform

SiagaBanjir menghubungkan aplikasi Android, layanan penyimpanan data, peta digital, dan dashboard admin dalam satu ekosistem.

---

## ✨ Fitur Sistem

| Fitur | Deskripsi |
|---|---|
| User Authentication | Autentikasi pengguna |
| Flood Reporting | Pengiriman laporan banjir |
| Photo Documentation | Dokumentasi foto kejadian |
| Location Mapping | Informasi lokasi laporan |
| Water Level Information | Informasi ketinggian air |
| Flood Map | Visualisasi persebaran laporan |
| AI Analysis | Analisis laporan berbantuan Gemini AI |
| Admin Dashboard | Pengelolaan laporan |
| Report Verification | Pemeriksaan dan verifikasi laporan |
| Report History | Riwayat laporan pengguna |

---

## 🏗️ Arsitektur Teknologi

SiagaBanjir dikembangkan menggunakan beberapa teknologi:

| Teknologi | Fungsi |
|---|---|
| Flutter | Aplikasi Android |
| Dart | Bahasa pemrograman mobile |
| Next.js | Dashboard admin |
| TypeScript | Pengembangan Admin Web |
| Firebase Authentication | Autentikasi pengguna |
| Cloud Firestore | Database laporan |
| Cloudinary | Penyimpanan dokumentasi foto |
| OpenStreetMap | Peta digital |
| Gemini API | Analisis laporan berbantuan AI |

### Gambaran Alur Sistem

```text
       MASYARAKAT
            |
            v
     SIAGABANJIR APP
         (Flutter)
            |
            v
      FIREBASE SYSTEM
            |
      +-----+------+
      |            |
      v            v
   DATABASE     PHOTO STORAGE
      |
      v
    ADMIN WEB
     (Next.js)
      |
      v
  GEMINI AI ANALYSIS
      |
      v
  INSIGHT & REVIEW
      |
      v
  ADMIN VERIFICATION
      |
      v
  VERIFIED REPORT
```

*Diagram merupakan gambaran konseptual alur sistem. Analisis AI dan verifikasi admin merupakan proses yang berbeda.*

---

## 📱 Platform

### Android Application
Digunakan masyarakat untuk mengirim laporan, melihat informasi lokasi, dan mengakses riwayat laporan.

### Admin Web Dashboard
Digunakan admin untuk mengelola laporan, memeriksa dokumentasi, melihat informasi analisis AI, dan melakukan verifikasi.

---

## ⚙️ Instalasi

### Clone Repository

```bash
git clone https://github.com/RiyanAditiya-sys/SiagaBanjir.git
cd SiagaBanjir
```

### Menjalankan Android Application

```bash
cd mobile
flutter pub get
flutter run
```

### Menjalankan Admin Web

Buka terminal baru:

```bash
cd admin-web
npm install
```

Siapkan konfigurasi environment sesuai kebutuhan proyek.

```env
GEMINI_API_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

Jalankan aplikasi:

```bash
npm run dev
```

Akses melalui:

```text
http://localhost:3000
```

---

## 🌍 Sustainable Development Goals (SDGs)

SiagaBanjir mendukung tujuan pembangunan berkelanjutan:

- **SDG 11 — Sustainable Cities and Communities:** Mendukung ketahanan masyarakat melalui penyampaian informasi kondisi banjir.
- **SDG 13 — Climate Action:** Mendorong pemanfaatan teknologi untuk mendukung kesiapsiagaan dan adaptasi terhadap risiko bencana.

---

## ⚠️ Disclaimer

SiagaBanjir merupakan platform pendukung pelaporan dan pemantauan informasi kondisi banjir berbasis komunitas.

Hasil analisis AI bersifat informatif dan tidak menggantikan pemeriksaan manusia. Laporan yang belum diverifikasi tidak dapat dianggap sebagai peringatan resmi bencana.

Masyarakat tetap perlu mengikuti informasi dan arahan dari BPBD serta instansi berwenang.

---

## 👥 Development Team

| Nama | NPM |
|---|---|
| Riyan Aditiya | 24312246 |
| Rizka Pirdiansyah | 24312220 |
| Maelani Putri | 24312189 |

**Universitas Teknokrat Indonesia — 2026**

---

## 💡 Project Vision

SiagaBanjir dikembangkan dengan visi menghadirkan ekosistem informasi banjir yang menggabungkan partisipasi masyarakat, pemetaan digital, pengelolaan laporan, dan kecerdasan buatan.

**SiagaBanjir — Smarter Insights, Stronger Community, Better Preparedness.**
