# SPMB Daftar Ulang - SMA Negeri 3 Tambun Selatan
Final Version V7 - 3 Jalur, Tanpa Lantai 2, Dengan Suara Google TTS

Jalur:
- Zonasi 50% (180)
- Prestasi Akademik 25% (90)
- Prestasi Non Akademik 25% (90)

## Deploy Tanpa Command (Drag & Drop)

### Github (via web):
1. Buat repo baru di github.com/new -> spmb-sman3-tamsel
2. Klik Add file -> Upload files
3. Drag SEMUA isi folder ini (index.html, vercel.json, api/, supabase/)
4. Commit changes

### Vercel (via web):
1. vercel.com -> Add New -> Project -> Import repo spmb-sman3-tamsel
2. Framework: Other
3. Env Vars (Settings -> Environment Variables):
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
4. Deploy

Frontend: index.html (prototype clean professional)
Backend: api/index.py (Python FastAPI)
Database: Supabase (schema.sql)

Suara pemanggilan: Web Speech API id-ID, toggle di dashboard panitia.
