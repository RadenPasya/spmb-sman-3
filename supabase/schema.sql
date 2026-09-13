
-- =====================================================
-- SPMB SMA NEGERI 3 TAMBUN SELATAN
-- SISTEM ANTREAN FIFO - V1
-- =====================================================

create extension if not exists pgcrypto;

-- Hapus tabel lama yang berhubungan dengan dokumen.
drop table if exists berkas cascade;

-- Hapus tabel antrean lama agar struktur bersih.
drop table if exists antrian_verifikasi cascade;
drop table if exists pendaftar cascade;
drop table if exists jalur cascade;

-- =====================================================
-- 1. DATA JALUR
-- =====================================================

create table jalur (
  id text primary key,
  nama text not null,
  kuota integer not null check (kuota > 0),
  persen integer not null check (persen >= 0 and persen <= 100)
);

insert into jalur (id, nama, kuota, persen) values
  ('zonasi', 'Zonasi', 180, 50),
  ('prestasi_akademik', 'Prestasi Akademik', 90, 25),
  ('prestasi_non', 'Prestasi Non Akademik', 90, 25);

-- =====================================================
-- 2. PENDAFTAR
-- Tidak ada kolom upload dokumen.
-- =====================================================

create table pendaftar (
  id uuid primary key default gen_random_uuid(),
  nomor_pendaftaran text not null unique,
  nama text not null,
  nisn text not null unique,
  jalur_id text not null references jalur(id),
  status text not null default 'pending'
    check (status in ('pending', 'dipanggil', 'selesai', 'ditolak')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================
-- 3. ANTREAN FIFO
-- Satu nomor antrean untuk setiap pendaftar.
-- =====================================================

create table antrian_verifikasi (
  id uuid primary key default gen_random_uuid(),
  pendaftar_id uuid not null unique references pendaftar(id) on delete cascade,
  nomor_antrian integer not null,
  jalur_id text not null references jalur(id),
  status text not null default 'pending'
    check (status in ('pending', 'dipanggil', 'selesai', 'ditolak')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (jalur_id, nomor_antrian)
);

-- =====================================================
-- 4. NOMOR URUT PER JALUR
-- =====================================================

create table counter_antrian (
  jalur_id text primary key references jalur(id),
  nomor_terakhir integer not null default 0
);

insert into counter_antrian (jalur_id)
select id from jalur;

-- =====================================================
-- 5. PROFIL ADMIN
-- Buat user admin terlebih dahulu di Supabase Auth.
-- Lalu masukkan UUID-nya ke tabel ini.
-- =====================================================

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin'
    check (role in ('admin'))
);

-- =====================================================
-- 6. FUNGSI PENGECEKAN ADMIN
-- =====================================================

create or replace function is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

-- =====================================================
-- 7. FUNGSI PENDAFTARAN PUBLIK
-- Tidak membutuhkan login.
-- Nomor dibuat secara atomik dan FIFO.
-- =====================================================

create or replace function daftar_spmb(
  p_nama text,
  p_nisn text,
  p_jalur_id text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nama text;
  v_nisn text;
  v_nomor integer;
  v_id uuid;
  v_nomor_pendaftaran text;
begin
  v_nama := trim(p_nama);
  v_nisn := trim(p_nisn);

  if v_nama = '' or v_nisn = '' then
    raise exception 'Nama dan NISN wajib diisi';
  end if;

  if length(v_nama) > 120 or length(v_nisn) > 30 then
    raise exception 'Data pendaftaran terlalu panjang';
  end if;

  if not exists (
    select 1 from jalur where id = p_jalur_id
  ) then
    raise exception 'Jalur tidak valid';
  end if;

  -- Mengunci counter jalur agar nomor tidak bentrok.
  select nomor_terakhir
  into v_nomor
  from counter_antrian
  where jalur_id = p_jalur_id
  for update;

  v_nomor := v_nomor + 1;

  update counter_antrian
  set nomor_terakhir = v_nomor
  where jalur_id = p_jalur_id;

  v_nomor_pendaftaran :=
    'SPMB-' || to_char(now(), 'YYYY') || '-' ||
    lpad(v_nomor::text, 4, '0');

  insert into pendaftar (
    nomor_pendaftaran,
    nama,
    nisn,
    jalur_id
  )
  values (
    v_nomor_pendaftaran,
    v_nama,
    v_nisn,
    p_jalur_id
  )
  returning id into v_id;

  insert into antrian_verifikasi (
    pendaftar_id,
    nomor_antrian,
    jalur_id
  )
  values (
    v_id,
    v_nomor,
    p_jalur_id
  );

  return json_build_object(
    'id', v_id,
    'nomor_pendaftaran', v_nomor_pendaftaran,
    'nomor_antrian', v_nomor,
    'jalur_id', p_jalur_id,
    'status', 'pending'
  );

exception
  when unique_violation then
    raise exception 'NISN sudah terdaftar';
end;
$$;

-- =====================================================
-- 8. RLS
-- =====================================================

alter table jalur enable row level security;
alter table pendaftar enable row level security;
alter table antrian_verifikasi enable row level security;
alter table counter_antrian enable row level security;
alter table profiles enable row level security;

create policy "Publik dapat melihat jalur"
on jalur for select
to anon, authenticated
using (true);

create policy "Admin dapat melihat pendaftar"
on pendaftar for select
to authenticated
using (is_admin());

create policy "Admin dapat mengubah pendaftar"
on pendaftar for update
to authenticated
using (is_admin())
with check (is_admin());

create policy "Admin dapat melihat antrean"
on antrian_verifikasi for select
to authenticated
using (is_admin());

create policy "Admin dapat mengubah antrean"
on antrian_verifikasi for update
to authenticated
using (is_admin())
with check (is_admin());

create policy "Admin dapat melihat profil"
on profiles for select
to authenticated
using (id = auth.uid());

-- Hanya fungsi terkontrol yang boleh membuat pendaftaran.
revoke insert, update, delete on pendaftar from anon, authenticated;
revoke insert, update, delete on antrian_verifikasi from anon, authenticated;
revoke all on counter_antrian from anon, authenticated;

grant execute on function daftar_spmb(text, text, text)
to anon, authenticated;

-- =====================================================
-- 9. REALTIME
-- =====================================================

alter table pendaftar replica identity full;
alter table antrian_verifikasi replica identity full;

alter publication supabase_realtime
add table pendaftar;

alter publication supabase_realtime
add table antrian_verifikasi;
