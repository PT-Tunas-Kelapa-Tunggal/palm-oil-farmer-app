# Arsitektur SwiftUI

Struktur ini memisahkan halaman, komponen, data, dan UI generik. Mulai dari [peta halaman](ScreenMap.md); [rencana awal](RefactorPlan.md) menyimpan inventaris baseline, bukan peta source terkini.

```text
PalmOilFarmer/
├── App/                         PalmOilFarmerApp → AppFlow
├── Core/DesignSystem/           Tokens, Components, Styles, Catalog
├── Features/
│   ├── Gardens/
│   │   ├── Models/              Nilai kebun, draf, laporan, review
│   │   ├── Data/                Store, persistence, lokasi, foto, layanan
│   │   └── Views/
│   │       ├── List/            GardenListScreen + Components
│   │       ├── Profile/         GardenProfileScreen + Components
│   │       ├── Registration/    RegistrationFlow, screen, Components
│   │       ├── Mapping/         Screen + Components
│   │       ├── History/         Screen + Components
│   │       ├── Review/          Screen + Components
│   │       ├── Recommendations/ Screen + Components
│   │       └── Components/     UI bersama lintas area Gardens
│   ├── FindingBlock/            Models, Data, Views (+ Components)
│   └── FindingWaypoint/         Models, Data, Views (+ Components)
├── Resources/Assets.xcassets/
└── PreviewSupport/              Fixtures, ReferenceScreens
PalmOilFarmerTests/
Docs/
```

## Aturan penempatan

- `…Screen.swift` berisi tipe dengan nama sama: konten utama tujuan navigasi, modal, tab, atau langkah flow. `…Flow.swift` memilih dan menghubungkan langkah. Tidak ada wrapper Screen yang meneruskan ke View lama.
- `Components` lokal berada di bawah area pemilik. Komponen lintas area ada di `Gardens/Views/Components`; komponen generik tanpa model/layanan fitur ada di `Core/DesignSystem/Components`.
- Model menyimpan nilai dan kalkulasi; Data menyimpan persistence atau akses framework/layanan. Tidak ada kewajiban ViewModel, repository, atau coordinator baru. State UI tetap dalam view asal.
- Folder memakai filesystem synchronized groups. Perpindahan tidak menambah entri source manual atau target baru dalam proyek Xcode. Info.plist tetap dihasilkan build settings. Resources hanya aset statis; kode preview tetap di PreviewSupport.
- Nama aset, bundle identifier, target/module, deployment target iOS 27, raw value enum, JSON keys, ID data dan lokasi `gardens.json` / `mapping-drafts.json` dipertahankan.

## Kepemilikan data dan alur

[AppFlow](../PalmOilFarmer/App/AppFlow.swift) memiliki [GardenStore](../PalmOilFarmer/Features/Gardens/Data/GardenStore.swift) dan [MappingDraftStore](../PalmOilFarmer/Features/Gardens/Data/MappingDraftStore.swift), serta state push profil, sheet pendaftaran dan full screen pemetaan. Daftar menerima nilai dan callback, bukan membuat store. Penyimpanan kebun tetap melalui [GardenPersistence](../PalmOilFarmer/Features/Gardens/Data/GardenPersistence.swift); kegagalan save tidak menerbitkan nilai sukses.

[GardenDetailsScreen](../PalmOilFarmer/Features/Gardens/Views/Registration/GardenDetailsScreen.swift) memiliki draf edit lokal; hanya callback `onSave` yang berhasil menutup editor. Profil menerima nilai kebun terbaru dari induk. Editor riwayat mengirim nilai baru lewat `onSave` → profil `onUpdate` → store. Review memakai [ReviewService](../PalmOilFarmer/Features/Gardens/Data/ReviewService.swift) dari environment; hasil submit disimpan oleh callback profil, dan status unduhan ditangani [ReviewReportDownload](../PalmOilFarmer/Features/Gardens/Data/ReviewReportDownload.swift). Ekstraksi komponen tidak memindahkan `.task`, lokasi GPS, network, binding, atau lifecycle store.

## Keputusan batas yang disengaja

| Keputusan | Alasan spesifik |
| --- | --- |
| GardenDetailsScreen tetap di Registration | Form yang sama dipakai pendaftaran dan edit profil; kedua mode dan pemanggil dicatat di ScreenMap, tanpa menduplikasi editor. |
| GardenBoundaryScreen tetap satu screen | State editor dan konfirmasi lokasi foto berkaitan erat; `editor` masih computed property pada screen supaya task GPS dan sheet detail tetap menempel di lokasi semula. |
| Panduan awal RegistrationFlow tetap inline | Hanya komposisi singkat teks, ilustrasi dan tombol; state langkah tetap milik flow. Langkah pencarian adalah screen tersendiri. |
| Profil masih memiliki `profileContent`, `map`, `profileProgress` inline | Bagian ini menyusun varian standard/overview/chart dan callback yang dikuasai profil; section riwayat pupuk dan panen yang mandiri sudah diekstrak. |
| GardenProfileLayout dan GardenProfileStep tetap dekat UI | Keduanya konfigurasi presentasi, bukan model persistence. GardenMetricTile tetap bersama GardenSummaryView karena hanya membentuk ringkasan tersebut. |
| History cards tetap satu file GardenHistoryViews | Kartu pupuk dan panen kecil dan berhubungan; HistoryValueRow dan GardenSectionHeader yang dipakai lintas area dipisahkan ke komponen bersama. |
| GardenPickerField tetap di design system | API hanya label, nilai dan content generik walaupun nama historisnya menyebut Garden. Preview EmptyStateView kini memakai ikon generik dan SelectionListScreen memakai opsi string tanpa SoilType; SeedlingIcon tetap milik Gardens. |
| FindingBlockView tetap berakhiran View | Bagian yang ditanam dalam tab alokasi rekomendasi, bukan halaman penuh; picker dan peta anak bernama Screen. |
| Model Garden dan laporan tetap milik Gardens | FindingBlock/FindingWaypoint memakai kontrak kebun yang sama. Penggunaan lintas fitur tidak memerlukan pemindahan seluruh domain ke Core. GardenLocalReport dikembalikan ke Models Gardens karena hanya membentuk laporan dari Garden. |
| FertilizerAllocationSection milik Gardens/Views/Components | UI domain laporan dipakai rekomendasi dan FindingBlock; bukan UI generik. |
| RecommendationAreaMapScreen memakai WaypointLocationSession | Dependensi lintas fitur sudah ada; dipertahankan untuk menghindari perubahan lifecycle GPS. FindingWaypoint flow tetap eksperimen. |
| ReviewService memakai SwiftUI EnvironmentKey | Ini adaptor injeksi layanan yang sudah ada, tetap bersama Data; bukan alasan membuat lapisan baru. |
| ReviewTimelineEntry.referenceEntries tetap dalam model | Dipakai simulasi review yang dapat dipersist, bukan hanya preview. Memindahkannya ke DEBUG akan mengubah kontrak Release. |
| BlockAllocation / BlockThumbnail tetap tersedia | Utilitas lama tidak aktif dari root; tidak dihapus dalam refactor struktur. |

Semua tipe yang dipisah mempertahankan implementasinya. Hanya `BlockAreaPickerScreen` dan `BlockAreaThumbnail` berubah dari private top-level menjadi internal agar bisa dipakai antarfile; tidak ada API public baru. WaypointGardenCard tetap private di file screen daftar eksperimen.

## Preview dan reference

Fixtures Gardens, Recommendation dan Waypoint berada di PreviewSupport/Fixtures dan dijaga `#if DEBUG`. Komposisi reference berada di PreviewSupport/ReferenceScreens. Preview lokal sederhana boleh berada di file pemilik UI. Preview yang menunjukkan hasil unduhan atau varian profil tidak berarti alur tersebut aktif dari root. Lihat status tiap tujuan di ScreenMap.

Dokumen implementasi [CodedUI2](CodedUI2Implementation.md), [FindingBlock](FindingBlock.md), dan [FindingWaypoint](FindingWaypoint.md) memuat konteks sebelumnya; hasil verifikasi refactor saat ini dicatat di [Verification](Verification.md).
