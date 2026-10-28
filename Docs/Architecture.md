# Arsitektur SwiftUI

Setiap area pekerjaan langsung terlihat di Features. Shared/Gardens berisi kode domain kebun yang digunakan beberapa fitur, sedangkan Core/DesignSystem berisi UI generik. Struktur diperbarui pada 28 Oktober 2026 dari baseline `075fe49`. Mulai dari [peta halaman](ScreenMap.md); [rencana awal](RefactorPlan.md) menyimpan inventaris baseline, bukan peta source terkini.

```text
PalmOilFarmer/
├── App/                              PalmOilFarmerApp → AppFlow
├── Core/DesignSystem/                Tokens, Components, Styles, Catalog
├── Features/
│   ├── GardenList/                   Daftar dan kartu kebun
│   ├── GardenProfile/                Profil dan komponen isi
│   ├── GardenDetails/                Form kebun baru/edit
│   ├── GardenRegistration/           Pilihan lokasi, pencarian, foto
│   ├── GardenMapping/                Batas kebun dan penyimpanan draf
│   ├── GardenHistory/                Editor pupuk/panen dan draf
│   ├── GardenReview/                 Pengajuan, status, layanan, nilai review
│   ├── FertilizerRecommendations/    Laporan, Models, Components
│   ├── MapDownloads/                 Reference unduhan peta
│   ├── FindingBlock/                 Models, Data, Views (+ Components)
│   └── FindingWaypoint/              Models, Data, Views (+ Components)
├── Shared/Gardens/                   Domain, store, lokasi, Components
├── Resources/Assets.xcassets/
└── PreviewSupport/                   Fixtures, ReferenceScreens
PalmOilFarmerTests/
Docs/
```

## Aturan penempatan

- `…Screen.swift` berisi tipe dengan nama sama: konten utama tujuan navigasi, modal, tab, atau langkah flow. `…Flow.swift` yang sudah ada memilih dan menghubungkan langkah; sufiks ini opsional, bukan kewajiban per area. Tidak ada wrapper Screen yang meneruskan ke View lama.
- `Components` lokal berada di bawah area pemilik. Komponen lintas area ada di `Shared/Gardens/Components`; komponen generik tanpa model/layanan fitur ada di `Core/DesignSystem/Components`.
- Screen, model dan layanan berada berdekatan di fitur pemilik; subfolder dibuat jika membantu pencarian. FertilizerRecommendations mempertahankan Models untuk kelompok kontrak laporan. Tidak ada kewajiban ViewModel, repository, atau coordinator baru. State UI tetap dalam view asal.
- Folder memakai filesystem synchronized groups. Perpindahan tidak menambah entri source manual atau target baru dalam proyek Xcode. Info.plist tetap dihasilkan build settings. Resources hanya aset statis; kode preview tetap di PreviewSupport.
- Nama aset, bundle identifier, target/module, deployment target iOS 27, raw value enum, JSON keys, ID data dan lokasi `gardens.json` / `mapping-drafts.json` dipertahankan.

## Kepemilikan data dan alur

[AppFlow](../PalmOilFarmer/App/AppFlow.swift) memiliki [GardenStore](../PalmOilFarmer/Shared/Gardens/GardenStore.swift) dan [MappingDraftStore](../PalmOilFarmer/Features/GardenMapping/MappingDraftStore.swift), serta state push profil, sheet pendaftaran dan full screen pemetaan. Daftar menerima nilai dan callback, bukan membuat store. Penyimpanan kebun tetap melalui [GardenPersistence](../PalmOilFarmer/Shared/Gardens/GardenPersistence.swift); kegagalan save tidak menerbitkan nilai sukses.

[GardenDetailsScreen](../PalmOilFarmer/Features/GardenDetails/GardenDetailsScreen.swift) memiliki draf edit lokal; hanya callback `onSave` yang berhasil menutup editor. Profil menerima nilai kebun terbaru dari induk. Editor riwayat mengirim nilai baru lewat `onSave` → profil `onUpdate` → store. Review memakai [ReviewService](../PalmOilFarmer/Features/GardenReview/ReviewService.swift) dari environment; hasil submit disimpan oleh callback profil, dan status unduhan ditangani [ReviewReportDownload](../PalmOilFarmer/Features/GardenReview/ReviewReportDownload.swift). Ekstraksi komponen tidak memindahkan `.task`, lokasi GPS, network, binding, atau lifecycle store.

## Keputusan batas yang disengaja

| Keputusan | Alasan spesifik |
| --- | --- |
| GardenDetailsScreen berada di GardenDetails | Form yang sama dipakai pendaftaran dan edit profil; kedua mode dan pemanggil dicatat di ScreenMap, tanpa menduplikasi editor. |
| GardenBoundaryScreen tetap satu screen | State editor dan konfirmasi lokasi foto berkaitan erat; `editor` masih computed property pada screen supaya task GPS dan sheet detail tetap menempel di lokasi semula. |
| Panduan awal RegistrationFlow tetap inline | Hanya komposisi singkat teks, ilustrasi dan tombol; state langkah tetap milik flow. Langkah pencarian adalah screen tersendiri. |
| GardenProfileContent menyusun isi; ReviewSubmissionView menyusun sheet | GardenProfileScreen tetap memiliki seluruh state presentasi, submit/refresh, response retry, onDismiss dan callback store. Dua komponen baru tidak menambah store, task atau Flow. |
| GardenProfileLayout dan GardenProfileStep tetap dekat UI | Keduanya konfigurasi presentasi, bukan model persistence. GardenMetricTile tetap bersama GardenSummaryView karena hanya membentuk ringkasan tersebut. |
| History cards tetap satu file GardenHistoryViews | Kartu pupuk dan panen kecil dan berhubungan; HistoryValueRow dipakai GardenHistory dan FertilizerRecommendations sehingga berada di Shared/Gardens/Components; GardenSectionHeader tetap lokal di GardenProfile. |
| GardenPickerField tetap di design system | API hanya label, nilai dan content generik walaupun nama historisnya menyebut Garden. Preview EmptyStateView kini memakai ikon generik dan SelectionListScreen memakai opsi string tanpa SoilType; SeedlingIcon tetap milik GardenList. |
| FindingBlockView tetap berakhiran View | Bagian yang ditanam dalam tab alokasi rekomendasi, bukan halaman penuh; picker dan peta anak bernama Screen. |
| Model kebun bersama berada di Shared/Gardens; laporan milik FertilizerRecommendations | FindingBlock/FindingWaypoint memakai kontrak kebun yang sama. Laporan tetap dekat fitur rekomendasi; GardenLocalReport berada di FertilizerRecommendations/Models. |
| FertilizerAllocationSection milik FertilizerRecommendations/Components | UI domain laporan dipakai rekomendasi dan FindingBlock; bukan UI generik. |
| RecommendationAreaMapScreen memakai WaypointLocationSession | Dependensi lintas fitur sudah ada; dipertahankan untuk menghindari perubahan lifecycle GPS. FindingWaypoint flow tetap eksperimen. |
| ReviewService memakai SwiftUI EnvironmentKey | Ini adaptor injeksi layanan yang sudah ada, tetap bersama GardenReview; bukan alasan membuat lapisan baru. |
| ReviewTimelineEntry.referenceEntries tetap dalam model | Dipakai simulasi review yang dapat dipersist, bukan hanya preview. Memindahkannya ke DEBUG akan mengubah kontrak Release. |
| BlockAllocation / BlockThumbnail tetap tersedia | Utilitas lama tidak aktif dari root; tidak dihapus dalam refactor struktur. |

Semua tipe yang dipisah mempertahankan implementasinya. Hanya `BlockAreaPickerScreen` dan `BlockAreaThumbnail` berubah dari private top-level menjadi internal agar bisa dipakai antarfile; tidak ada API public baru. WaypointGardenCard tetap private di file screen daftar eksperimen.

## Preview dan reference

Fixtures Gardens, Recommendation dan Waypoint berada di PreviewSupport/Fixtures dan dijaga `#if DEBUG`. Komposisi reference berada di PreviewSupport/ReferenceScreens. Preview lokal sederhana boleh berada di file pemilik UI. Preview yang menunjukkan hasil unduhan atau varian profil tidak berarti alur tersebut aktif dari root. Lihat status tiap tujuan di ScreenMap.

Dokumen implementasi [CodedUI2](CodedUI2Implementation.md), [FindingBlock](FindingBlock.md), dan [FindingWaypoint](FindingWaypoint.md) memuat konteks sebelumnya; hasil verifikasi terbaru dicatat di [FeatureFoldersVerification](FeatureFoldersVerification.md).

## Kepemilikan di antara fitur

[GardenProfileContent](../PalmOilFarmer/Features/GardenProfile/GardenProfileContent.swift) menerima nilai kebun/layout/status dan tiga callback: edit pupuk, edit panen, aksi review. ScrollView dan tracking scroll tetap di GardenProfileScreen. [ReviewSubmissionView](../PalmOilFarmer/Features/GardenReview/ReviewSubmissionView.swift) menerima binding showsReviewForm serta onSubmit; NavigationStack sheet dipindahkan utuh. Respons server tetap disimpan di receivedReview pada profil jika persistence gagal, agar retry tidak mengirim permintaan kedua. Perpindahan ke status tetap terjadi sesudah sheet ditutup.

| Shared | Pemakai runtime |
| --- | --- |
| Garden, GardenBoundary, GardenLocation, GardenDisplayMetrics | GardenList, GardenDetails, GardenMapping, GardenProfile dan fitur yang memakai kontrak kebun |
| GardenStore / GardenPersistence | AppFlow; FindingWaypointFlow ketika eksperimen dijalankan |
| CurrentLocationProvider | GardenRegistration/LocationSearchScreen, GardenMapping/GardenBoundaryScreen |
| GardenMapView | GardenList, GardenProfile, GardenDetails dan FertilizerRecommendations |
| LocationMapPreview | Kartu draf GardenList dan reference MapDownloads |
| GardenAreaIcon | GardenList/GardenCard, GardenProfile/GardenSummaryView dan GardenProfileProgressView |
| HistoryValueRow | Kartu riwayat GardenHistory dan FertilizerRecommendations/FertilizerCostTable |

SeedlingIcon milik GardenList, BoundaryGuideIllustration milik GardenRegistration, MapHeroView milik MapDownloads. FertilizerAllocationSection milik FertilizerRecommendations meskipun juga dipakai FindingBlock. Garden sebagai aggregate persistence merujuk model review/laporan di area pemiliknya; folder bukan batas module dan tidak menjamin dependensi satu arah.

[OwnershipVerification](OwnershipVerification.md) menyimpan hasil ekstraksi profil sebelumnya; [Verification](Verification.md) menyimpan hasil refactor 27 Oktober. Kedua laporan tersebut bersifat historis. [FeatureFoldersVerification](FeatureFoldersVerification.md) mencatat pemeriksaan perpindahan folder terbaru.

Penyimpangan kecil dari rencana: GardenSectionHeader berada di GardenProfile/Components karena hanya dua section profil yang memakainya saat runtime. Preview di GardenHistory tidak menjadikannya komponen bersama.


## Batas Features, Shared dan Core

Features berisi area pekerjaan yang dapat ditemukan langsung dari namanya. Tidak ada folder Features/Gardens yang membungkus seluruh area. GardenDetails tetap menyimpan form yang digunakan pendaftaran dan edit profil. MapDownloads tetap reference, FindingWaypoint tetap eksperimen, FindingBlock tetap bagian alokasi yang ditanam pada rekomendasi.

Shared/Gardens hanya menampung nilai kebun/geometri/lokasi/display metrics, penyimpanan kebun, penyedia lokasi yang dipakai beberapa fitur, serta komponen domain bersama. MappingDraft dan MappingDraftStore tetap milik GardenMapping; GardenReview dan ReviewService tetap milik GardenReview; kontrak laporan tetap milik FertilizerRecommendations meskipun dipakai fitur lain. Penggunaan lintas fitur tidak otomatis memindahkan file ke Shared.

Struktur folder bukan batas module. Garden yang disimpan tetap merujuk model review dan laporan dari fitur pemiliknya. Store masih dibuat AppFlow; perpindahan file ke Shared tidak mengubah pemilik state atau membuat singleton. Nama file mengikuti tipe utama; tidak menambah Flow atau mengganti nama simbol pada iterasi pemindahan ini.
