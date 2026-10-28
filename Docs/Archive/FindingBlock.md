# FindingBlock

Catatan implementasi sebelum refactor struktur. Untuk lokasi file dan status alur terbaru, lihat [ScreenMap](../ScreenMap.md); untuk hasil pemeriksaan task ini, lihat [Verification](Verification.md).

Logika pembagian wilayah dan GPS mengikuti FindingWaypoint. UI mengikuti Sketch KROPS / CodedUI2: Fertilizer Allocation, Pilih Area Kebun, dan Navigasi Area.

## Alur dan tampilan
- Detail Kebun hanya satu tombol utama: Ajukan peninjauan sebelum pengajuan; Lihat hasil peninjauan setelah pengajuan.
- Status pengajuan tetap terbuka setelah submit; gesture tahan judul untuk simulasi tetap tersedia.
- Alokasi: MapKit satelit setinggi 206 pt, poligon putih, pilihan Area berbentuk capsule, Buka Map, kartu periode dari laporan.
- Pilihan Area: sheet dengan pencarian kode, thumbnail geometri, centang pilihan dan konfirmasi.
- Navigasi: MapKit layar penuh, header Navigasi dan tombol X, penanda pejalan kaki, serta kartu kaca jarak/Area di bawah.
- Tidak ada formulir alokasi manual, diagram warna eksperimen, tombol Mulai, segmented picker blok, atau tombol tambahan di profil.
- Data periode/dosis ditampilkan hanya bila tersedia pada laporan, dipadankan dengan kode area. Data hara, biaya, dan cuaca tidak dibuat dari luas lahan.
- File BlockAllocation dan BlockThumbnail lama tetap tersedia sebagai utilitas, tetapi tidak dipakai oleh UI ini.

## Logika
Batas kebun aktif dibagi menjadi dua kolom dan tiga baris dengan luas seimbang; kode AA/BA, AB/BB, AC/BC. Triangulasi dan clipping menjaga fragmen di dalam batas kebun cekung. Tujuan di dalam blok. Garis triangulasi internal dihapus dari overlay.
GPS memakai CLLocationUpdate dan CLServiceSession. Sesi dimulai saat layar navigasi aktif, berhenti ketika ditutup/tidak aktif. Posisi lebih tua dari 15 detik diabaikan; garis dan jarak memerlukan Lokasi Tepat dan akurasi <=25 m. Garis menunjukkan arah langsung, bukan rute jalan.
Pembagian mendukung poligon valid sampai 500 titik, rentang lokal <1°. MapKit memerlukan koneksi untuk citra satelit.

## Validasi sebelum refactor
Build berhasil. Tes geometri, luas, identitas kebun, dan GPS sebelumnya lulus. Tes baru kode area serta penghilangan garis triangulasi lulus. Preview alokasi, pilihan area, navigasi, dan profil dipakai untuk memeriksa susunan UI. Pemuatan citra MapKit dan GPS lapangan tetap perlu pemeriksaan perangkat.
