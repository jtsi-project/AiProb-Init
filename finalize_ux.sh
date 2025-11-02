import os
import sys
import subprocess

# Ambil versi dari argumen pertama
try:
    CORE_VERSION = sys.argv[1]
except IndexError:
    print("ERROR: Argumen CORE_VERSION hilang.")
    sys.exit(1)

# Ambil PATHS dari Environment Variables (diset di setup_prerequisites.sh)
PYTHON_BIN = os.environ.get('PYTHON_BIN', 'python3')
VENV_NAME = os.environ.get('VENV_NAME', '.venv_aiprob')

def run_ai_prob():
    # 1. Cleaning Runner.sh (Tetap lakukan cleaning di Python untuk kebersihan maksimal)
    try:
        with open('runner.sh', 'r') as f:
            content = f.read()
        # Hapus Carriage Returns (CR) yang menyebabkan masalah '404'
        clean_content = content.replace('\r', '') 
        with open('runner.sh', 'w') as f:
            f.write(clean_content)
        
        # 2. Pastikan Izin Eksekusi
        os.chmod('runner.sh', 0o755)

        # 3. Eksekusi runner.sh menggunakan subprocess (paling stabil)
        print("Memulai AiProb menggunakan subprocess...")
        # Kita menggunakan exec/bash agar runner.sh mengambil alih shell
        subprocess.call(["bash", "./runner.sh"]) 

    except Exception as e:
        print(f"❌ ERROR: Gagal menjalankan runner.sh dari Python: {e}")
        sys.exit(1)


# --- DISPLAY UX DAN MENU INTERAKTIF ---
def display_ux_and_menu():
    print("-------------------------------------------------")
    print("✅ INSTALASI CORE SELESAI TOTAL! Program Siap Dioperasikan.")
    print("-------------------------------------------------")
    print("\n🔥 PANDUAN PENGOPERASIAN AiProb v{} 🔥".format(CORE_VERSION))
    print("-------------------------------------------------")
    print("Langkah 1: Menjalankan Server")
    print("Akses: Jalankan skrip runner yang telah disiapkan.")
    print("   $ ./runner.sh")
    print("")
    print("Langkah 2: Setup Awal (Hanya sekali)")
    print("Akses: Buka browser Anda dan kunjungi http://127.0.0.1:5000")
    print("Aksi: Buat akun Admin dan masukkan Kunci API Gemini Anda.")
    print("-------------------------------------------------")

    # Menampilkan opsi interaktif baru
    print("\n--- OPSI PASCA-INSTALASI ---")
    print("1. Jalankan AiProb sekarang (./runner.sh)")
    print("2. Keluar (Lakukan secara manual nanti)")
    
    try:
        post_install_choice = input("Pilih opsi [1/2]: ")
    except EOFError:
        post_install_choice = '2' # Jika non-interaktif
    
    if post_install_choice == "1":
        run_ai_prob()


if __name__ == "__main__":
    display_ux_and_menu()
