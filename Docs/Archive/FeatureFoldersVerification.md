# Verifikasi fitur langsung di Features

Tanggal: 28 Oktober 2026. Baseline: `075fe49`. Branch lokal: `codex/refactor-gardens-ownership` (melanjutkan branch refactor yang sudah ada).

## Hasil

Area pekerjaan kini langsung berada di Features: GardenList, GardenProfile, GardenDetails, GardenRegistration, GardenMapping, GardenHistory, GardenReview, FertilizerRecommendations, MapDownloads, FindingBlock dan FindingWaypoint. Nilai kebun, persistence, penyedia lokasi bersama dan komponen domain bersama ada di Shared/Gardens. Tidak ada lagi pembungkus Features/Gardens.

76 file dipindahkan. Seluruhnya identik byte demi byte dengan baseline; tidak ada perubahan simbol, isi Swift, API, state, navigasi, lifetime store, task, transport, JSON atau lokasi penyimpanan data. Seluruh source lain, aset, file proyek Xcode dan test juga identik. Proyek menggunakan filesystem synchronized root group sehingga tidak memerlukan referensi source manual.

| Area asal di Features/Gardens | Lokasi baru | Jumlah file |
| --- | --- | --- |
| Details | Features/GardenDetails | 2 |
| History | Features/GardenHistory | 6 |
| List | Features/GardenList | 4 |
| MapDownloads | Features/MapDownloads | 6 |
| Mapping | Features/GardenMapping | 5 |
| Profile | Features/GardenProfile | 7 |
| Recommendations | Features/FertilizerRecommendations | 16 |
| Registration | Features/GardenRegistration | 6 |
| Review | Features/GardenReview | 13 |
| Shared | Shared/Gardens | 11 |

Struktur internal tiap area dipertahankan. FindingBlock dan FindingWaypoint tidak berubah. Tidak menambah Flow, model, lapisan, atau folder kosong. Shared tidak menampung seluruh kode yang sekadar berhubungan dengan kebun: draf tetap di GardenMapping, review di GardenReview, laporan di FertilizerRecommendations.

## Pemeriksaan baru pada iterasi ini

- Build Debug dan seluruh 28 test dalam empat suite lulus: PalmOilFarmerTests, GardenStressTests, CodedUI2FlowTests, FindingBlockTests.
- Build Release lulus.
- Seluruh 76 pasangan asal/tujuan diverifikasi identik terhadap baseline; semua lokasi asal sudah tidak ada, semua tujuan terisi, tidak ada file duplikat atau folder kosong.
- README, Architecture, ScreenMap dan panduan penempatan diperbarui. Link source pada dokumen historis mengikuti lokasi sekarang; uraian dan hasil test historis tidak dianggap pemeriksaan baru.
- Seluruh link lokal dokumentasi dan diff whitespace diperiksa.

Xcode 27.0; simulator iPhone 18 Pro / iOS 27.0. Build/test memakai DEVELOPER_DIR tanpa mengubah konfigurasi toolchain global. Test memakai data sementara. Peringatan WaypointPreviewData tentang main actor dan pemberitahuan metadata AppIntents sudah ada sebelum perpindahan.

Log sementara: `/tmp/krops-feature-folders-tests.log` dan `/tmp/krops-feature-folders-release.log`. Result bundle: `/tmp/krops-feature-folders-tests.xcresult`. Peta 76 perpindahan: `/tmp/krops-feature-folders-moves.json`.

Tidak menjalankan ulang snapshot atau interaksi UI pada iterasi pemindahan ini karena seluruh source aplikasi identik. Hasil visual dan interaksi ekstraksi sebelumnya tersedia di [OwnershipVerification](OwnershipVerification.md); bukan klaim pengujian UI baru. Layanan nyata, GPS dan foto tidak diuji ulang.

## Cara menemukan kode

- Susunan profil: [GardenProfileScreen](../../PalmOilFarmer/Features/GardenProfile/GardenProfileScreen.swift) → [GardenProfileContent](../../PalmOilFarmer/Features/GardenProfile/GardenProfileContent.swift).
- Pengajuan: [ReviewSubmissionView](../../PalmOilFarmer/Features/GardenReview/ReviewSubmissionView.swift) → callback submitReview di GardenProfileScreen → [ReviewService](../../PalmOilFarmer/Features/GardenReview/ReviewService.swift).
- Simpan kebun: callback ke [AppFlow](../../PalmOilFarmer/App/AppFlow.swift) → [GardenStore](../../PalmOilFarmer/Shared/Gardens/GardenStore.swift) → [GardenPersistence](../../PalmOilFarmer/Shared/Gardens/GardenPersistence.swift).

Perubahan disimpan sebagai satu commit lokal perpindahan + dokumentasi. Tidak melakukan push, PR atau merge.
