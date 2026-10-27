# Implementasi CodedUI2

Sumber: dokumen Sketch KROPS, page CodedUI2 (8DE4612E-1AC7-45FD-ACC8-1812F7C8915C).
Audit 25 Oktober 2026: struktur frame dan teks seluruh alur diperiksa; screenshot digunakan untuk registrasi, profil, hasil, pilihan area, navigasi, dan unduhan.

| Alur | Implementasi |
| --- | --- |
| Panduan pendaftaran | Panduan batas lalu satu layar Cari alamat. |
| Cari alamat | Alamat dan point of interest, lokasi perangkat, dan foto dalam satu layar; loading, kosong, gagal, pembatalan pencarian. |
| Lokasi foto | EXIF dibaca, lalu peta konfirmasi “Ya, Ini kebun saya” / “Cari Lagi”. |
| Batas kebun | Satelit berwarna, titik dan jarak, luas/perimeter, urungkan/hapus, validasi batas, konfirmasi ke Data kebun. |
| Lakukan Nanti | Draf lokasi tersimpan di mapping-drafts.json; kartu Lanjutkan pemetaan; saat dilanjutkan peta meminta lokasi perangkat dan mengikuti posisi. |
| Data kebun | Pilihan Mineral, Gambut, Lainnya; nilai tanah lama tetap dapat diedit. Tahun/bulan tanam dan riwayat lama dipertahankan. |
| Profil/riwayat | Komponen riwayat yang sudah sesuai dipakai kembali; header Detail Kebun dan indikator peninjauan diperbarui. |
| Pengajuan | Informasi → persetujuan → Lanjutkan → formulir kontak → layanan submit → simpan status → Status Pengajuan. |
| Status | Submitted, scheduled, in review, completed dari data layanan; pembaruan ketika profil dibuka dan pull to refresh. |
| Proyeksi hara | Legenda, kebutuhan, kondisi tiap unsur, ringkasan, tabel biaya, dan sheet referensi berdasarkan data laporan. |
| Alokasi | Pilihan area dengan pencarian dan konfirmasi; dosis per periode; peta area dengan geometri laporan. |
| Navigasi | Polygon area, lokasi GPS, arah langsung dan jarak ke target laporan; penanganan izin, akurasi, GPS kedaluwarsa. |
| Curah hujan | Grafik tujuh hari, ikon, judul dan ringkasan dari laporan; kondisi kosong jika data belum tersedia. |
| Unduhan | URL laporan → progres dan jumlah byte → file lokal → berbagi/buka file. Task tetap berjalan ketika meninggalkan halaman, selama aplikasi masih berjalan. |

## Integrasi layanan

Layanan backend belum tersedia dalam project. Default ReviewService melempar error yang jelas; aplikasi tidak menganggap pengajuan berhasil tanpa respons layanan.

Sediakan ReviewService(submit:refresh:) melalui environment reviewService pada ContentView.
- submit menerima Garden dan ReviewContactDetails, lalu mengembalikan GardenReview dari respons server.
- refresh menerima Garden dengan requestID tersimpan, lalu mengembalikan status/laporan terbaru atau nil bila tidak berubah.
- Transport harus memakai idempotency untuk pengajuan agar retry jaringan tidak membuat permintaan ganda.
- Laporan menyediakan nilai hara dan kebutuhannya, status unsur, ringkasan, referensi pupuk, biaya, periode dosis, curah hujan, URL unduhan, polygon area, dan navigationTarget.
- Nomor/kode area dan target navigasi berasal dari laporan, bukan pembagian zona eksperimen.
- Unduhan mengharapkan URL file yang dapat diakses URLSession. Belum ada konfigurasi autentikasi khusus atau unduhan sistem di background.
- Setelah laporan diunduh, file disimpan di Application Support/ReviewReports. Peta satelit tetap bergantung pada MapKit.

Data pada RecommendationPreviewData hanya contoh dari desain dan hanya dikompilasi pada DEBUG; bukan hasil analisis kebun atau prakiraan cuaca aktual.

## Validasi

- BuildProject berhasil.
- Swift Testing: 19 tes lulus, mencakup penyimpanan lama, kegagalan tulis, draf yang bertahan setelah relaunch, laporan Codable, dan pembaruan status yang mempertahankan riwayat terbaru.
- Interaksi simulator: panduan → pencarian landmark publik → peta → empat titik batas → Data kebun → pilihan tanah.
- Preview diperiksa: pencarian, proyeksi hara, alokasi, curah hujan, referensi nitrogen, progres unduhan, dan Dynamic Type AX 1. Legenda dan baseline grafik diperbaiki dari hasil render.
- Belum diverifikasi dengan layanan nyata: pengiriman, status server, laporan/cuaca aktual, dan unduhan jaringan.
- Pengujian foto geotagged dan GPS berjalan di kebun memerlukan perangkat/foto yang sesuai. Citra satelit pada simulator pengujian tidak termuat, meskipun pencarian, koordinat, polygon, dan perhitungan batas berfungsi.

Preview tambahan berada di PreviewSupport/ReferenceScreens/CodedUI2FlowPreviews.swift.

## Pemeriksaan lanjutan status pengajuan

- Dibandingkan kembali dengan frame CodedUI2 Status Pengajuan Submitted dan screenshot Completed.
- Jarak teks timeline dan warna garis disesuaikan; bagian bawah konten diberi ruang untuk scrolling.
- Jika URL laporan tersedia, tombol “Lihat & unduh hasil” memulai unduhan dan membuka hasil.
- Pada build DEBUG, submit yang menghasilkan ReviewServiceError.unavailable membuka simulasi lokal setelah validasi formulir. Error layanan lainnya tetap ditampilkan.
- Tahan teks judul “Status Pengajuan” selama 1 detik, lepaskan, lalu ulangi untuk maju dari submitted → scheduled → inReview → completed. Tidak ada tombol lanjut yang terlihat.
- Status simulasi disimpan per ID kebun melalui GardenStore ke gardens.json, termasuk setiap perpindahan tahap. Penanda isLocalSimulation membedakannya dari respons server; refresh layanan dilewati untuk simulasi. Keluar dari profil atau relaunch tidak menghapus status. Penyimpanan gagal menampilkan error dan tidak memajukan status. Data simulasi lama yang hanya berada di state halaman tidak dapat dipulihkan setelah halaman ditutup.
- Setelah completed, “Lihat hasil peninjauan” membuka laporan lokal dari kebun aktif. FindingBlock menangani enam blok dari batas kebun, tampilan periode dari laporan bila tersedia, dan panduan GPS. Hara, biaya, dan hujan tidak diisi dengan data contoh. Detail Kebun hanya memiliki satu tombol utama: “Ajukan peninjauan” lalu “Lihat hasil peninjauan”. UI FindingBlock mengikuti Sketch dengan overlay area putih di atas MapKit, sheet pilihan area, dan kartu jarak kaca.
- Release tetap menggunakan layanan asli; fallback demo hanya tersedia pada DEBUG.
- Validasi lanjutan: BuildProject berhasil; 3 tes terkait laporan, pembaruan review, dan layanan unavailable lulus; preview status completed diperiksa.
- Gesture end-to-end belum diverifikasi: tool simulator membutuhkan skill device-interaction yang tidak tersedia dalam sesi ini.

