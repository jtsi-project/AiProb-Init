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
echo "Akses: Buka browser Anda dan kunjungi [http://127.0.0.1:5000](http://127.0.0.1:5000)"
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
    # Kita tidak bisa menjalankan runner.sh dari shell ini karena init.sh sudah dimatikan
    # Tapi kita bisa memanggilnya secara langsung
    ./runner.sh
fi

# Nonaktifkan Venv (Ini hanya formalitas, karena init.sh sudah menjalankan deactivate)
deactivate
