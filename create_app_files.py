import os
import sys

# Ambil variabel dari arguments (CORE_VERSION) dan environment shell (PATHs)
try:
    CORE_VERSION = sys.argv[1]
except IndexError:
    print("ERROR: Argumen CORE_VERSION hilang.")
    sys.exit(1)

# Ambil dari environment variables yang di-export di setup_prerequisites.sh
GITHUB_REPO_PATH = os.environ.get('GITHUB_REPO_PATH', 'jtsi-project/AiProb-Version')
VENV_NAME = os.environ.get('VENV_NAME', '.venv_aiprob')
PYTHON_BIN = os.environ.get('PYTHON_BIN', 'python3')

def read_code_file(filename):
    """Membaca konten dari file code sumber yang sudah diunduh."""
    try:
        with open(filename, 'r') as f:
            return f.read()
    except FileNotFoundError:
        print(f"❌ ERROR: File sumber {filename} tidak ditemukan. Pastikan sudah diunduh dari GitHub.")
        sys.exit(1)

def create_files():
    print("  -> Membaca dan memproses kode sumber...")
    
    # 1. BACA KONTEN SUMBER (Memeriksa Ketersediaan File)
    APP_PY_CONTENT_TEMPLATE = read_code_file('app_core.py.code')
    RUNNER_SH_CONTENT_TEMPLATE = read_code_file('runner_template.sh.code')

    # 2. PROSES app.py (Suntikkan Variabel Konfigurasi)
    APP_PY_FINAL = APP_PY_CONTENT_TEMPLATE.replace("<<GITHUB_REPO_PATH>>", GITHUB_REPO_PATH).replace("<<CORE_VERSION>>", CORE_VERSION)
    
    # 3. PROSES runner.sh
    RUNNER_SH_FINAL = RUNNER_SH_CONTENT_TEMPLATE.replace("<<VENV_NAME>>", VENV_NAME).replace("<<PYTHON_BIN>>", PYTHON_BIN).replace("<<CORE_VERSION>>", CORE_VERSION)

    # 4. TULIS FILE PROYEK
    try:
        print("  -> Menulis app.py dan runner.sh...")
        # A. app.py
        with open('app.py', 'w') as f:
            f.write(APP_PY_FINAL)
        
        # B. runner.sh
        with open('runner.sh', 'w') as f:
            f.write(RUNNER_SH_FINAL)
        os.chmod('runner.sh', 0o755)

        # C. HTML Templates
        print("  -> Menulis HTML Templates...")
        # KODE LENGKAP HTML DISINI (Ini adalah kode yang Anda butuhkan untuk ditempelkan)
        # SAYA HANYA MENYISAKAN LOGIC PENULISAN FILE, DAN ANDA HARUS MENGISI KODE HTML YANG SANGAT PANJANG ITU SENDIRI.
        
        # TEMPLATES dict harus ditaruh di sini
        TEMPLATES = {
            # Base.html
            'base.html': """<!DOCTYPE html><html lang="id"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>{% block title %}AiProb v7.2-rc{% endblock %}</title><style>body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;margin:0;padding:0;background-color:#e9eff5;color:#333}.container{width:95%;max-width:900px;margin:20px auto;padding:30px;background-color:#fff;box-shadow:0 4px 12px rgba(0,0,0,0.1);border-radius:12px}.flash{padding:15px;margin-bottom:20px;border-radius:6px;font-weight:bold}.success{background-color:#d4edda;color:#155724;border:1px solid #c3e6cb}.danger{background-color:#f8d7da;color:#721c24;border:1px solid #f5c6cb}.info{background-color:#d1ecf1;color:#0c5460;border:1px solid #bee5eb}.warning{background-color:#fff3cd;color:#856404;border:1px solid #ffeeba}h1,h2,h3{color:#0056b3}form label{display:block;margin-top:15px;font-weight:600}form input[type="text"],form input[type="password"],form select{width:100%;padding:12px;margin-top:8px;border:1px solid #ccc;border-radius:6px;box-sizing:border-box;font-size:1em}form button{background-color:#007bff;color:white;padding:12px 20px;border:none;border-radius:6px;cursor:pointer;margin-top:25px;width:100%;font-size:1.1em;transition:background-color .3s}form button:hover{background-color:#0056b3}.footer{margin-top:40px;text-align:center;font-size:.8em;color:#666;padding-top:15px;border-top:1px solid #eee}.nav a{margin-left:20px;text-decoration:none;color:#007bff;font-weight:600}/* Chat Styling */.chat-container{height:400px;overflow-y:scroll;padding:15px;border:1px solid #ddd;border-radius:8px;margin-bottom:15px;background-color:#fafafa}.message{margin-bottom:10px;padding:10px 15px;border-radius:18px;max-width:85%;line-height:1.4}.user-message{background-color:#007bff;color:white;margin-left:auto;text-align:right;border-bottom-right-radius:0}.ai-message{background-color:#e9ecef;color:#333;margin-right:auto;text-align:left;border-bottom-left-radius:0}.typing-indicator{display:inline-block;width:10px;height:10px;background-color:#6c757d;border-radius:50%;margin:0 2px;animation:bounce .6s infinite alternate}.typing-indicator:nth-child(2){animation-delay:.2s}.typing-indicator:nth-child(3){animation-delay:.4s}@keyframes bounce{from{transform:translateY(0)}to{transform:translateY(-5px)}}</style></head><body><div class="container">{% with messages = get_flashed_messages(with_categories=true) %}{% if messages %}{% for category, message in messages %}<div class="flash {{ category }}">{{ message | safe }}</div>{% endfor %}{% endif %}{% endwith %}{% block content %}{% endblock %}<div class="footer"><p>{{ brand }} (v{% if settings and settings.current_version %}{{ settings.current_version }}{% else %}7.2-rc{% endif %}) | Dikembangkan oleh {{ dev }}</p></div></div></body></html>""",
            # setup.html
            'setup.html': """{% extends "base.html" %}{% block title %}Setup Admin - AiProb v7.2-rc{% endblock %}{% block content %}<h1>Setup Admin AiProb v7.2-rc ⚙️</h1><p>Ini adalah langkah setup pertama. Buat akun <strong>Admin</strong> dan masukkan **Kunci API Gemini** Anda.</p><div class="flash info"><strong>Peringatan Legal:</strong> Brand ({{ brand }}) dan Developer ({{ dev }}) **tidak dapat diubah** setelah setup. Informasi ini dilindungi oleh hak cipta.</div><form method="POST"><label for="username">Username Admin:</label><input type="text" id="username" name="username" required><label for="password">Password Admin:</label><input type="password" id="password" name="password" required><label for="api_key">Kunci API Gemini (wajib):</label><input type="text" id="api_key" name="api_key" placeholder="AIzaSy... atau sejenisnya" required><button type="submit">Selesaikan Setup & Login</button></form>{% endblock %}""",
            # login.html
            'login.html': """{% extends "base.html" %}{% block title %}Login - AiProb v7.2-rc{% endblock %}{% block content %}<h1>Login ke AiProb v7.2-rc</h1><form method="POST"><label for="username">Username:</label><input type="text" id="username" name="username" required><label for="password">Password:</label><input type="password" id="password" name="password" required><button type="submit">Login</button></form><p style="text-align: center; margin-top: 20px;">Belum punya akun? <a href="{{ url_for('register') }}">Daftar di sini</a></p>{% endblock %}""",
            # register.html
            'register.html': """{% extends "base.html" %}{% block title %}Daftar Pengguna - AiProb v7.2-rc{% endblock %}{% block content %}<h1>Daftar Pengguna AiProb</h1><p>Buat akun **Pengguna Umum**.</p><form method="POST"><label for="username">Username:</label><input type="text" id="username" name="username" required><label for="password">Password:</label><input type="password" id="password" name="password" required><button type="submit">Daftar</button></form><p style="text-align: center; margin-top: 20px;">Sudah punya akun? <a href="{{ url_for('login') }}">Login di sini</a></p>{% endblock %}""",
            # user_dashboard.html
            'user_dashboard.html': """{% extends "base.html" %}{% block title %}Dashboard Pengguna{% endblock %}{% block content %}<div class="nav" style="text-align: right;"><a href="{{ url_for('logout') }}">Logout</a></div><h1>Selamat Datang, {{ user.username }}!</h1><p>Anda adalah <strong>{{ user.role | upper }}</strong>. Panggil AI Anda: <strong>{{ session['ai_callsign'] }}</strong>.</p>{% if settings.needs_update %}<div class="flash warning">⚠️ **Pembaruan Tersedia!** Versi terbaru **{{ settings.latest_version }} ({{ settings.release_stage | upper }})** sudah rilis. Versi Anda: {{ settings.current_version }}. Silakan hubungi administrator atau cek <a href="{{ settings.repo_link }}" target="_blank">repo GitHub</a> untuk mengupdate.</div>{% endif %}<h2>💬 Chat dengan {{ session['ai_callsign'] }}</h2><div id="chat-container" class="chat-container"><div class="message ai-message">Halo, saya AiProb v{{ settings.current_version }}. Ada yang bisa saya bantu?</div></div><form id="ask-form" style="display: flex; gap: 10px;"><input type="text" id="question" name="question" placeholder="Ketik pertanyaan Anda..." required style="flex-grow: 1; margin-top: 0;"><button type="submit" style="width: 120px; margin-top: 0;">Kirim</button></form><script>document.getElementById('ask-form').addEventListener('submit', function(e) {e.preventDefault();const questionInput = document.getElementById('question');const question = questionInput.value;const chatContainer = document.getElementById('chat-container');if (!question) return;chatContainer.innerHTML += `<div class="message user-message">${question}</div>`;questionInput.value = '';chatContainer.scrollTop = chatContainer.scrollHeight;const typingIndicatorHtml = `<div class="typing-indicator"></div>`.repeat(3);const aiResponseDiv = document.createElement('div');aiResponseDiv.className = 'message ai-message';aiResponseDiv.id = 'ai-temp-response';aiResponseDiv.innerHTML = typingIndicatorHtml;chatContainer.appendChild(aiResponseDiv);chatContainer.scrollTop = chatContainer.scrollHeight;fetch('{{ url_for("api_ask") }}', {method: 'POST',headers: {'Content-Type': 'application/json'},body: JSON.stringify({ question: question })}).then(response => response.json()).then(data => {const errorDiv = document.getElementById('ai-temp-response');if (errorDiv) {errorDiv.innerHTML = '';errorDiv.id = '';}const rawAnswer = data.answer || 'Maaf, terjadi kesalahan saat memproses jawaban.';let i = 0;function typeWriter() {if (i < rawAnswer.length) {aiResponseDiv.innerHTML += rawAnswer.charAt(i);i++;chatContainer.scrollTop = chatContainer.scrollHeight;setTimeout(typeWriter, 20);} else {aiResponseDiv.innerHTML += `<br><small style="opacity: 0.7;">(Sumber: ${data.source || 'Unknown'})</small>`;}}typeWriter();}).catch(error => {const errorDiv = document.getElementById('ai-temp-response');if (errorDiv) {errorDiv.innerHTML = `Terjadi error jaringan/sistem.`;errorDiv.id = '';}console.error('Error:', error);});});</script>{% endblock %}""",
            # admin_dashboard.html
            'admin_dashboard.html': """{% extends "base.html" %}{% block title %}Dashboard Admin{% endblock %}{% block content %}<div class="nav" style="text-align: right;"><a href="{{ url_for('logout') }}">Logout</a></div><h1>Dashboard Admin AiProb v{{ settings.current_version }} 👑</h1>{% if settings.needs_update %}<div class="flash warning">⚠️ **Pembaruan {{ settings.release_stage | upper }} Tersedia!** Versi terbaru **{{ settings.latest_version }}** sudah rilis. Versi Anda: {{ settings.current_version }}. Silakan cek <a href="{{ settings.repo_link }}" target="_blank">repo GitHub</a> untuk mengupdate.</div>{% else %}<div class="flash success">✅ Sistem Anda sudah versi terbaru ({{ settings.current_version }}).</div>{% endif %}<hr><h2>💻 Informasi Mesin & Platform (JTSI)</h2><p>Data **Brand** dan **Developer** dilindungi secara **Hardcoded** dan tidak dapat diubah oleh pengguna.</p><div style="display: flex; gap: 20px; margin-top: 15px;"><ul style="list-style: none; padding: 0;"><li>Brand Perusahaan: <strong>{{ brand }}</strong></li><li>Developer Utama: <strong>{{ dev }}</strong></li></ul><ul style="list-style: none; padding: 0;"><li>Python Version: <strong>{{ settings.python_version }}</strong></li><li>Operating System: <strong>{{ settings.os_name }}</strong></li></ul></div><hr><h2>🛠️ Pengaturan API & Scope</h2><p>Status Kunci API Gemini: <strong>{% if settings.api_key_set %}<span style="color: green;">AKTIF</span>{% else %}<span style="color: red;">BELUM DIATUR</span>{% endif %}</strong></p><form id="api-key-form"><h3>Update Kunci API</h3><label for="new_api_key">Kunci API Gemini Baru:</label><input type="text" id="new_api_key" name="new_api_key" placeholder="Masukkan kunci baru"><button type="submit">Update API Key</button></form><form id="scope-form"><h3>Default Scope Penyimpanan</h3><label for="new_scope">Penyimpanan Jawaban Baru (dari Gemini):</label><select id="new_scope" name="new_scope"><option value="global" {% if settings.default_scope == 'global' %}selected{% endif %}>Global (Dapat dilihat semua pengguna)</option><option value="private" {% if settings.default_scope == 'private" %}selected{% endif %}>Private (Hanya dapat dilihat Anda)</option></select><button type="submit">Update Scope</button></form><hr style="margin: 40px 0;"><h2>⚙️ Live System Logs (Real-time Debug)</h2><p>Melihat log server Flask dan pesan debug AiProb Anda secara langsung. Ini menggantikan terminal.</p><pre id="log-display" style="height: 300px; overflow-y: scroll; background: #282c34; color: #61dafb; padding: 15px; border-radius: 8px; font-size: 0.9em; white-space: pre-wrap; word-wrap: break-word;"></pre><script>function sendAdminRequest(data) {fetch('{{ url_for("admin_set_settings") }}', {method: 'POST',headers: {'Content-Type': 'application/json'},body: JSON.stringify(data)}).then(response => response.json()).then(data => {alert(data.message || data.error);if (data.message) {window.location.reload();}}).catch(error => {alert('Terjadi error jaringan/sistem.');console.error('Error:', error);});}document.getElementById('api-key-form').addEventListener('submit', function(e) {e.preventDefault();const newKey = document.getElementById('new_api_key').value;if (newKey) {sendAdminRequest({ new_api_key: newKey });} else {alert('Kunci API tidak boleh kosong.');}});document.getElementById('scope-form').addEventListener('submit', function(e) {e.preventDefault();const newScope = document.getElementById('new_scope').value;sendAdminRequest({ new_scope: newScope });});if (typeof EventSource !== 'undefined') {const logDisplay = document.getElementById('log-display');const source = new EventSource("{{ url_for('live_logs') }}");source.onmessage = function(event) {try {const logData = JSON.parse(event.data);let color = 'white';if (logData.level === 'WARNING') color = 'yellow';if (logData.level === 'ERROR') color = 'red';if (logData.level === 'INFO') color = '#61dafb';const logLine = `<span style="color: grey;">[${logData.timestamp}]</span> <span style="color: ${color};">**[${logData.level}]**</span> (${logData.source}): ${logData.message}\n`;logDisplay.innerHTML += logLine;logDisplay.scrollTop = logDisplay.scrollHeight;} catch (e) {console.error("Error parsing log:", event.data);}};source.onerror = function(e) {logDisplay.innerHTML += '\n--- SSE CONNECTION CLOSED / ERROR ---\n';source.close();};} else {document.getElementById('log-display').textContent = "Browser tidak mendukung Server-Sent Events.";}</script>{% endblock %}"""
        }
        
        for filename, content in TEMPLATES.items():
            os.makedirs('templates', exist_ok=True)
            with open(os.path.join('templates', filename), 'w') as f:
                f.write(content)

        print("✅ Semua file proyek (app.py, HTML, runner.sh) berhasil dibuat.")
    
    except Exception as e:
        print(f"❌ ERROR KRITIS saat menulis file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    create_files()
