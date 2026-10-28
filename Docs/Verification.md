# Verifikasi refactor SwiftUI

> Catatan historis. Struktur folder telah diperbarui menjadi Features langsung dan Shared/Gardens. Gunakan [Architecture](Architecture.md) untuk struktur saat ini dan [FeatureFoldersVerification](FeatureFoldersVerification.md) untuk pemeriksaan terbaru. Tautan source dalam dokumen ini mengikuti lokasi sekarang; uraian dan hasil tes tetap merujuk iterasi saat itu.


Tanggal: 27 Oktober 2026. Cakupan: seluruh aplikasi, termasuk Gardens, FindingBlock, FindingWaypoint, design system, resources dan preview. Refactor mempertahankan perilaku baseline; bukan migrasi penyimpanan atau redesain.

## Git

- Branch task: `codex/refactor-swiftui-structure`.
- Baseline pekerjaan pengguna: `df36f86` (47 file: 46 aplikasi/dokumen fitur + satu panduan). Tidak ada reset/stash/amend.
- Perpindahan/rename: `6ea71d2`.
- Pemisahan model, screen dan komponen: `4e2ccb0`.
- Dokumentasi final dibuat dalam commit terpisah sesudah commit kode.
- Remote yang diperiksa: `origin`, `https://github.com/hatamisg/palm-oil.git`. Tidak melakukan push, PR atau merge; permintaan ini mengotorisasi pekerjaan lokal dan commit.

## Build dan test

Xcode 27.0 (27A266a), scheme PalmOilFarmer, test target PalmOilFarmerTests, simulator iPhone 18 Pro / iOS 27.0. Toolchain default mesin menunjuk Command Line Tools; setiap perintah memakai DEVELOPER_DIR untuk Xcode tanpa mengubah pengaturan global. Tidak mengubah deployment target, signing, bundle identifier, target membership, atau project.pbxproj.

| Pemeriksaan | Hasil |
| --- | --- |
| Baseline Debug build + test | Lulus, 28 test dalam 4 suite |
| Setelah perpindahan/rename | Debug build lulus |
| Setelah pemisahan model/komponen | Debug build + 28 test lulus |
| Release setelah pemisahan | Build lulus |
| Debug dan Release final setelah preview SelectionList dilepaskan dari SoilType | Keduanya lulus |
| Suite | PalmOilFarmerTests, GardenStressTests, CodedUI2FlowTests, FindingBlockTests |

Pengujian mencakup persistence/kompatibilitas, gagal-simpan, draf dan review, geometri pembagian blok, serta validasi GPS. Suite bernama FlowTests adalah Swift Testing untuk data/perilaku, bukan otomatisasi tap UI.

Peringatan yang sudah ada pada baseline masih ada: `WaypointPreviewData` memanggil initializer GardenCoordinate yang main-actor-isolated dalam closure sinkron. Lokasi file kini PreviewSupport/Fixtures. Build juga memberi pemberitahuan metadata AppIntents dilewati karena framework tidak dipakai. Tidak ada error build; peringatan concurrency tersebut dicatat sebagai tindak lanjut terpisah.

Perintah pemeriksaan (jalankan dari root repo, pilih simulator iOS 27 yang tersedia):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project PalmOilFarmer.xcodeproj -scheme PalmOilFarmer \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath /tmp/krops-refactor-check
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project PalmOilFarmer.xcodeproj -scheme PalmOilFarmer -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/krops-refactor-check
```

Log dan result bundle sesi disimpan di `/tmp/krops-refactor-*`; bukan file yang di-commit. Harness snapshot sementara berada di salinan repo `/tmp/krops-visual-baseline` dan `/tmp/krops-visual-final`, bukan source/target permanen.

## Perbandingan visual

32 pasangan screenshot pada input dan ukuran yang sama (402 × 874 pt): 8 kasus × light/dark × Dynamic Type large/accessibility3. Kasus: daftar kosong, daftar nama panjang, daftar draf, daftar unduhan, profil lengkap nama panjang, profil riwayat sebagian, status review, rekomendasi hara. Tampilan memakai UIHostingController di simulator iOS 27; gambar UIKit diekspor dari XCTest attachments. Ini perbandingan area yang dirender, bukan semua posisi scroll.

- 31 pasangan identik piksel demi piksel.
- Satu pasangan `list-draft-dark-large` berbeda hanya pada area citra peta: baseline masih grid loading, final sudah memuat satelit. Teks, posisi, ukuran kartu dan tombol di luar area peta identik. Perbedaan tersebut diperiksa secara visual.
- Sampel light/dark, teks panjang dan accessibility diperiksa berdampingan. Susunan yang sudah ada pada baseline tetap dipertahankan, termasuk batas/overflow pada reference profile; task ini tidak meredesain layout.
- Tidak mengubah modifier Reduce Motion/Transparency. Toggle kedua opsi itu belum diuji sebagai matriks visual tersendiri.

Ringkasan hasil numerik disimpan di [VisualComparison.json](VisualComparison.json). Screenshot penuh dan result bundles berada di `/tmp/krops-shots-*` dan `/tmp/krops-visual-*.xcresult`; lokasi sementara dapat dibersihkan sistem.

## Interaksi pada simulator khusus

Menggunakan simulator baru **Krops Refactor QA**, berisi satu kebun sintetis, tanpa memakai data kebun pengguna:

1. Daftar → ketuk kartu → profil: berhasil.
2. Menu edit → ubah nama → Tutup: nama lama tetap ditampilkan.
3. Edit ulang → ubah nama → Simpan: profil diperbarui; JSON diperiksa, ID dan riwayat lama tetap utuh. Keyboard simulator mengoreksi kata Kebun menjadi Kevin; nilai yang tersimpan sesuai nilai yang tampil.
4. Tombol Ubah di section pupuk yang diekstrak → editor pemupukan → tutup → profil: berhasil.
5. Tombol Ubah di section panen yang diekstrak → increment frekuensi → Simpan: profil menampilkan 3 kali per bulan.

Uji gagal-simpan dilindungi test otomatis, tidak diinjeksi ulang melalui UI pada sesi ini. Pendaftaran/pemetaan penuh, foto geotagged, pengiriman layanan nyata, GPS lapangan, seluruh sheet review dan seluruh state scroll belum diuji interaktif ulang. Kode lifecycle, callback dan model untuk alur tersebut dipertahankan dan test relevan lulus.

## Pemeriksaan statis

- Seluruh isi tipe Swift dibandingkan dengan baseline setelah normalisasi rename dan whitespace: tidak ada tipe hilang. Hanya body GardenListScreen dan GardenProfileScreen yang berubah untuk mengganti subtree stateless dengan tiga komponen baru: MappingDraftCard, GardenFertilizerHistorySection, GardenHarvestHistorySection.
- Tipe lainnya mempertahankan body, termasuk model, store, layanan, task GPS dan callback navigasi; private top-level dua komponen yang dipisah menjadi internal, bukan public.
- Semua 29 file aset dibandingkan byte demi byte: identik. Nama dan lookup aset tidak diubah.
- Tidak ada source duplikat atau tipe Screen/Flow yang tertinggal dalam file campuran; setiap Screen/Flow memiliki file bernama sama.
- Tidak ada referensi nama simbol lama di source/test. Nama lama hanya ada dalam panduan/inventaris historis sebagai konteks asal perpindahan.
- Link lokal dokumentasi, daftar Screen/Flow dalam ScreenMap, dan batas dependensi tipe fitur di Core diperiksa.
- Konfigurasi proyek dan test yang sudah ada tidak berubah dari baseline. Semua source baru disertakan dalam commit kode; build tidak bergantung pada file untracked.
