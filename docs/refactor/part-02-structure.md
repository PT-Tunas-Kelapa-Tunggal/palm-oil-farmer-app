# Hasil Part 2 - Struktur folder dan batas fitur

Tanggal: 4 November 2026 (Asia/Jakarta).

Status: pemindahan selesai, pengujian otomatis lulus, checkpoint lokal. Pelaksanaan memakai file dan Terminal; tidak menggunakan computer use, tidak push, dan tidak membuat PR.

## Acuan dan commit

| Item | Nilai |
| --- | --- |
| Branch awal | `refactor/01-baseline` |
| Commit awal Part 2 | `fca7dd1` |
| Baseline implementasi Swift | `43e413f` |
| Branch pekerjaan | `refactor/02-feature-folders` |
| Commit pemindahan | `663959a` |
| Isi commit pemindahan | 60 rename `R100`, 0 baris ditambah, 0 baris dihapus |
| Dokumentasi dan bukti | Disimpan pada commit terpisah sesudah pemindahan |

## Perubahan struktur

Folder `Features/Gardens` tidak lagi menjadi payung seluruh alur. Struktur baru memisahkan:

- `Domain/Gardens` dan `Domain/Reviews` untuk nilai dan kontrak yang sudah ada.
- `Data/Gardens`, `Data/Reviews`, dan `Data/Location` untuk implementasi penyimpanan/remote/lokasi saat ini.
- Fitur sejajar: `GardenList`, `GardenRegistration`, `GardenProfile`, `GardenHistory`, `ReviewRequest`, `ReviewStatus`, `Recommendations`, `AreaGuidance`, dan `MapDownload`.
- `SharedUI/Maps` dan `SharedUI/Gardens` untuk komponen/presentation value yang dipakai bersama.
- `Experiments/FindingWaypoint` untuk entry point eksperimen, layar peta, serta thumbnail/preview yang tetap utuh.

Mapping tetap menjadi bagian GardenRegistration. Pengajuan dipisahkan dari status agar batas kepemilikan terlihat. Session GPS dan zoning yang dipakai ulang dipindahkan keluar dari entry point eksperimen.

Peta lengkap setiap file dan hash isi pada checkpoint pemindahan tersedia di [bukti rename](evidence/part-02-renames.tsv). Terdapat 59 file Swift dan satu README yang berpindah. Seluruh file Swift mempertahankan isi byte-for-byte.

README eksperimen kemudian diperbarui dalam perubahan dokumentasi untuk menjelaskan lokasi baru. Hash README pada bukti rename merujuk checkpoint pemindahan `663959a`, sebelum pembaruan penjelasan tersebut.

## Batas implementasi yang dipertahankan

- Tidak ada perubahan Swift, termasuk status/timeline, report, demo/fallback, download, eksperimen, dan panduan area milik implementasi tim.
- App/module, test, project/scheme, assets, entitlements, serta konfigurasi tracked tidak diubah.
- Nama dan properti model SwiftData, lokasi store, DTO/field CloudKit, serta enum raw values dipertahankan.
- Pendekatan draf SwiftData dan submitted CloudKit tetap sama. Tidak menambahkan cache submitted atau migrasi storage.
- Tidak membuat ViewModel, Coordinator, use case, repository baru, target baru, atau package baru pada part ini.

Ini merupakan struktur transisi menuju Clean Architecture + MVVM-C. GardenStore masih menggabungkan state dan data; GardenBoundary masih mempunyai konversi CoreLocation; model review masih membentuk timeline UI; LiveGardenReader masih membaca store konkret; GardenDetailsView masih dipakai profil dan registrasi. Batas tersebut dicatat dalam tutorial, bukan diselesaikan melalui perubahan di luar scope pemindahan.

## Hasil pemeriksaan

| Pemeriksaan | Hasil |
| --- | --- |
| Rename saat staging/commit pertama | 60 `R100`; 59 Swift dan satu README |
| Hash isi file pada pemindahan | Seluruh file cocok dengan snapshot sebelum pemindahan |
| Test Debug iPhone 18 Pro iOS 27.0, arm64 | 18 lulus, 0 gagal, 0 skipped |
| Build Debug melalui test action | Succeeded, 0 error, 8 warning |
| Perbandingan warning Debug | Jenis/pesan dan jumlah sama dengan baseline Part 1 |
| Build Release generic iOS Simulator | Succeeded, 0 error, 3 warning |
| Pemeriksaan format Git | `git diff --check` lulus |
| UI/manual smoke baru | Tidak dijalankan pada Part 2 sesuai batas tanpa computer use |
| Archive, TestFlight, dan upgrade data | Tidak dijalankan; tidak diklaim lulus |

Bukti resmi Xcode:

- [Ringkasan test Debug](evidence/part-02-tests-summary.json).
- [Ringkasan build Debug](evidence/part-02-debug-build-summary.json).
- [Ringkasan build Release](evidence/part-02-release-build-summary.json).

Release yang diperiksa adalah kompilasi untuk simulator. Tidak ada Run Production, upload, atau pengajuan baru yang dikirim oleh pemeriksaan ini. Warning actor isolation yang sudah ada dicatat tanpa diperbaiki dalam commit pemindahan.

## Reproduksi pemeriksaan

Dijalankan dari root repository dengan Xcode 27.0, build `27A266a`. Directory developer dipilih khusus proses, tanpa mengubah pengaturan global.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project PalmOilFarmer.xcodeproj \
  -scheme PalmOilFarmer \
  -destination 'platform=iOS Simulator,id=BD8D68EA-DE49-4AF3-A283-69D78F6984C3' \
  -derivedDataPath /private/tmp/palm-oil-part2.Lvb8LG/Debug \
  -resultBundlePath /private/tmp/palm-oil-part2.Lvb8LG/DebugTests.xcresult \
  -parallel-testing-enabled NO \
  -quiet
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project PalmOilFarmer.xcodeproj \
  -scheme PalmOilFarmer \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/palm-oil-part2.Lvb8LG/Release \
  -resultBundlePath /private/tmp/palm-oil-part2.Lvb8LG/ReleaseBuild.xcresult \
  -quiet
```

Log dan result bundle lengkap berada dalam directory sementara di atas. Gunakan nama result bundle baru saat mengulang. Bukti JSON ringkas disimpan di Git agar hasil tidak hanya bergantung pada file sementara.

## Dokumentasi yang diperbarui

- README root: lokasi fitur/layer baru, kondisi transisi, aturan kompatibilitas data, serta deskripsi penyimpanan/review sesuai implementasi sekarang.
- README eksperimen: lokasi session GPS dan geometri yang dipakai produksi.
- Tutorial Part 1: link source aktif diarahkan ke tujuan baru. Uraian snapshot baseline tetap menjelaskan keadaan sebelum pemindahan.
- Tutorial Part 2: catatan bahwa pelaksanaan telah didelegasikan dan selesai; perintah manual tetap menjadi bahan belajar, bukan untuk dijalankan ulang pada checkout ini.

Dokumen analisis awal yang sudah untracked sebelum pekerjaan ini tidak dimasukkan ke commit. Catatan baseline Part 1 tetap dipertahankan, termasuk pemeriksaan UI yang belum lengkap dan identitas TestFlight yang belum terverifikasi.

## Checkpoint

- [x] Struktur fitur sejajar dan batas lokasi file diterapkan.
- [x] Seluruh Swift tetap identik; konfigurasi dan kontrak data dipertahankan.
- [x] Test Debug serta kompilasi Release simulator berhasil.
- [x] Pemindahan disimpan terpisah dari perubahan dokumentasi.
- [x] Tidak ada push, PR, atau computer use pada sesi Part 2.
- [ ] Lengkapi verifikasi perilaku/upgrade yang masih terbuka pada baseline sebelum menyatakan seluruh integrasi rilis sudah teruji.

Langkah berikutnya adalah Part 3: memisahkan nilai/validasi/kontrak sesuai scope sampai pengajuan. Struktur baru belum menggantikan pekerjaan pemisahan dependency tersebut.
