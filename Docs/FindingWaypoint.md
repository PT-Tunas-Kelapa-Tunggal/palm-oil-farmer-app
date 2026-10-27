# Finding Waypoint — eksperimen

Implementasi berada di `PalmOilFarmer/Features/FindingWaypoint/{Models,Data,Views}`; fixture berada di PreviewSupport. Tidak ada perubahan ke app entry point, model Garden, penyimpanan zona, assets, atau target pengujian.

## Menjalankan

- Buka FindingWaypointFlow.swift dan pilih preview “Finding Waypoint — data tersimpan” untuk tab Home/Pemupukan.
- Preview “Pemupukan — contoh” dan “Zona 5” menggunakan data contoh yang tidak disimpan.
- Untuk berjalan dengan GPS pada iPhone, **pengembang perlu mengganti sementara ContentView() dengan FindingWaypointFlow() di WindowGroup PalmOilFarmerApp.swift**, lalu Run ke iPhone. Perubahan ini sengaja tidak dilakukan oleh implementasi ini karena file tersebut berada di luar folder yang diizinkan.
- Aktifkan internet dan izinkan lokasi saat aplikasi digunakan, termasuk Lokasi Tepat. Project sudah memiliki deskripsi izin lokasi.
- Tab Home memakai GardenStore dan alur registrasi yang sudah ada: tambah/edit/hapus di Home memengaruhi data kebun asli.
- Pemupukan → pilih kebun → pilih zona 1–6 → Mulai panduan. Tombol lokasi mengikuti posisi; menggeser peta melepaskan follow. Tombol peta menampilkan kebun kembali.
- GPS berhenti ketika layar ditutup, tab ditinggalkan, atau aplikasi tidak aktif. Tekan Mulai lagi setelah kembali.

## Batas eksperimen

- Dua kolom barat–timur, masing-masing tiga bagian utara–selatan dengan luas seimbang. Nomor dibaca per baris: 1–2, 3–4, 5–6.
- Persegi panjang menghasilkan grid simetris. Batas tidak beraturan menghasilkan bentuk yang berbeda; zona cekung bisa terdiri atas beberapa bagian terpisah. Ini belum pembagian agronomi atau jaringan jalan.
- Triangulasi lalu pemotongan luas menjaga area di dalam batas, termasuk kebun cekung. Titik tujuan memakai centroid zona jika berada di dalamnya; jika tidak, memakai centroid fragmen terbesar.
- Zona dihitung ulang dari batas, tidak disimpan dan tidak mengubah batas kebun. Belum ada catatan pemupukan per zona.
- Maksimum 500 titik, rentang koordinat lokal kurang dari 1° dari titik awal; batas invalid atau di sekitar kutub/antimeridian tidak diproses.
- Thumbnail merupakan skema geometri ringan. Peta detail memakai citra MapKit online.
- Titik biru dan lingkaran akurasi berasal dari pembaruan Core Location yang sama dengan perhitungan jarak.
- Garis putus-putus adalah arah langsung, bukan rute pejalan kaki dan tidak menghindari sungai, pagar, atau tanaman.
- Data GPS berusia lebih dari 15 detik tidak ditampilkan sebagai posisi aktif. Panduan garis dinonaktifkan bila akurasi lebih buruk dari 25 m atau izin Lokasi Tepat tidak aktif.
- “Dekat titik tujuan” muncul hanya ketika jarak <=15 m dan akurasi <=10 m. Ini indikator perkiraan, bukan konfirmasi tiba atau jaminan zona yang benar. Zona kecil tetap membutuhkan verifikasi lapangan.
- Tidak ada background tracking, offline map, routing internal kebun, atau jaminan akurasi GPS. Kanopi pohon dan kondisi perangkat perlu diuji di kebun.

## Pemeriksaan

Build melalui Xcode berhasil. RunCodeSnippet memeriksa persegi panjang, L, U, titik collinear, segitiga, masing-masing dalam dua arah urutan: enam zona, luas total, keseimbangan luas, waypoint di dalam fragmen. Batas menyilang/kosong dan GPS invalid/kedaluwarsa juga diperiksa.

Preview daftar berhasil dirender. Snapshot peta dapat tertangkap sebelum citra/overlay MapKit dimuat; pemeriksaan interaksi peta dan jalan kaki tetap harus dilakukan pada perangkat.

Uji perangkat yang perlu dilakukan:
1. Berjalan menuju zona 5, pantau titik biru, jarak, pemilihan zona dan tombol follow.
2. Tolak izin, matikan Lokasi Tepat, lalu pulihkan melalui Pengaturan.
3. Hentikan/mulai cepat, kunci layar, pindah tab, kembali ke aplikasi.
4. Uji sinyal lemah, tanpa internet, dan kebun dengan zona lebih kecil dari ketelitian GPS.
5. Pastikan batas kebun dan akses lapangan sesuai sebelum mengandalkan panduan.
