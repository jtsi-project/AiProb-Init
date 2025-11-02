#!/bin/bash
# Part 3: UX akhir dan menu interaktif.

# Ambil CORE_VERSION dari argumen pertama
CORE_VERSION=$1
VENV_NAME=".venv_aiprob"

# Hentikan jika ada error
set -e

echo "-------------------------------------------------"
echo "✅ INSTALASI CORE SELESAI TOTAL! Program Siap Dioperasikan."
echo "-------------------------------------------------"
echo ""
echo "🔥 PANDUAN PENGOPERASIAN AiProb v$CORE_VERSION 🔥"
echo "-------------------------------------------------"
echo "Langkah 1: Menjalankan Server"
echo "Akses: Jalankan skrip runner yang telah disiapkan."
echo "   \$ ./runner.sh"
echo ""
echo "Langkah 2: Setup Awal (Hanya sekali)"
echo "Akses: Buka browser Anda dan kunjungi http://127.0.0.1:5000"
echo "Aksi: Buat akun Admin dan masukkan Kunci API Gemini Anda."
echo ""
echo "Langkah 3: Penggunaan Normal"
echo "Akses: Login sebagai Admin (👑) untuk pengaturan dan Logs, atau User (💬) untuk chat AI."
echo ""
echo "Langkah 4: Menghentikan Server"
echo "Aksi: Di terminal server berjalan, tekan Ctrl + C. Lingkungan akan dinonaktifkan."
echo "-------------------------------------------------"

# Menampilkan opsi interaktif baru
echo "\n--- OPSI PASCA-INSTALASI ---"
echo "1. Jalankan AiProb sekarang (./runner.sh)"
echo "2. Keluar (Lakukan secara manual nanti)"
read -p "Pilih opsi [1/2]: " POST_INSTALL_CHOICE

if [ "$POST_INSTALL_CHOICE" == "1" ]; then
    echo "Memulai AiProb..."
    
    # 1. Pastikan Izin Eksekusi
    chmod +x runner.sh 
    
    # 2. **PERBAIKAN KRITIS: Hapus Carriage Return (CR)**
    # Ini mengatasi masalah di mana file yang ditulis Python memiliki karakter aneh (404)
    if command -v dos2unix &> /dev/null; then
        dos2unix runner.sh
    else
        # Fallback menggunakan 'tr' (lebih universal)
        tr -d '\r' < runner.sh > runner.sh.tmp && mv runner.sh.tmp runner.sh
    fi
    
    # 3. Jalankan runner.sh di shell baru yang bersih
    exec bash ./runner.sh
    
    # exec akan menggantikan proses ini. Jika gagal, pesan di bawah muncul:
    echo "❌ ERROR: Gagal memulai runner.sh. Cek runner.sh"
fi

# Nonaktifkan Venv (Ini hanya formalitas)
deactivate 
