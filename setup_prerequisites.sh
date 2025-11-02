#!/bin/bash
# Part 1: Pre-check, instalasi sistem, VENV, dan PIP.

set -e

# Variabel Global (Harus di-export agar dapat diakses oleh script Python dan Bash selanjutnya)
export VENV_NAME=".venv_aiprob"
export GITHUB_REPO_PATH="jtsi-project/AiProb-Version"

# --- Pemeriksaan Lingkungan & Tools ---
if [ -n "$PREFIX" ]; then
    INSTALL_CMD="pkg install -y"
    SYS_DEPS="python python-pip build-essential git"
    export PYTHON_BIN="python"
    PKG_UPDATE="pkg update -y"
else
    INSTALL_CMD="sudo apt-get install -y"
    SYS_DEPS="python3 python3-venv python3-pip build-essential git"
    export PYTHON_BIN="python3"
    PKG_UPDATE="sudo apt-get update -y"
fi

echo "[1.1] Memastikan Kebutuhan Sistem..."
NEEDS_INSTALL=0
if ! command -v $PYTHON_BIN &> /dev/null; then NEEDS_INSTALL=1; fi
if ! command -v git &> /dev/null; then NEEDS_INSTALL=1; fi

if [ $NEEDS_INSTALL -eq 1 ]; then
    echo "  -> Menginstal dependensi: $SYS_DEPS"
    $PKG_UPDATE
    $INSTALL_CMD $SYS_DEPS || { echo "ERROR: Gagal menginstal dependensi sistem."; exit 1; }
else
    echo "✅ Tools dasar (Python, Git) ditemukan."
fi

echo "[1.2] Menyiapkan Lingkungan Virtual ($VENV_NAME)..."
$PYTHON_BIN -m venv $VENV_NAME || { echo "ERROR: Gagal membuat lingkungan virtual!"; exit 1; }

echo "[1.3] Menginstal Dependensi Python..."
# requirements.txt sudah diunduh oleh init.sh
# Di sini pip akan dijalankan dari VENV karena init.sh sudah menjalankan '. .venv_aiprob/bin/activate'
pip install -r requirements.txt || { echo "ERROR: Gagal menginstal dependensi Python!"; exit 1; }

echo "✅ FASE 1 SELESAI."
