-- SPMB SMAN 3 TAMBUN SELATAN - FINAL 3 JALUR (Tanpa Lantai 2)
-- Jalur
create table if not exists jalur (
  id text primary key,
  nama text,
  kuota int,
  persen int
);
delete from jalur;
insert into jalur values 
('zonasi','Zonasi',180,50),
('prestasi_akademik','Prestasi Akademik',90,25),
('prestasi_non','Prestasi Non Akademik',90,25);

-- Profiles
create table if not exists profiles (
  id uuid primary key references auth.users(id),
  role text check (role in ('siswa','panitia','admin')),
  nisn text unique,
  nama text
);

-- Pendaftar
create table if not exists pendaftar (
  id uuid primary key default gen_random_uuid(),
  nisn text,
  nama text,
  jalur_id text references jalur(id),
  status text default 'pending',
  created_at timestamp default now()
);

-- Berkas
create table if not exists berkas (
  id uuid primary key default gen_random_uuid(),
  pendaftar_id uuid references pendaftar(id),
  jenis text,
  file_url text,
  verified boolean default false
);

-- Antrian FIFO
create table if not exists antrian_verifikasi (
  id uuid primary key default gen_random_uuid(),
  pendaftar_id uuid references pendaftar(id),
  created_at timestamp default now(),
  status text default 'pending'
);

-- FIFO Query: SELECT * FROM antrian_verifikasi WHERE status='pending' ORDER BY created_at ASC FOR UPDATE SKIP LOCKED LIMIT 1;
