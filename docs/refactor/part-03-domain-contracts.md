# Hasil Part 3 - Domain dan kontrak repository

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/03-domain-contracts`. Acuan: `5972ac9`.

Commit implementasi dan test: `585e014`. Catatan serta bukti verifikasi disimpan pada commit dokumentasi terpisah.

Pelaksanaan langsung melalui file/Terminal; tidak membuat materi tutorial, menggunakan computer use, push, atau PR.

## Perubahan

- Domain hanya mengimpor Foundation dan berhasil dikompilasi sendiri sebagai module sementara untuk verifikasi. App tetap memakai satu target/module yang sama.
- Konversi koordinat dan pengukuran perimeter berbasis CoreLocation dipindahkan ke `Data/Location/GardenGeometry+CoreLocation.swift` dengan isi helper identik.
- Label jenis tanah, judul draf, judul status, serta format timeline dipindahkan ke SharedUI. Isi helper timeline/status dipertahankan; file implementasi status/hasil tim tidak diedit.
- Aturan kelengkapan profil berada di Domain. Stage/filter/list item tetap model presentation pada fitur daftar; pengaturan developer berada di App.
- Validasi data kebun, pupuk, panen, dan kontak dipusatkan di Domain lalu dipakai form yang ada. Aturannya tetap sama: tidak memperketat tahun tanam, mengubah batas frekuensi panen, atau menormalisasi format nomor telepon pada payload.
- Dua jalur submit memakai pembentuk snapshot `PlantationReviewRequest(garden:contact:)` yang sama.
- GardenStore menerima `any FarmerReviewRepository` dan menggunakan operasi pada kontrak tersebut. Default runtime tetap CloudKit; repository fake dipakai dalam test untuk membuktikan refresh, submit sukses, dan submit gagal tanpa write CloudKit.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Kompilasi Domain mandiri dengan Foundation | Berhasil, tanpa diagnostic |
| Test Debug iPhone 18 Pro iOS 27.0 | 29 lulus, 0 gagal, 0 skipped; sebelumnya 18 test |
| Build Debug | Berhasil, 0 error, 8 warning yang sama dengan Part 2 |
| Build Release simulator | Berhasil, 0 error, 3 warning yang sama dengan Part 2 |
| File runtime/configuration yang dilindungi | 27 file identik dengan acuan |
| Body helper timeline/status/koordinat/perimeter | Hash isi cocok sebelum dan sesudah dipindahkan |
| Format Git | `git diff --check` lulus |

Sebelas test baru memeriksa batas dan normalisasi input yang lama, kesiapan profil, adapter geodesic, fixture JSON lengkap beserta raw values/tanggal review, snapshot payload CloudKit, proyeksi refresh, eviction sesudah submit sukses, serta draf tetap persisten ketika submit ditolak.

Bukti:

- [Test Debug](evidence/part-03-tests-summary.json).
- [Build Debug](evidence/part-03-debug-build-summary.json).
- [Build Release](evidence/part-03-release-build-summary.json).
- [Kompilasi Domain dan hash file/helper yang dipertahankan](evidence/part-03-boundary-verification.json).

Result bundle/log lengkap berada di `/private/tmp/palm-oil-part3.D49m8w`. Domain dikompilasi dengan `xcrun swiftc -swift-version 5 -parse-as-library -emit-module`, memakai seluruh file di `PalmOilFarmer/Domain`, module sementara `PalmOilDomain`, dan output/cache di folder sementara tersebut. Build/test memakai Xcode 27.0 dan destination yang sama dengan baseline; DEVELOPER_DIR dipilih per proses, tidak diubah global.

## Kompatibilitas dan batas pekerjaan

Nama dan stored properties model Codable/SwiftData, DTO, CKRecord adapter, CloudKit repository, app identity, project/scheme, entitlements, serta konfigurasi dipertahankan. Kebijakan SwiftData untuk draf dan CloudKit untuk submitted tetap sama; cache submitted dan migrasi data tidak ditambahkan.

Seluruh file yang sudah ada pada ReviewStatus, Recommendations, AreaGuidance, MapDownload, Experiments, dan Data/Reviews tetap identik. Model hasil pada PlantationReviewModels juga dipertahankan. Relokasi helper presentation tidak mengubah pesan, format tanggal, atau transisi status.

Part 3 belum mengganti orkestrasi GardenStore menjadi use case, memisahkan repository lokal, menghilangkan default singleton pada composition, atau mengganti akses CloudKit langsung pada profil. Ini pekerjaan tahap Data/composition dan migrasi fitur berikutnya, sebelum penerapan ViewModel/Coordinator.

Tidak ada UI smoke test, Archive, upload TestFlight, verifikasi upgrade, atau verifikasi operator baru. Pemeriksaan manual/identitas build yang masih terbuka pada baseline tetap belum diklaim selesai. Dokumen analisis lama yang sudah untracked tidak dimasukkan ke commit.
