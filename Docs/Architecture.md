# Arsitektur SwiftUI

Struktur ini memisahkan halaman, komponen, data, dan UI generik. Mulai dari [peta halaman](ScreenMap.md); [rencana awal](RefactorPlan.md) menyimpan inventaris baseline, bukan peta source terkini.

```text
PalmOilFarmer/
├── App/                         PalmOilFarmerApp → AppFlow
├── Core/DesignSystem/           Tokens, Components, Styles, Catalog
├── Features/
│   ├── Gardens/
│   │   ├── List/               Daftar dan kartu kebun
│   │   ├── Profile/            Profil dan komponen isi
│   │   ├── Details/            Form kebun baru/edit
│   │   ├── Registration/       Pilihan lokasi, pencarian, foto
│   │   ├── Mapping/            Batas kebun dan penyimpanan draf
│   │   ├── History/            Editor pupuk/panen dan draf
│   │   ├── Review/             Pengajuan, status, layanan, nilai review
│   │   ├── Recommendations/    Laporan, Models, Components
│   │   ├── MapDownloads/       Reference unduhan peta
│   │   └── Shared/             Domain, store, lokasi, Components
│   ├── FindingBlock/            Models, Data, Views (+ Components)
│   └── FindingWaypoint/         Models, Data, Views (+ Components)
├── Resources/Assets.xcassets/
└── PreviewSupport/              Fixtures, ReferenceScreens
PalmOilFarmerTests/
Docs/
```

## Aturan penempatan

- `…Screen.swift` berisi tipe dengan nama sama: konten utama tujuan navigasi, modal, tab, atau langkah flow. `…Flow.swift` yang sudah ada memilih dan menghubungkan langkah; sufiks ini opsional, bukan kewajiban per area. Tidak ada wrapper Screen yang meneruskan ke View lama.
- `Components` lokal berada di bawah area pemilik. Komponen lintas area ada di `Gardens/Shared/Components`; komponen generik tanpa model/layanan fitur ada di `Core/DesignSystem/Components`.
- Screen, model dan layanan Gardens berada berdekatan di area pemilik; subfolder dibuat jika membantu pencarian. Recommendations mempertahankan Models untuk kelompok kontrak laporan. Tidak ada kewajiban ViewModel, repository, atau coordinator baru. State UI tetap dalam view asal.
- Folder memakai filesystem synchronized groups. Perpindahan tidak menambah entri source manual atau target baru dalam proyek Xcode. Info.plist tetap dihasilkan build settings. Resources hanya aset statis; kode preview tetap di PreviewSupport.
- Nama aset, bundle identifier, target/module, deployment target iOS 27, raw value enum, JSON keys, ID data dan lokasi `gardens.json` / `mapping-drafts.json` dipertahankan.

## Kepemilikan data dan alur

[AppFlow](../PalmOilFarmer/App/AppFlow.swift) memiliki [GardenStore](../PalmOilFarmer/Features/Gardens/Shared/GardenStore.swift) dan [MappingDraftStore](../PalmOilFarmer/Features/Gardens/Mapping/MappingDraftStore.swift), serta state push profil, sheet pendaftaran dan full screen pemetaan. Daftar menerima nilai dan callback, bukan membuat store. Penyimpanan kebun tetap melalui [GardenPersistence](../PalmOilFarmer/Features/Gardens/Shared/GardenPersistence.swift); kegagalan save tidak menerbitkan nilai sukses.

[GardenDetailsScreen](../PalmOilFarmer/Features/Gardens/Details/GardenDetailsScreen.swift) memiliki draf edit lokal; hanya callback `onSave` yang berhasil menutup editor. Profil menerima nilai kebun terbaru dari induk. Editor riwayat mengirim nilai baru lewat `onSave` → profil `onUpdate` → store. Review memakai [ReviewService](../PalmOilFarmer/Features/Gardens/Review/ReviewService.swift) dari environment; hasil submit disimpan oleh callback profil, dan status unduhan ditangani [ReviewReportDownload](../PalmOilFarmer/Features/Gardens/Review/ReviewReportDownload.swift). Ekstraksi komponen tidak memindahkan `.task`, lokasi GPS, network, binding, atau lifecycle store.

## Keputusan batas yang disengaja

| Keputusan | Alasan spesifik |
| --- | --- |
| GardenDetailsScreen berada di Details | Form yang sama dipakai pendaftaran dan edit profil; kedua mode dan pemanggil dicatat di ScreenMap, tanpa menduplikasi editor. |
| GardenBoundaryScreen tetap satu screen | State editor dan konfirmasi lokasi foto berkaitan erat; `editor` masih computed property pada screen supaya task GPS dan sheet detail tetap menempel di lokasi semula. |
| Panduan awal RegistrationFlow tetap inline | Hanya komposisi singkat teks, ilustrasi dan tombol; state langkah tetap milik flow. Langkah pencarian adalah screen tersendiri. |
| GardenProfileContent menyusun isi; ReviewSubmissionView menyusun sheet | GardenProfileScreen tetap memiliki seluruh state presentasi, submit/refresh, response retry, onDismiss dan callback store. Dua komponen baru tidak menambah store, task atau Flow. |
| GardenProfileLayout dan GardenProfileStep tetap dekat UI | Keduanya konfigurasi presentasi, bukan model persistence. GardenMetricTile tetap bersama GardenSummaryView karena hanya membentuk ringkasan tersebut. |
| History cards tetap satu file GardenHistoryViews | Kartu pupuk dan panen kecil dan berhubungan; HistoryValueRow dan GardenSectionHeader yang dipakai lintas area dipisahkan ke komponen bersama. |
| GardenPickerField tetap di design system | API hanya label, nilai dan content generik walaupun nama historisnya menyebut Garden. Preview EmptyStateView kini memakai ikon generik dan SelectionListScreen memakai opsi string tanpa SoilType; SeedlingIcon tetap milik Gardens. |
| FindingBlockView tetap berakhiran View | Bagian yang ditanam dalam tab alokasi rekomendasi, bukan halaman penuh; picker dan peta anak bernama Screen. |
| Model Garden dan laporan tetap milik Gardens | FindingBlock/FindingWaypoint memakai kontrak kebun yang sama. Penggunaan lintas fitur tidak memerlukan pemindahan seluruh domain ke Core. GardenLocalReport berada di Recommendations/Models karena hanya membentuk laporan dari Garden. |
| FertilizerAllocationSection milik Recommendations/Components | UI domain laporan dipakai rekomendasi dan FindingBlock; bukan UI generik. |
| RecommendationAreaMapScreen memakai WaypointLocationSession | Dependensi lintas fitur sudah ada; dipertahankan untuk menghindari perubahan lifecycle GPS. FindingWaypoint flow tetap eksperimen. |
| ReviewService memakai SwiftUI EnvironmentKey | Ini adaptor injeksi layanan yang sudah ada, tetap bersama Review; bukan alasan membuat lapisan baru. |
| ReviewTimelineEntry.referenceEntries tetap dalam model | Dipakai simulasi review yang dapat dipersist, bukan hanya preview. Memindahkannya ke DEBUG akan mengubah kontrak Release. |
| BlockAllocation / BlockThumbnail tetap tersedia | Utilitas lama tidak aktif dari root; tidak dihapus dalam refactor struktur. |

Semua tipe yang dipisah mempertahankan implementasinya. Hanya `BlockAreaPickerScreen` dan `BlockAreaThumbnail` berubah dari private top-level menjadi internal agar bisa dipakai antarfile; tidak ada API public baru. WaypointGardenCard tetap private di file screen daftar eksperimen.

## Preview dan reference

Fixtures Gardens, Recommendation dan Waypoint berada di PreviewSupport/Fixtures dan dijaga `#if DEBUG`. Komposisi reference berada di PreviewSupport/ReferenceScreens. Preview lokal sederhana boleh berada di file pemilik UI. Preview yang menunjukkan hasil unduhan atau varian profil tidak berarti alur tersebut aktif dari root. Lihat status tiap tujuan di ScreenMap.

Dokumen implementasi [CodedUI2](CodedUI2Implementation.md), [FindingBlock](FindingBlock.md), dan [FindingWaypoint](FindingWaypoint.md) memuat konteks sebelumnya; hasil verifikasi refactor saat ini dicatat di [Verification](Verification.md).

## Ownership Gardens setelah pengelompokan area

[GardenProfileContent](../PalmOilFarmer/Features/Gardens/Profile/GardenProfileContent.swift) menerima nilai kebun/layout/status dan tiga callback: edit pupuk, edit panen, aksi review. ScrollView dan tracking scroll tetap di GardenProfileScreen. [ReviewSubmissionView](../PalmOilFarmer/Features/Gardens/Review/ReviewSubmissionView.swift) menerima binding showsReviewForm serta onSubmit; NavigationStack sheet dipindahkan utuh. Respons server tetap disimpan di receivedReview pada profil jika persistence gagal, agar retry tidak mengirim permintaan kedua. Perpindahan ke status tetap terjadi sesudah sheet ditutup.

| Shared | Pemakai runtime |
| --- | --- |
| Garden, GardenBoundary, GardenLocation, GardenDisplayMetrics | List, Details, Mapping, Profile dan fitur yang memakai kontrak kebun |
| GardenStore / GardenPersistence | AppFlow; FindingWaypointFlow ketika eksperimen dijalankan |
| CurrentLocationProvider | Registration/LocationSearchScreen, Mapping/GardenBoundaryScreen |
| GardenMapView | List, Profile, Details dan Recommendations |
| LocationMapPreview | Kartu draf List dan reference MapDownloads |
| GardenAreaIcon | List/GardenCard, Profile/GardenSummaryView dan GardenProfileProgressView |
| HistoryValueRow | Kartu riwayat History dan Recommendations/FertilizerCostTable |

SeedlingIcon milik List, BoundaryGuideIllustration milik Registration, MapHeroView milik MapDownloads. FertilizerAllocationSection milik Recommendations meskipun juga dipakai FindingBlock. Garden sebagai aggregate persistence merujuk model review/laporan di area pemiliknya; folder bukan batas module dan tidak menjamin dependensi satu arah.

Verifikasi iterasi ownership: [OwnershipVerification](OwnershipVerification.md). Verifikasi 27 Oktober tetap merupakan catatan historis refactor pertama.

Penyimpangan kecil dari rencana: GardenSectionHeader berada di Profile/Components karena hanya dua section profil yang memakainya saat runtime. Preview di History tidak menjadikannya komponen bersama.
