import sqlite3
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = "sman3_tamsel_spcm_secret_key_2026"

def init_db():
    conn = sqlite3.connect('spcm.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS pendaftaran (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nisn TEXT UNIQUE NOT NULL,
            nik TEXT NOT NULL,
            nama TEXT NOT NULL,
            tempat_lahir TEXT NOT NULL,
            tgl_lahir TEXT NOT NULL,
            jk TEXT NOT NULL,
            smp_asal TEXT NOT NULL,
            jalur_ppdb TEXT NOT NULL,
            nama_ortu TEXT NOT NULL,
            no_hp TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'Menunggu Verifikasi',
            catatan_revisi TEXT DEFAULT ''
        )
    ''')
    conn.commit()
    conn.close()

init_db()

def get_db_connection():
    conn = sqlite3.connect('spcm.db')
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/daftar', methods=['GET', 'POST'])
def daftar():
    if request.method == 'POST':
        try:
            nisn = request.form['nisn']
            nik = request.form['nik']
            nama = request.form['nama']
            tempat_lahir = request.form['tempat_lahir']
            tgl_lahir = request.form['tgl_lahir']
            jk = request.form['jk']
            smp_asal = request.form['smp_asal']
            jalur_ppdb = request.form['jalur_ppdb']
            nama_ortu = request.form['nama_ortu']
            no_hp = request.form['no_hp']

            conn = get_db_connection()
            conn.execute('''
                INSERT INTO pendaftaran (nisn, nik, nama, tempat_lahir, tgl_lahir, jk, smp_asal, jalur_ppdb, nama_ortu, no_hp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (nisn, nik, nama, tempat_lahir, tgl_lahir, jk, smp_asal, jalur_ppdb, nama_ortu, no_hp))
            conn.commit()
            conn.close()

            flash('Pendaftaran berhasil! Silakan cek status pendaftaran secara berkala.', 'success')
            return redirect(url_for('cek_status'))
        except sqlite3.IntegrityError:
            flash('Error: NISN sudah terdaftar di sistem!', 'danger')
            return redirect(url_for('daftar'))

    return render_template('daftar.html')

@app.route('/cek-status', methods=['GET', 'POST'])
def cek_status():
    siswa = None
    if request.method == 'POST':
        nisn = request.form.get('nisn')
        tgl_lahir = request.form.get('tgl_lahir')

        conn = get_db_connection()
        siswa = conn.execute('SELECT * FROM pendaftaran WHERE nisn = ? AND tgl_lahir = ?', (nisn, tgl_lahir)).fetchone()
        conn.close()

        if not siswa:
            flash('Data tidak ditemukan! Periksa kembali NISN dan Tanggal Lahir.', 'danger')

    return render_template('cek_status.html', siswa=siswa)

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        if username == "panitia_sman3" and password == "tamsel2026":
            session['is_admin'] = True
            session['username'] = username
            return redirect(url_for('admin_dashboard'))
        else:
            flash('Username atau Password Panitia Salah!', 'danger')

    return render_template('admin_login.html')

@app.route('/admin/dashboard')
def admin_dashboard():
    if not session.get('is_admin'):
        return redirect(url_for('admin_login'))

    conn = get_db_connection()
    pendaftar = conn.execute('SELECT * FROM pendaftaran ORDER BY created_at ASC').fetchall()
    conn.close()

    return render_template('admin_dashboard.html', antrean=pendaftar)

@app.route('/admin/verifikasi/<int:id>/<string:status>', methods=['POST'])
def verifikasi(id, status):
    if not session.get('is_admin'):
        return redirect(url_for('admin_login'))

    catatan = request.form.get('catatan', '')
    
    conn = get_db_connection()
    conn.execute('UPDATE pendaftaran SET status = ?, catatan_revisi = ? WHERE id = ?', (status, catatan, id))
    conn.commit()
    conn.close()

    flash(f'Status pendaftar berhasil diperbarui menjadi {status}.', 'info')
    return redirect(url_for('admin_dashboard'))

@app.route('/admin/logout')
def admin_logout():
    session.clear()
    return redirect(url_for('admin_login'))

if __name__ == '__main__':
    app.run(debug=True, port=5000)
