from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="SPMB SMAN 3 Tamsel API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

# Data jalur final - 3 jalur saja
JALUR = [
    {"id": "zonasi", "nama": "Zonasi", "kuota": 180, "persen": 50},
    {"id": "prestasi_akademik", "nama": "Prestasi Akademik", "kuota": 90, "persen": 25},
    {"id": "prestasi_non", "nama": "Prestasi Non Akademik", "kuota": 90, "persen": 25}
]

@app.get("/api/health")
def health():
    return {"status": "ok", "sekolah": "SMA Negeri 3 Tambun Selatan", "tahun": "2026/2027"}

@app.get("/api/jalur")
def get_jalur():
    return JALUR

@app.get("/api/antrian")
def get_antrian():
    return {
        "fifo": "SELECT * FROM antrian_verifikasi WHERE status='pending' ORDER BY created_at ASC",
        "tree": "Jalur -> Syarat",
        "note": "Hubungkan ke Supabase dengan SUPABASE_URL & SUPABASE_KEY di Vercel Env"
    }
