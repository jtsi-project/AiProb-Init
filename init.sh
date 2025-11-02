#!/bin/bash
# --- AiProb v7.2-rc CORE Installer (init.sh) ---
# FUNGSI: Otak Instalasi. Melakukan pre-check, venv, dan membuat app.py/HTML.
# Pengembang: Anjas Amar Pradana / JTSI

set -e

# --- KONFIGURASI CORE LOGIC ---
VENV_NAME=".venv_aiprob"
PYTHON_BIN="python3"
# PATH KE REPO VERSION (Digunakan oleh Python untuk Self-Update)
GITHUB_REPO_PATH="jtsi-project/AiProb-Version" 
CORE_VERSION="v7.2-rc"

# --- Header ---
echo "========================================================="
echo "== AiProb v$CORE_VERSION: Instalasi Core (JTSI) =="
echo "========================================================="
echo ""

# --- FASE 1: SHELL, ROOT & PRASYARAT CHECK ---
echo "--- [Pemeriksaan Lingkungan & Prasyarat] ---"

if [ -z "$BASH_VERSION" ]; then
    echo "⚠️ Peringatan Shell: Skrip ini dirancang untuk BASH. Disarankan menggunakan 'bash'."
fi

if [ "$(id -u)" = "0" ] && [ -z "$PREFIX" ]; then
    echo "🚨 Akses ROOT Terdeteksi! Program harus dijalankan sebagai user biasa untuk keamanan."
else
    echo "✅ Akses Non-Root/Termux terdeteksi. Lingkungan sesuai."
fi

# 3. Deteksi Lingkungan
if [ -n "$PREFIX" ]; then
    INSTALL_CMD="pkg install -y"
    SYS_DEPS="python python-pip build-essential git"
    PYTHON_BIN="python"
    PKG_UPDATE="pkg update -y"
else
    INSTALL_CMD="sudo apt-get install -y"
    SYS_DEPS="python3 python3-venv python3-pip build-essential git"
    PYTHON_BIN="python3"
    PKG_UPDATE="sudo apt-get update -y"
fi
echo ""

# --- FASE 1: PERINGATAN & CLEARING LAMA ---
echo "--- [Pembersihan Awal] ---"
if [ -f "app.py" ] || [ -f "jtsi_aiprob.db" ] || [ -d "$VENV_NAME" ]; then
    echo "  -> Instalasi lama terdeteksi."
    read -p "  -> Hapus instalasi lama dan mulai setup baru? [Y/n] " PERSETUJUAN
    if [ "$PERSETUJUAN" != "y" ] && [ "$PERSETUJUAN" != "Y" ] && [ "$PERSETUJUAN" != "" ]; then
        echo "Instalasi dibatalkan."
        exit 0
    fi
    echo "  -> Membersihkan file..."
    rm -f app.py jtsi_aiprob.db requirements.txt runner.sh
    rm -rf templates static $VENV_NAME
fi

read -p "Mulai instalasi AiProb v$CORE_VERSION? [Y/n] " PERSETUJUAN
if [ "$PERSETUJUAN" != "y" ] && [ "$PERSETUJUAN" != "Y" ] && [ "$PERSETUJUAN" != "" ]; then
    echo "Instalasi dibatalkan."
    exit 0
fi

echo ""
echo "--- Memulai Proses Instalasi Core ---"
echo ""

# --- FASE 2: INSTALASI DEPENDENSI SISTEM ---
echo "[TAHAP 1/5] Memastikan Kebutuhan Sistem..."
NEEDS_INSTALL=0
if ! command -v $PYTHON_BIN &> /dev/null; then NEEDS_INSTALL=1; fi
if ! command -v git &> /dev/null; then NEEDS_INSTALL=1; fi

if [ $NEEDS_INSTALL -eq 1 ]; then
    echo "  -> Menginstal dependensi: $SYS_DEPS"
    $PKG_UPDATE
    $INSTALL_CMD $SYS_DEPS || { echo "ERROR: Gagal menginstal dependensi sistem."; exit 1; }
else
    echo "✅ Semua tools dasar (Python, Git) ditemukan."
fi

if ! $PYTHON_BIN -m venv --help &> /dev/null
then
    echo "  -> Peringatan: Modul 'venv' hilang. Mencoba instalasi venv."
    if [ -n "$PREFIX" ]; then $INSTALL_CMD python-pip python; else $INSTALL_CMD python3-venv || { echo "ERROR: Gagal menginstal python3-venv!"; exit 1; }; fi
fi

echo "[TAHAP 2/5] Menyiapkan Lingkungan Virtual (.venv_aiprob)..."
$PYTHON_BIN -m venv $VENV_NAME || { echo "ERROR: Gagal membuat lingkungan virtual!"; exit 1; }
. $VENV_NAME/bin/activate
echo "  -> Lingkungan virtual diaktifkan."

# --- FASE 3: INSTALASI PYTHON & FILE PROYEK ---
echo "[TAHAP 3/5] Menginstal Dependensi Python..."
cat > requirements.txt <<'REQ_CODE'
Flask
requests
rapidfuzz
configparser
itsdangerous
Werkzeug
jinja2
REQ_CODE
pip install -r requirements.txt || { echo "ERROR: Gagal menginstal dependensi Python!"; deactivate; exit 1; }

echo "[TAHAP 4/5] Membuat Struktur Direktori..."
mkdir -p templates
mkdir -p static
echo "  -> Direktori 'templates/' dan 'static/' dibuat."


# --- TAHAP 5/5: Membuat app.py & HTML Templates ---
echo "[TAHAP 5/5] Membuat File Utama (app.py, HTML & Runner) menggunakan PYTHON..."

# KODE PYTHON UTAMA UNTUK MENULIS SEMUA FILE (MENGHINDARI ERROR SHELL)
$PYTHON_BIN - <<END_OF_PYTHON_CODE
import os
import sys

# Data Konfigurasi Python dari script shell
GITHUB_REPO_PATH = "$GITHUB_REPO_PATH"
CORE_VERSION = "$CORE_VERSION"
PYTHON_BIN = "$PYTHON_BIN"
VENV_NAME = "$VENV_NAME"

# 1. KODE app.py
APP_PY_CONTENT = """
# [KODE app.py LENGKAP - AiProb v7.2-rc - JTSI (DATA DINAMIS)]
import sqlite3
import sys
import datetime
import os
import hashlib
import requests
import json
import logging
import queue
import configparser
import platform
from functools import wraps
from flask import (
    Flask, jsonify, request, render_template, 
    redirect, url_for, session, flash, g, Response
)
from rapidfuzz import process

# --- KONFIGURASI INI ---
GITHUB_VERSION_INI_URL = "https://raw.githubusercontent.com/{}/main/version.ini" 

# --- KONFIGURASI KONSTAN LEGAL (HARDCODE TERTINGGI UNTUK LEGALITAS) ---
DEFAULT_BRAND = "JTSI (JAS TECH SYSTEM INSTRUMENT)"
DEFAULT_DEVELOPER = "Anjas Amar Pradana"
DEFAULT_AI_NAME = "AiProb"
DEFAULT_VERSION = "{}" 

# --- KONFIGURASI LOGIKA ---
DB_NAME = 'jtsi_aiprob.db'
MIN_PROBABILITY_SCORE = 75
STARTING_SCORE = 10

# --- Inisialisasi Aplikasi Flask ---
app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24).hex()

# --- Variabel Global ---
GEMINI_API_KEY = None
log_queue = queue.Queue(maxsize=100)

# --- FUNGSI HELPER LOGGING ---
class QueueHandler(logging.Handler):
    def emit(self, record):
        log_entry = {
            'timestamp': self.format(record).split(' - ')[0],
            'level': record.levelname,
            'message': record.getMessage(),
            'source': record.name
        }
        try:
            log_queue.put_nowait(json.dumps(log_entry))
        except queue.Full:
            log_queue.get_nowait()
            log_queue.put_nowait(json.dumps(log_entry))

# --- FUNGSI KEAMANAN & DECORATOR ---
def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(plain_password, hashed_password):
    return hash_password(plain_password) == hashed_password

def role_required(role="admin"):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                flash("Anda perlu login untuk mengakses halaman ini.", "warning")
                return redirect(url_for('login'))
            if session.get('role') != role:
                flash(f"Akses ditolak. Hanya {role.upper()} yang diizinkan.", "danger")
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# --- FUNGSI DATABASE & KONFIGURASI DINAMIS ---
def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db_path = os.path.join(app.root_path, DB_NAME)
        db = g._database = sqlite3.connect(db_path, timeout=10, check_same_thread=False)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def query_db(query, args=(), one=False):
    cur = get_db().execute(query, args)
    rv = cur.fetchall()
    cur.close()
    return (rv[0] if rv else None) if one else rv

def execute_db(query, args=()):
    db = get_db()
    cursor = db.cursor()
    cursor.execute(query, args)
    db.commit()
    return cursor.lastrowid

def get_setting_from_db(setting_name, default_value=None):
    try:
        result = query_db("SELECT setting_value FROM Settings WHERE setting_name = ?", (setting_name,), one=True)
        return result['setting_value'] if result else default_value
    except sqlite3.OperationalError:
        return default_value

def get_app_config():
    version = get_setting_from_db('APP_VERSION', DEFAULT_VERSION) 
    
    return {
        'brand': get_setting_from_db('APP_BRAND', DEFAULT_BRAND),
        'developer': get_setting_from_db('APP_DEVELOPER', DEFAULT_DEVELOPER),
        'ai_name': get_setting_from_db('AI_NAME', DEFAULT_AI_NAME),
        'current_version': version
    }

def load_and_configure_api_key():
    global GEMINI_API_KEY
    with app.app_context():
        GEMINI_API_KEY = get_setting_from_db('GEMINI_API_KEY')
    if GEMINI_API_KEY:
        app.logger.info("Kunci API Gemini (dari DB) berhasil dimuat.")
    else:
        app.logger.warning("PERINGATAN: Kunci API Gemini tidak diatur.")

# --- FUNGSI SELF-UPDATE CHECK (MEMBACA version.ini) ---
def check_for_updates(current_version):
    app.logger.info("Memeriksa pembaruan dari version.ini...")
    try:
        response = requests.get(GITHUB_VERSION_INI_URL.format(GITHUB_REPO_PATH), timeout=7)
        
        if response.status_code == 200:
            config = configparser.ConfigParser()
            config.read_string(response.text)
            
            latest_version = config.get('VERSION', 'CURRENT_VERSION', fallback=None)
            release_stage = config.get('VERSION', 'RELEASE_STAGE', fallback='unknown')
            
            if latest_version and latest_version != current_version:
                app.logger.warning(f"UPDATE TERSEDIA! Versi: {latest_version} ({release_stage}).")
                execute_db("UPDATE Settings SET setting_value = ? WHERE setting_name = 'APP_VERSION'", (latest_version,))
                return True, latest_version, release_stage
            elif latest_version == current_version:
                app.logger.info(f"AiProb sudah versi terbaru ({current_version}).")
            return False, latest_version, release_stage
        else:
            app.logger.warning(f"Gagal akses version.ini (Status: {response.status_code}).")
    except Exception as e:
        app.logger.error(f"Error saat cek update: {e}")
    return False, None, None

# --- LOGIKA SETUP & APP CONFIG ---
def is_setup_complete():
    db_path = os.path.join(app.root_path, DB_NAME)
    if not os.path.exists(db_path):
        return False
    try:
        with app.app_context():
            version = query_db("SELECT * FROM Settings WHERE setting_name = 'APP_VERSION'", one=True)
            admin = query_db("SELECT * FROM Users WHERE role = 'admin'", one=True)
            return admin is not None and version is not None
    except sqlite3.OperationalError:
        return False

def inisialisasi_database():
    try:
        with app.app_context():
            db = get_db()
            cursor = db.cursor()
            cursor.execute("CREATE TABLE IF NOT EXISTS Settings (setting_name TEXT PRIMARY KEY, setting_value TEXT)")
            # --- MASUKKAN DATA HARDCODE LEGAL KE DB ---
            cursor.execute("INSERT OR IGNORE INTO Settings (setting_name, setting_value) VALUES (?, ?)", ('APP_BRAND', DEFAULT_BRAND))
            cursor.execute("INSERT OR IGNORE INTO Settings (setting_name, setting_value) VALUES (?, ?)", ('APP_DEVELOPER', DEFAULT_DEVELOPER))
            cursor.execute("INSERT OR IGNORE INTO Settings (setting_name, setting_value) VALUES (?, ?)", ('AI_NAME', DEFAULT_AI_NAME))
            cursor.execute("INSERT OR IGNORE INTO Settings (setting_name, setting_value) VALUES (?, ?)", ('APP_VERSION', DEFAULT_VERSION))
            # ----------------------------------------
            cursor.execute(f'''
            CREATE TABLE IF NOT EXISTS Users (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                hashed_password TEXT NOT NULL,
                role TEXT NOT NULL CHECK(role IN ('admin', 'user')),
                ai_callsign TEXT DEFAULT '{DEFAULT_AI_NAME}'
            )
            ''')
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS Questions (
                q_id INTEGER PRIMARY KEY AUTOINCREMENT,
                teks_pertanyaan_inti TEXT UNIQUE,
                user_id_pembuat INTEGER,
                scope TEXT NOT NULL DEFAULT 'global' CHECK(scope IN ('global', 'private')),
                FOREIGN KEY (user_id_pembuat) REFERENCES Users (user_id)
            )
            ''')
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS Answers (
                a_id INTEGER PRIMARY KEY AUTOINCREMENT,
                q_id_terkait INTEGER,
                teks_jawaban TEXT,
                user_id_pembuat INTEGER,
                skor_probabilitas INTEGER DEFAULT 10,
                FOREIGN KEY (q_id_terkait) REFERENCES Questions (q_id),
                FOREIGN KEY (user_id_pembuat) REFERENCES Users (user_id)
            )
            ''')
            db.commit()
        return True
    except sqlite3.Error as e:
        app.logger.error(f"Error DB (Inisialisasi): {e}")
        return False

# --- RUTE UTAMA & MIDDLEWARE ---
@app.before_request
def check_setup_status():
    if not is_setup_complete() and request.endpoint not in ['setup', 'static']:
        inisialisasi_database() 
        return redirect(url_for('setup'))
    if is_setup_complete() and request.endpoint == 'setup':
        return redirect(url_for('login'))

@app.route('/setup', methods=['GET', 'POST'])
def setup():
    if is_setup_complete():
        return redirect(url_for('login'))
    
    config = get_app_config() 
    
    if request.method == 'POST':
        admin_user = request.form['username']
        admin_pass = request.form['password']
        api_key = request.form['api_key']
        if not admin_user or not admin_pass or not api_key:
            flash("Semua field wajib diisi!", "danger")
            return render_template('setup.html', brand=config['brand'], dev=config['developer'])
        
        hashed_pass = hash_password(admin_pass)
        try:
            execute_db(
                "INSERT INTO Users (username, hashed_password, role, ai_callsign) VALUES (?, ?, 'admin', ?)",
                (admin_user, hashed_pass, f"{config['ai_name']} (Admin)")
            )
            execute_db("INSERT INTO Settings (setting_name, setting_value) VALUES ('GEMINI_API_KEY', ?)", (api_key,))
            execute_db("INSERT INTO Settings (setting_name, setting_value) VALUES ('DEFAULT_MANUAL_SCOPE', 'global')")
            flash("Setup Berhasil! Akun Admin telah dibuat. Silakan login.", "success")
            return redirect(url_for('login'))
        except sqlite3.Error as e:
            flash(f"Error saat membuat admin: {e}", "danger")
            return render_template('setup.html', brand=config['brand'], dev=config['developer'])
            
    return render_template('setup.html', brand=config['brand'], dev=config['developer'])

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = query_db("SELECT * FROM Users WHERE username = ?", (username,), one=True)
        config = get_app_config() 
        if user and verify_password(password, user['hashed_password']):
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['role'] = user['role']
            session['ai_callsign'] = user['ai_callsign']
            flash(f"Login berhasil! Selamat datang, {user['username']}.", "success")
            return redirect(url_for('dashboard'))
        else:
            flash("Username atau password salah.", "danger")
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if not username or not password:
            flash("Username dan password wajib diisi.", "warning")
            return redirect(url_for('register'))
        user = query_db("SELECT * FROM Users WHERE username = ?", (username,), one=True)
        config = get_app_config() 
        if user:
            flash("Username sudah terpakai.", "warning")
        else:
            hashed_pass = hash_password(password)
            try:
                execute_db(
                    "INSERT INTO Users (username, hashed_password, role, ai_callsign) VALUES (?, ?, 'user', ?)",
                    (username, hashed_pass, config['ai_name'])
                )
                flash("Registrasi berhasil! Silakan login.", "success")
                return redirect(url_for('login'))
            except sqlite3.Error as e:
                flash(f"Error registrasi: {e}", "danger")
    return render_template('register.html')

@app.route('/logout')
def logout():
    session.clear()
    flash("Anda telah logout.", "info")
    return redirect(url_for('login'))


@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    user_data = {
        'username': session['username'],
        'role': session['role'],
        'user_id': session['user_id']
    }
    
    config = get_app_config()
    
    needs_update, latest_version, release_stage = check_for_updates(config['current_version'])
    
    config = get_app_config() 
    
    repo_link = GITHUB_VERSION_INI_URL.format(GITHUB_REPO_PATH).replace('https://raw.githubusercontent.com/', 'https://github.com/').replace('/main/version.ini', '')
    
    settings = {
        'api_key_set': bool(get_setting_from_db('GEMINI_API_KEY')),
        'default_scope': get_setting_from_db('DEFAULT_MANUAL_SCOPE', 'global'),
        'needs_update': needs_update,
        'latest_version': latest_version,
        'current_version': config['current_version'],
        'release_stage': release_stage,
        'repo_link': repo_link,
        'python_version': sys.version.split()[0],
        'os_name': platform.system() 
    }
    
    if user_data['role'] == 'admin':
        return render_template('admin_dashboard.html', user=user_data, settings=settings, brand=config['brand'], dev=config['developer'])
    else:
        return render_template('user_dashboard.html', user=user_data, settings=settings, brand=config['brand'], dev=config['developer'])

# --- RUTE API UTAMA ---
@app.route('/api/ask', methods=['POST'])
def api_ask():
    if 'user_id' not in session:
        return jsonify({"error": "Not authenticated"}), 401
    
    user_id = session['user_id']
    user_input = request.json.get('question', '')
    if not user_input:
        return jsonify({"error": "No question provided"}), 400
    
    config = get_app_config()
    
    dynamic_answer = get_dynamic_response(user_input)
    if dynamic_answer:
        app.logger.info(f"User {session['username']} bertanya dinamis.")
        return jsonify({"answer": dynamic_answer, "source": "static"})

    all_questions_list = get_all_questions(user_id)
    all_questions_text = [q['teks_pertanyaan_inti'] for q in all_questions_list] 
    
    best_match = process.extractOne(user_input, all_questions_text) if all_questions_text else (None, 0)
    skor_kemiripan = best_match[1] if best_match else 0
    
    if skor_kemiripan >= MIN_PROBABILITY_SCORE:
        teks_pertanyaan_mirip = best_match[0]
        q_id_terbaik = next((q['q_id'] for q in all_questions_list if q['teks_pertanyaan_inti'] == teks_pertanyaan_mirip), None)
        
        if q_id_terbaik:
            jawaban_terbaik, _ = get_ambiguous_answer(q_id_terbaik)
            app.logger.info(f"User {session['username']} dijawab dari Memori.")
            return jsonify({"answer": jawaban_terbaik, "source": "memory"})
    
    app.logger.info(f"User {session['username']} dikirim ke Gemini.")
    gemini_answer = panggil_gemini_api(user_input)
    if gemini_answer:
        learn_new_answer(user_input, gemini_answer, user_id, get_setting_from_db('DEFAULT_MANUAL_SCOPE', 'global'))
        return jsonify({"answer": gemini_answer, "source": "gemini (saved)"})
    else:
        app.logger.warning(f"Gagal mendapatkan jawaban untuk '{user_input}'.")
        return jsonify({"answer": "Maaf, saya tidak tahu jawaban ini dan tidak bisa mencarinya secara online.", "source": "failed"})

@app.route('/api/admin/settings', methods=['POST'])
@role_required(role='admin')
def admin_set_settings():
    """Hanya izinkan perubahan API Key dan Scope. Branding DILARANG diubah."""
    data = request.json
    if 'new_api_key' in data:
        new_key = data['new_api_key']
        if new_key:
            execute_db("UPDATE Settings SET setting_value = ? WHERE setting_name = 'GEMINI_API_KEY'", (new_key,))
            global GEMINI_API_KEY
            GEMINI_API_KEY = new_key
            app.logger.info("Admin mengupdate Kunci API.")
            return jsonify({"message": "Kunci API berhasil di-update."})
    if 'new_scope' in data:
        new_scope = data['new_scope']
        if new_scope in ['private', 'global']:
            execute_db("UPDATE Settings SET setting_value = ? WHERE setting_name = 'DEFAULT_MANUAL_SCOPE'", (new_scope,))
            app.logger.info(f"Admin mengubah Default Scope ke '{new_scope}'.")
            return jsonify({"message": f"Default scope diatur ke '{new_scope}'."})
    return jsonify({"error": "Invalid request"}), 400

# --- RUTE LIVE LOG ADMIN ---
@app.route('/admin/live-logs')
@role_required(role='admin')
def live_logs():
    def generate():
        while True:
            log_entry = log_queue.get() 
            yield f"data: {log_entry}\n\n"
            import time
            time.sleep(0.1) 
    
    return Response(generate(), mimetype='text/event-stream')

# --- FUNGSI HELPER LOGIKA AI ---
def get_dynamic_response(teks):
    config = get_app_config()
    teks = teks.lower()
    now = datetime.datetime.now()
    if any(kata in teks for kata in ['jam berapa']): return f"Sekarang jam {now.strftime('%H:%M:%S')}"
    if any(kata in teks for kata in ['tanggal berapa']):
        hari = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"][now.weekday()]
        bulan = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"][now.month - 1]
        return f"Hari ini {hari}, {now.day} {bulan} {now.year}"
    if any(kata in teks for kata in ['siapa kamu']): return f"Saya {config['ai_name']} (v{config['current_version']}), AI dari {config['brand']}."
    if 'jtsi' in teks: return f"{config['brand']} adalah brand perusahaan yang menciptakan saya."
    if 'anjas amar pradana' in teks: return f"Saya dikembangkan oleh {config['developer']}."
    return None

def get_all_questions(user_id):
    return query_db(
        "SELECT q_id, teks_pertanyaan_inti FROM Questions "
        "WHERE scope = 'global' OR (scope = 'private' AND user_id_pembuat = ?)",
        (user_id,)
    )

def get_ambiguous_answer(q_id):
    max_score_result = query_db("SELECT MAX(skor_probabilitas) FROM Answers WHERE q_id_terkait = ?", (q_id,), one=True)
    if not max_score_result or max_score_result[0] is None: return None, []
    max_score = max_score_result[0]
    results = query_db(
        "SELECT a_id, teks_jawaban, skor_probabilitas FROM Answers "
        "WHERE q_id_terkait = ? AND skor_probabilitas = ?",
        (q_id, max_score)
    )
    if len(results) >= 1:
        row = results[0]
        pkg = [{'a_id': row['a_id'], 'teks': row['teks_jawaban'], 'skor': row['skor_probabilitas']}]
        return f"{row['teks_jawaban']}", pkg
    return None, []

def learn_new_answer(pertanyaan_baru, jawaban_baru, user_id, scope):
    q = query_db("SELECT q_id FROM Questions WHERE teks_pertanyaan_inti = ?", (pertanyaan_baru,), one=True)
    if q:
        q_id = q['q_id']
    else:
        q_id = execute_db(
            "INSERT INTO Questions (teks_pertanyaan_inti, user_id_pembuat, scope) VALUES (?, ?, ?)",
            (pertanyaan_baru, user_id, scope)
        )
    execute_db(
        "INSERT INTO Answers (q_id_terkait, teks_jawaban, user_id_pembuat, skor_probabilitas) VALUES (?, ?, ?, ?)",
        (q_id, jawaban_baru, user_id, STARTING_SCORE)
    )
    return True

def panggil_gemini_api(pertanyaan):
    if GEMINI_API_KEY is None: return None
    config = get_app_config()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={GEMINI_API_KEY}"
    data = {"contents": [{"parts": [{"text": (
        f"Anda adalah {config['ai_name']} (v{config['current_version']}), AI dari {config['brand']} yang dikembangkan oleh {config['developer']}. Jawab pertanyaan berikut "
        "secara singkat dan faktual dalam bahasa Indonesia. "
        f"Pertanyaan: {pertanyaan}"
    )}]}]}
    headers = {"Content-Type": "application/json"}
    try:
        response = requests.post(url, headers=headers, data=json.dumps(data), timeout=20)
        if response.status_code != 200:
            app.logger.error(f"Error API Gemini: {response.status_code}")
            return None
        result_json = response.json()
        text_answer = result_json.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', 'API Error')
        return text_answer
    except Exception as e:
        app.logger.error(f"Error saat memanggil API Gemini (requests): {e}")
        return None

# --- TITIK MULAI PROGRAM ---
if __name__ == "__main__":
    werkzeug_logger = logging.getLogger('werkzeug') 
    werkzeug_logger.setLevel(logging.INFO)
    werkzeug_logger.addHandler(QueueHandler())

    app.logger.setLevel(logging.DEBUG) 
    app.logger.addHandler(QueueHandler())
    
    config = get_app_config()

    app.logger.info(f"Memulai server AiProb v{config['current_version']} ({config['brand']})...")
    
    with app.app_context():
        if not is_setup_complete():
            inisialisasi_database()
            app.logger.warning("PERHATIAN: Database belum di-setup.")
            print("\n!!! SILAKAN BUKA BROWSER UNTUK SETUP !!!\n")
        else:
            load_and_configure_api_key()
            config = get_app_config() 
            check_for_updates(config['current_version'])
    
    app.run(host='0.0.0.0', port=5000, debug=False)
""".format(GITHUB_REPO_PATH, CORE_VERSION)

# 2. KODE HTML TEMPLATES (disingkat di sini)
# KODE HTML DIBUAT DENGAN TEMPLATE PENUH DARI RESPONS SEBELUMNYA.
TEMPLATES = {
    'base.html': """<!DOCTYPE html><html lang="id"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>{% block title %}AiProb v7.2-rc{% endblock %}</title><style>body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;margin:0;padding:0;background-color:#e9eff5;color:#333}.container{width:95%;max-width:900px;margin:20px auto;padding:30px;background-color:#fff;box-shadow:0 4px 12px rgba(0,0,0,0.1);border-radius:12px}.flash{padding:15px;margin-bottom:20px;border-radius:6px;font-weight:bold}.success{background-color:#d4edda;color:#155724;border:1px solid #c3e6cb}.danger{background-color:#f8d7da;color:#721c24;border:1px solid #f5c6cb}.info{background-color:#d1ecf1;color:#0c5460;border:1px solid #bee5eb}.warning{background-color:#fff3cd;color:#856404;border:1px solid #ffeeba}h1,h2,h3{color:#0056b3}form label{display:block;margin-top:15px;font-weight:600}form input[type="text"],form input[type="password"],form select{width:100%;padding:12px;margin-top:8px;border:1px solid #ccc;border-radius:6px;box-sizing:border-box;font-size:1em}form button{background-color:#007bff;color:white;padding:12px 20px;border:none;border-radius:6px;cursor:pointer;margin-top:25px;width:100%;font-size:1.1em;transition:background-color .3s}form button:hover{background-color:#0056b3}.footer{margin-top:40px;text-align:center;font-size:.8em;color:#666;padding-top:15px;border-top:1px solid #eee}.nav a{margin-left:20px;text-decoration:none;color:#007bff;font-weight:600}/* Chat Styling */.chat-container{height:400px;overflow-y:scroll;padding:15px;border:1px solid #ddd;border-radius:8px;margin-bottom:15px;background-color:#fafafa}.message{margin-bottom:10px;padding:10px 15px;border-radius:18px;max-width:85%;line-height:1.4}.user-message{background-color:#007bff;color:white;margin-left:auto;text-align:right;border-bottom-right-radius:0}.ai-message{background-color:#e9ecef;color:#333;margin-right:auto;text-align:left;border-bottom-left-radius:0}.typing-indicator{display:inline-block;width:10px;height:10px;background-color:#6c757d;border-radius:50%;margin:0 2px;animation:bounce .6s infinite alternate}.typing-indicator:nth-child(2){animation-delay:.2s}.typing-indicator:nth-child(3){animation-delay:.4s}@keyframes bounce{from{transform:translateY(0)}to{transform:translateY(-5px)}}</style></head><body><div class="container">{% with messages = get_flashed_messages(with_categories=true) %}{% if messages %}{% for category, message in messages %}<div class="flash {{ category }}">{{ message | safe }}</div>{% endfor %}{% endif %}{% endwith %}{% block content %}{% endblock %}<div class="footer"><p>{{ brand }} (v{% if settings and settings.current_version %}{{ settings.current_version }}{% else %}7.2-rc{% endif %}) | Dikembangkan oleh {{ dev }}</p></div></div></body></html>""",
    'setup.html': """{% extends "base.html" %}{% block title %}Setup Admin - AiProb v7.2-rc{% endblock %}{% block content %}<h1>Setup Admin AiProb v7.2-rc ⚙️</h1><p>Ini adalah langkah setup pertama. Buat akun <strong>Admin</strong> dan masukkan **Kunci API Gemini** Anda.</p><div class="flash info"><strong>Peringatan Legal:</strong> Brand ({{ brand }}) dan Developer ({{ dev }}) **tidak dapat diubah** setelah setup. Informasi ini dilindungi oleh hak cipta.</div><form method="POST"><label for="username">Username Admin:</label><input type="text" id="username" name="username" required><label for="password">Password Admin:</label><input type="password" id="password" name="password" required><label for="api_key">Kunci API Gemini (wajib):</label><input type="text" id="api_key" name="api_key" placeholder="AIzaSy... atau sejenisnya" required><button type="submit">Selesaikan Setup & Login</button></form>{% endblock %}""",
    'login.html': """{% extends "base.html" %}{% block title %}Login - AiProb v7.2-rc{% endblock %}{% block content %}<h1>Login ke AiProb v7.2-rc</h1><form method="POST"><label for="username">Username:</label><input type="text" id="username" name="username" required><label for="password">Password:</label><input type="password" id="password" name="password" required><button type="submit">Login</button></form><p style="text-align: center; margin-top: 20px;">Belum punya akun? <a href="{{ url_for('register') }}">Daftar di sini</a></p>{% endblock %}""",
    'register.html': """{% extends "base.html" %}{% block title %}Daftar Pengguna - AiProb v7.2-rc{% endblock %}{% block content %}<h1>Daftar Pengguna AiProb</h1><p>Buat akun **Pengguna Umum**.</p><form method="POST"><label for="username">Username:</label><input type="text" id="username" name="username" required><label for="password">Password:</label><input type="password" id="password" name="password" required><button type="submit">Daftar</button></form><p style="text-align: center; margin-top: 20px;">Sudah punya akun? <a href="{{ url_for('login') }}">Login di sini</a></p>{% endblock %}""",
    'user_dashboard.html': """{% extends "base.html" %}{% block title %}Dashboard Pengguna{% endblock %}{% block content %}<div class="nav" style="text-align: right;"><a href="{{ url_for('logout') }}">Logout</a></div><h1>Selamat Datang, {{ user.username }}!</h1><p>Anda adalah <strong>{{ user.role | upper }}</strong>. Panggil AI Anda: <strong>{{ session['ai_callsign'] }}</strong>.</p>{% if settings.needs_update %}<div class="flash warning">⚠️ **Pembaruan Tersedia!** Versi terbaru **{{ settings.latest_version }} ({{ settings.release_stage | upper }})** sudah rilis. Versi Anda: {{ settings.current_version }}. Silakan hubungi administrator atau cek <a href="{{ settings.repo_link }}" target="_blank">repo GitHub</a> untuk mengupdate.</div>{% endif %}<h2>💬 Chat dengan {{ session['ai_callsign'] }}</h2><div id="chat-container" class="chat-container"><div class="message ai-message">Halo, saya AiProb v{{ settings.current_version }}. Ada yang bisa saya bantu?</div></div><form id="ask-form" style="display: flex; gap: 10px;"><input type="text" id="question" name="question" placeholder="Ketik pertanyaan Anda..." required style="flex-grow: 1; margin-top: 0;"><button type="submit" style="width: 120px; margin-top: 0;">Kirim</button></form><script>document.getElementById('ask-form').addEventListener('submit', function(e) {e.preventDefault();const questionInput = document.getElementById('question');const question = questionInput.value;const chatContainer = document.getElementById('chat-container');if (!question) return;chatContainer.innerHTML += `<div class="message user-message">${question}</div>`;questionInput.value = '';chatContainer.scrollTop = chatContainer.scrollHeight;const typingIndicatorHtml = `<div class="typing-indicator"></div>`.repeat(3);const aiResponseDiv = document.createElement('div');aiResponseDiv.className = 'message ai-message';aiResponseDiv.id = 'ai-temp-response';aiResponseDiv.innerHTML = typingIndicatorHtml;chatContainer.appendChild(aiResponseDiv);chatContainer.scrollTop = chatContainer.scrollHeight;fetch('{{ url_for("api_ask") }}', {method: 'POST',headers: {'Content-Type': 'application/json'},body: JSON.stringify({ question: question })}) .then(response => response.json()) .then(data => {const errorDiv = document.getElementById('ai-temp-response');if (errorDiv) {errorDiv.innerHTML = '';errorDiv.id = '';}const rawAnswer = data.answer || 'Maaf, terjadi kesalahan saat memproses jawaban.';let i = 0;function typeWriter() {if (i < rawAnswer.length) {aiResponseDiv.innerHTML += rawAnswer.charAt(i);i++;chatContainer.scrollTop = chatContainer.scrollHeight;setTimeout(typeWriter, 20);} else {aiResponseDiv.innerHTML += `<br><small style="opacity: 0.7;">(Sumber: ${data.source || 'Unknown'})</small>`;}}typeWriter();}) .catch(error => {const errorDiv = document.getElementById('ai-temp-response');if (errorDiv) {errorDiv.innerHTML = `Terjadi error jaringan/sistem.`;errorDiv.id = '';}console.error('Error:', error);});});</script>{% endblock %}""",
    'admin_dashboard.html': """{% extends "base.html" %}{% block title %}Dashboard Admin{% endblock %}{% block content %}<div class="nav" style="text-align: right;"><a href="{{ url_for('logout') }}">Logout</a></div><h1>Dashboard Admin AiProb v{{ settings.current_version }} 👑</h1>{% if settings.needs_update %}<div class="flash warning">⚠️ **Pembaruan {{ settings.release_stage | upper }} Tersedia!** Versi terbaru **{{ settings.latest_version }}** sudah rilis. Versi Anda: {{ settings.current_version }}. Silakan cek <a href="{{ settings.repo_link }}" target="_blank">repo GitHub</a> untuk mengupdate.</div>{% else %}<div class="flash success">✅ Sistem Anda sudah versi terbaru ({{ settings.current_version }}).</div>{% endif %}<hr><h2>💻 Informasi Mesin & Platform (JTSI)</h2><p>Data **Brand** dan **Developer** dilindungi secara **Hardcoded** dan tidak dapat diubah oleh pengguna.</p><div style="display: flex; gap: 20px; margin-top: 15px;"><ul style="list-style: none; padding: 0;"><li>Brand Perusahaan: <strong>{{ brand }}</strong></li><li>Developer Utama: <strong>{{ dev }}</strong></li></ul><ul style="list-style: none; padding: 0;"><li>Python Version: <strong>{{ settings.python_version }}</strong></li><li>Operating System: <strong>{{ settings.os_name }}</strong></li></ul></div><hr><h2>🛠️ Pengaturan API & Scope</h2><p>Status Kunci API Gemini: <strong>{% if settings.api_key_set %}<span style="color: green;">AKTIF</span>{% else %}<span style="color: red;">BELUM DIATUR</span>{% endif %}</strong></p><form id="api-key-form"><h3>Update Kunci API</h3><label for="new_api_key">Kunci API Gemini Baru:</label><input type="text" id="new_api_key" name="new_api_key" placeholder="Masukkan kunci baru"><button type="submit">Update API Key</button></form><form id="scope-form"><h3>Default Scope Penyimpanan</h3><label for="new_scope">Penyimpanan Jawaban Baru (dari Gemini):</label><select id="new_scope" name="new_scope"><option value="global" {% if settings.default_scope == 'global' %}selected{% endif %}>Global (Dapat dilihat semua pengguna)</option><option value="private" {% if settings.default_scope == 'private" %}selected{% endif %}>Private (Hanya dapat dilihat Anda)</option></select><button type="submit">Update Scope</button></form><hr style="margin: 40px 0;"><h2>⚙️ Live System Logs (Real-time Debug)</h2><p>Melihat log server Flask dan pesan debug AiProb Anda secara langsung. Ini menggantikan terminal.</p><pre id="log-display" style="height: 300px; overflow-y: scroll; background: #282c34; color: #61dafb; padding: 15px; border-radius: 8px; font-size: 0.9em; white-space: pre-wrap; word-wrap: break-word;"></pre><script>function sendAdminRequest(data) {fetch('{{ url_for("admin_set_settings") }}', {method: 'POST',headers: {'Content-Type': 'application/json'},body: JSON.stringify(data)}).then(response => response.json()).then(data => {alert(data.message || data.error);if (data.message) {window.location.reload();}}).catch(error => {alert('Terjadi error jaringan/sistem.');console.error('Error:', error);});}document.getElementById('api-key-form').addEventListener('submit', function(e) {e.preventDefault();const newKey = document.getElementById('new_api_key').value;if (newKey) {sendAdminRequest({ new_api_key: newKey });} else {alert('Kunci API tidak boleh kosong.');}});document.getElementById('scope-form').addEventListener('submit', function(e) {e.preventDefault();const newScope = document.getElementById('new_scope').value;sendAdminRequest({ new_scope: newScope });});if (typeof EventSource !== 'undefined') {const logDisplay = document.getElementById('log-display');const source = new EventSource("{{ url_for('live_logs') }}");source.onmessage = function(event) {try {const logData = JSON.parse(event.data);let color = 'white';if (logData.level === 'WARNING') color = 'yellow';if (logData.level === 'ERROR') color = 'red';if (logData.level === 'INFO') color = '#61dafb';const logLine = `<span style="color: grey;">[${logData.timestamp}]</span> <span style="color: ${color};">**[${logData.level}]**</span> (${logData.source}): ${logData.message}\n`;logDisplay.innerHTML += logLine;logDisplay.scrollTop = logDisplay.scrollHeight;} catch (e) {console.error("Error parsing log:", event.data);}};source.onerror = function(e) {logDisplay.innerHTML += '\n--- SSE CONNECTION CLOSED / ERROR ---\n';source.close();};} else {document.getElementById('log-display').textContent = "Browser tidak mendukung Server-Sent Events.";}</script>{% endblock %}"""
}


# 3. KODE RUNNER.SH
RUNNER_SH_CONTENT = """#!/bin/bash
# AiProb v{}-rc Runner - JTSI
set -e
VENV_NAME="{}"
PYTHON_BIN="{}"

echo "-------------------------------------------------"
echo "Mengaktifkan Lingkungan Virtual..."
. \$VENV_NAME/bin/activate

echo "Menjalankan AiProb v{}-rc..."
echo "Akses di: http://0.0.0.0:5000"
echo "Log debug kini tampil di Dashboard Admin (Live Logs)."
echo "Tekan Ctrl+C untuk menghentikan server."

\$PYTHON_BIN app.py

echo "Server dihentikan. Menonaktifkan lingkungan virtual..."
deactivate
""".format(CORE_VERSION, VENV_NAME, PYTHON_BIN, CORE_VERSION)

# Menulis file ke disk
try:
    with open('app.py', 'w') as f:
        f.write(APP_PY_CONTENT)
    
    for filename, content in TEMPLATES.items():
        # Pastikan folder templates ada
        os.makedirs('templates', exist_ok=True)
        with open(os.path.join('templates', filename), 'w') as f:
            f.write(content)

    with open('runner.sh', 'w') as f:
        f.write(RUNNER_SH_CONTENT)
    os.chmod('runner.sh', 0o755)

    print("✅ Semua file proyek (app.py, HTML, runner.sh) berhasil dibuat.")
except Exception as e:
    print(f"❌ ERROR KRITIS saat menulis file: {e}")
    sys.exit(1)

# PANDUAN PENGOPERASIAN (UX FINAL)
print("-------------------------------------------------")
print("✅ INSTALASI CORE SELESAI! Program Siap Dioperasikan.")
print("-------------------------------------------------")
print("")
print("🔥 PANDUAN PENGOPERASIAN AiProb v{CORE_VERSION} 🔥".format(CORE_VERSION=CORE_VERSION))
print("-------------------------------------------------")
print("Langkah 1: Menjalankan Server")
print("Akses: Jalankan skrip runner yang telah disiapkan.")
print("   \$ ./runner.sh")
print("")
print("Langkah 2: Setup Awal (Hanya sekali)")
print("Akses: Buka browser Anda dan kunjungi http://127.0.0.1:5000")
print("Aksi: Buat akun Admin dan masukkan Kunci API Gemini Anda.")
print("")
print("Langkah 3: Penggunaan Normal")
print("Akses: Login sebagai Admin (👑) untuk pengaturan dan Logs, atau User (💬) untuk chat AI.")
print("")
print("Langkah 4: Menghentikan Server")
print("Aksi: Di terminal server berjalan, tekan Ctrl + C. Lingkungan akan dinonaktifkan.")
print("-------------------------------------------------")

# Menampilkan opsi interaktif baru
print("\n--- OPSI PASCA-INSTALASI ---")
print("1. Jalankan AiProb sekarang (./runner.sh)")
print("2. Keluar (Lakukan secara manual nanti)")
post_install_choice = input("Pilih opsi [1/2]: ")

if post_install_choice == "1":
    print("Memulai AiProb...")
    os.system("./runner.sh")

# Menonaktifkan Venv internal skrip init.sh
os.system("deactivate")

END_OF_PYTHON_CODE
