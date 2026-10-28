# Rencana struktur SwiftUI yang sederhana dan konsisten

**Revisi 28 Oktober 2026 — hanya rencana, belum implementasi.** Dokumen ini menggantikan versi sebelumnya dari RefactorOwnershipPlan. Source diperiksa pada branch `codex/refactor-swiftui-structure`, commit `5245dd4`. Sebelum revisi, satu-satunya file untracked adalah dokumen rencana ini; source tracked bersih.

Tujuan: seseorang yang ingin mengubah satu bagian aplikasi dapat menemukan halaman, komponen dan pemilik datanya dari nama file serta lokasi yang berdekatan. Tidak ada target jumlah folder atau jumlah baris per file.

[Architecture](Architecture.md) dan [ScreenMap](ScreenMap.md) masih menggambarkan implementasi sekarang. Struktur di bawah adalah target berikutnya, bukan klaim pekerjaan sudah selesai. Panduan pertama tetap menjadi acuan kompatibilitas data/Git/pengujian, tetapi pilihan struktur dan pemisahan pada rencana terbaru ini menggantikan usulan lamanya ketika implementasi diminta.

## 1. Keputusan penamaan

| Hal | Keputusan untuk Krops |
| --- | --- |
| File Swift | Sama dengan tipe utama: GardenCard → GardenCard.swift. Helper/enum kecil yang erat hubungannya boleh satu file. |
| Tipe dan simbol | UpperCamelCase untuk tipe; lowerCamelCase untuk properti/fungsi; nama konkret sesuai tanggung jawab. |
| Halaman | Pertahankan akhiran Screen yang sudah konsisten. Tidak rename seluruh proyek kembali menjadi View. |
| Komponen | Nama peran seperti GardenCard, ReviewTimelineRow, GardenSummaryView; tidak memaksa satu akhiran untuk semua UI. |
| Flow | Opsional. AppFlow, RegistrationFlow dan FindingWaypointFlow yang sudah ada tetap dipertahankan. Tidak membuat Flow per area. |
| Penambahan nama | Hindari Manager, Helper, Utils, Base atau Common tanpa tanggung jawab spesifik. Jangan mengganti Flow dengan Coordinator hanya demi istilah berbeda. |
| Folder | Nama domain/area dalam bahasa Inggris; tetap Gardens untuk koleksi/domain kebun, Garden untuk tipe satu kebun. Nama file tetap cukup spesifik saat ditemukan melalui pencarian global. |
| Komentar | Tambahkan dokumentasi untuk kontrak/state/lifetime yang tidak jelas dari nama. Tidak mewajibkan komentar pembuka panjang atau komentar yang mengulang kode. |

Dasar penamaan: [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) mengutamakan kejelasan dan konsistensi nama. Konvensi file mengikuti tipe utama, dengan helper terkait boleh tetap bersama, juga dipakai [Google Swift Style Guide](https://google.github.io/swift/#file-names). Sufiks Screen/Flow dan susunan folder di sini merupakan keputusan proyek, bukan aturan wajib Apple.

## 2. Struktur target: area dahulu, subfolder seperlunya

Hapus lapisan `Gardens/Views` yang membuat semua halaman terpisah dari data dan layanan area masing-masing. Screen, model kecil dan layanan area berada berdekatan. `Components` menampung UI lokal; `Models` hanya dipertahankan pada Recommendations karena ada satu kelompok kontrak laporan yang cukup besar dan saling berhubungan.

```text
PalmOilFarmer/
├── App/                              # Entry point dan pemilik store
├── Core/DesignSystem/                 # UI generik; tetap
├── Features/
│   ├── Gardens/
│   │   ├── List/
│   │   │   ├── GardenListScreen.swift
│   │   │   └── Components/
│   │   ├── Profile/
│   │   │   ├── GardenProfileScreen.swift
│   │   │   ├── GardenProfileContent.swift     # Baru: susunan isi profil
│   │   │   └── Components/
│   │   ├── Details/
│   │   │   ├── GardenDetailsScreen.swift      # Form baru dan edit yang sama
│   │   │   └── PlantingDatePickerScreen.swift
│   │   ├── Registration/
│   │   │   ├── RegistrationFlow.swift        # Panduan → pilihan lokasi
│   │   │   ├── LocationSearchScreen.swift
│   │   │   ├── LocationSearchService.swift
│   │   │   ├── PhotoLocationReader.swift
│   │   │   └── Components/
│   │   ├── Mapping/
│   │   │   ├── GardenBoundaryScreen.swift
│   │   │   ├── PhotoLocationConfirmationScreen.swift
│   │   │   ├── MappingDraft.swift
│   │   │   ├── MappingDraftStore.swift
│   │   │   └── Components/
│   │   ├── History/
│   │   │   ├── FertilizerHistoryScreen.swift
│   │   │   ├── HarvestHistoryScreen.swift
│   │   │   ├── FertilizerDraft.swift
│   │   │   └── Components/
│   │   ├── Review/
│   │   │   ├── ReviewSubmissionView.swift    # Baru: susunan sheet pengajuan
│   │   │   ├── ReviewRequestScreen.swift
│   │   │   ├── ReviewContactFormScreen.swift
│   │   │   ├── ReviewStatusScreen.swift
│   │   │   ├── ReviewService.swift
│   │   │   ├── ReviewReportDownload.swift
│   │   │   ├── GardenReview.swift            # + nilai status/kontak/timeline
│   │   │   └── Components/
│   │   ├── Recommendations/
│   │   │   ├── FertilizerRecommendationScreen.swift
│   │   │   ├── NutrientReferenceScreen.swift
│   │   │   ├── RecommendationAreaPickerScreen.swift
│   │   │   ├── RecommendationAreaMapScreen.swift
│   │   │   ├── Components/
│   │   │   └── Models/                       # Kontrak laporan dan nilai pendukung
│   │   ├── MapDownloads/                     # Reference/preview, tetap tidak aktif
│   │   │   ├── MapDownloadScreen.swift
│   │   │   ├── MapDownloadItem.swift
│   │   │   ├── MapDownloadState.swift
│   │   │   └── Components/
│   │   └── Shared/
│   │       ├── Garden.swift                  # + boundary/location/display metrics
│   │       ├── GardenStore.swift
│   │       ├── GardenPersistence.swift
│   │       ├── CurrentLocationProvider.swift
│   │       └── Components/
│   ├── FindingBlock/                        # Struktur sekarang tetap
│   └── FindingWaypoint/                     # Struktur sekarang tetap; eksperimen
├── Resources/                              # Tetap
└── PreviewSupport/                         # Tetap; perbarui pemanggil jika perlu
```

Gardens adalah kelompok domain. Unit pencarian sehari-hari adalah List, Profile, Mapping, Review, dan seterusnya. FindingBlock/FindingWaypoint tidak dipindah untuk mengejar keseragaman; keduanya sudah memiliki tanggung jawab yang bisa ditemukan.

Tidak membuat subfolder kosong atau satu folder Models/Data untuk satu file. Tidak menggabungkan kembali semua model kecil hanya untuk mengurangi jumlah file: penempatan diperbaiki dahulu, pemecahan tipe yang sudah masuk akal dipertahankan.

## 3. Batas kode bersama

- `Shared` menyimpan Garden, geometri/lokasi, display metrics, store/persistence kebun dan layanan lokasi yang dipakai pencarian serta pemetaan. Instansiasi GardenStore tetap di AppFlow; memindahkan file tidak memindahkan pemilik state.
- Komponen bersama: GardenMapView, LocationMapPreview, GardenAreaIcon, GardenSectionHeader dan HistoryValueRow. Catat pemakai runtime masing-masing pada Architecture setelah implementasi.
- SeedlingIcon masuk List; BoundaryGuideIllustration masuk Registration; MapHeroView, MapDownloadCard dan MapDownloadProgressView masuk MapDownloads. Pemakaian oleh preview tidak otomatis menjadikan komponen Shared.
- Model MappingDraft tetap milik Mapping walaupun ditampilkan List. Card unduhan tetap milik MapDownloads walaupun dipasang List. FertilizerAllocationSection tetap milik Recommendations walaupun dipakai FindingBlock. Pemakaian lintas area tidak mengharuskan duplikasi atau pemindahan ke Shared.
- Garden adalah aggregate persistence yang merujuk GardenReview dan laporan rekomendasi. Ketergantungan nilai lintas folder ini dipertahankan, tanpa migrasi JSON. Struktur folder tidak memberikan isolasi module atau jaminan dependensi satu arah.
- Core/DesignSystem tetap tanpa dependensi model/layanan fitur, termasuk pada preview. Komponen generik menerima nilai, binding, content atau callback.

## 4. Rapikan profil dengan perubahan terkecil yang berguna

Rencana sebelumnya mewajibkan GardenProfileFlow dan ReviewRequestFlow. Revisi ini **tidak membuat keduanya**. GardenProfileScreen tetap menjadi tujuan navigasi dan pemilik state presentasi. Kita memisahkan dua bagian yang memang punya tanggung jawab mandiri, tanpa memindahkan umur state ke container baru.

| File target | Tanggung jawab | Data/state |
| --- | --- | --- |
| Profile/GardenProfileScreen.swift | Menghubungkan isi profil dengan toolbar, editor, review dan tujuan status/hasil. | Garden terbaru dari parent; state presentasi, scroll, receivedReview, error; ReviewService environment; callback store tetap seperti sekarang. |
| Profile/GardenProfileContent.swift | Menyusun peta, nama, ringkasan, riwayat dan kelengkapan untuk varian standard/overview/chart. | Nilai tampilan dan callback aksi; tanpa store, submit, task network/GPS atau state navigasi. |
| Review/ReviewSubmissionView.swift | Menghubungkan halaman informasi dengan formulir kontak di dalam sheet yang sudah ada. | Binding showsReviewForm dari profil dan onSubmit async; state form tetap pada screen masing-masing. |

Kontrak konkret:

- Ganti computed property `profileContent` dengan GardenProfileContent. Pindahkan helper layout `map`/`profileProgress` yang terkait bersama content. ScrollView, padding luar, scroll tracking, refreshable, toolbar serta modifier presentasi tetap di screen agar perilakunya terjaga.
- Content menerima garden, referenceMapImage, metrics, showsHeader, layout, chartValues dan status yang diperlukan. Callback yang dibutuhkan hanya edit pupuk, edit panen dan aksi review utama. Content tidak menerima seluruh store atau sebuah objek router.
- Susunan NavigationStack pada sheet review dipindah ke ReviewSubmissionView. Root NavigationStack tetap di AppFlow; tidak menambah stack baru di profil.
- Closure submit yang sekarang inline diberi nama `submitReview(_:)` pada GardenProfileScreen. Implementasinya tetap: pakai receivedReview jika tersedia, submit hanya bila perlu, simpan lewat saveReview, baru tutup sheet setelah sukses.
- receivedReview, submittedReviewNeedsNavigation, reset showsReviewForm dan transisi onDismiss tetap di profil. Gagal persistence harus mempertahankan respons untuk retry tanpa submit ulang.
- `.task(id: garden.id)`, refreshReview, onUpdateReview khusus dari parent, dan dismiss setelah hapus sukses tetap berada pada pemilik semula. Tidak ada @State salinan Garden baru.
- API GardenProfileScreen terhadap AppFlow, eksperimen dan preview tetap dipertahankan. Tambahkan preview content untuk pemeriksaan visual; preview interaksi tetap memakai screen dan parent stateful.
- Urutkan isi screen secara logis, misalnya input/state → body/presentasi → aksi review, memakai MARK bila membantu. Jangan memecah extension menjadi file tambahan hanya untuk menyembunyikan panjang file.

Tradeoff: screen tetap mengatur beberapa sheet dan operasi review. Itu keputusan yang disengaja untuk menjaga lifetime. Targetnya alur mudah dibaca dan komposisi mudah ditemukan; bukan screen tanpa state atau aturan batas baris. Jika setelah ekstraksi tanggung jawab presentasi masih sulit dijelaskan, evaluasi pemisahan lanjutan dengan bukti dan kontrak sendiri, bukan otomatis menambahkan Flow sekarang.

## 5. Urutan kerja ketika implementasi diminta

1. **Pastikan baseline.** Cek status/HEAD/instruksi repo kembali. Gunakan kode `5245dd4` yang sudah diverifikasi sebagai titik banding bila belum ada perubahan baru. Dokumen ini merupakan pekerjaan perencanaan saat ini; jangan diam-diam memasukkan pekerjaan lain. Untuk iterasi implementasi, satu branch task seperti `codex/refactor-gardens-ownership` cukup.
2. **Perpindahan mekanis seluruh Gardens.** Terapkan 74 pasangan path pada lampiran. Tidak ada rename simbol dalam tahap ini. Perbarui README/Architecture/ScreenMap dan link terkait dalam commit yang sama; periksa tidak ada lokasi lama yang masih bersaing. Build Debug dan bandingkan isi file sebelum/sesudah.
3. **Ekstraksi Profile + Review.** Buat hanya GardenProfileContent dan ReviewSubmissionView sesuai kontrak bagian 4. Pertahankan API screen dan state owners. Catat hasil review diff dan pemeriksaan perilaku dalam commit perubahan ini.
4. **Verifikasi final.** Jalankan Debug/Release, test relevan, pemeriksaan visual dan interaksi di bawah. Tambahkan test hanya untuk risiko yang belum dilindungi, seperti retry tanpa submit kedua; jangan menulis test nama folder.
5. **Dokumentasi final.** Perbarui panduan awal agar aturan penempatan konsisten dengan hasil; Architecture menjelaskan ownership/pengecualian, ScreenMap menjadi indeks nama pengguna → screen → pemilik data/presentasi. Pertahankan pemisahan komposisi dan navigasi serta status aktif/reference/eksperimen. Dokumen historis ditandai jelas.

Commit yang diusulkan: perpindahan + referensi dokumentasinya, ekstraksi komposisi + bukti pemeriksaan, lalu laporan final bila masih perlu. Setiap commit kode harus dapat dibangun sendiri. Tidak amend/reset/stash pekerjaan pengguna. Perintah implementasi berikutnya menentukan otorisasi commit; push/PR/merge tidak diasumsikan dari permintaan membuat rencana ini.

## 6. Verifikasi dan definisi selesai

**Yang dipertahankan:** tampilan, navigation/modal behavior, source-of-truth stores, format/keys/raw values JSON, ID kebun, gardens.json/mapping-drafts.json, kegagalan save, target/module, bundle identifier, deployment target dan signing. Eksperimen tetap tidak aktif. Tidak menambah MVVM wajib, repository, package/module atau mesin GPS baru.

**Build/test:** Debug dan Release final; PalmOilFarmerTests, GardenStressTests, CodedUI2FlowTests dan FindingBlockTests sesuai dampak. Pemeriksaan baseline lama menjadi referensi, bukan klaim pemeriksaan baru telah dijalankan. Cek seluruh pemanggil, fixture DEBUG, aset dan file untracked; gunakan data sementara.

**Interaksi yang harus diuji:** daftar → profil → edit/batal/simpan; editor pupuk/panen; review informasi → kontak → kembali/tutup; gagal submit → retry; submit berhasil tetapi gagal save → retry tanpa pengiriman kedua; tutup sheet lalu buka status; back dari status/hasil; refresh tidak menimpa riwayat terbaru; hapus gagal/sukses pada data sintetis. Gunakan ReviewService stub bila layanan nyata tidak tersedia; jangan mengubah transport produksi agar test lewat.

**Visual:** profil standard/overview/chart, riwayat kosong/terisi, review dan editor; input/ukuran sama, light/dark, teks panjang, Dynamic Type besar serta Reduce Motion/Transparency yang relevan. Pisahkan perbedaan citra MapKit yang dimuat asinkron dari perubahan layout. Snapshot bukan pengganti pemeriksaan interaksi.

**Uji kejelasan:**

| Tugas pembaca | Jalur target yang harus mudah ditemukan |
| --- | --- |
| Ubah kartu daftar | List/GardenListScreen → List/Components/GardenCard |
| Ubah susunan profil | Profile/GardenProfileScreen → Profile/GardenProfileContent |
| Cari proses pengajuan | Review/ReviewSubmissionView → onSubmit di Profile/GardenProfileScreen → Review/ReviewService |
| Cari gagal simpan kebun/review | Profile/GardenProfileScreen callback → AppFlow → Shared/GardenStore |
| Ubah draf pupuk | History/FertilizerHistoryScreen → History/FertilizerDraft |
| Cari penyimpanan draf peta | Mapping/GardenBoundaryScreen → AppFlow callback → Mapping/MappingDraftStore |
| Temukan form baru dan edit | Details/GardenDetailsScreen, dua initializer untuk satu implementasi |
| Bedakan unduhan | MapDownloads untuk reference peta; Review/ReviewReportDownload untuk laporan |

Selesai bila: seluruh path tujuan terisi tanpa lokasi lama ganda; tanggung jawab dua file baru dan setiap file Shared jelas; tidak ada wrapper kosong atau store tambahan; link dokumentasi valid; pemeriksaan yang dijalankan dan batasannya tercatat. Agent memverifikasi jalur pencarian tersebut; kemudahan belajar pengguna tidak dianggap terbukti hanya karena build/test lulus.

## 7. Lampiran: perpindahan 74 file yang ada

Semua tujuan di bawah relatif terhadap `PalmOilFarmer/Features/Gardens/`. Asal ditautkan ke file yang ada sekarang. Tujuan belum dibuat. Semua nama tipe dan file dipertahankan; dua file baru pada bagian 4 tidak termasuk 74 perpindahan ini.

| File asal | Tujuan |
| --- | --- |
| [Data/CurrentLocationProvider.swift](../PalmOilFarmer/Features/Gardens/Shared/CurrentLocationProvider.swift) | `Shared/CurrentLocationProvider.swift` |
| [Data/GardenPersistence.swift](../PalmOilFarmer/Features/Gardens/Shared/GardenPersistence.swift) | `Shared/GardenPersistence.swift` |
| [Data/GardenStore.swift](../PalmOilFarmer/Features/Gardens/Shared/GardenStore.swift) | `Shared/GardenStore.swift` |
| [Data/LocationSearchService.swift](../PalmOilFarmer/Features/Gardens/Registration/LocationSearchService.swift) | `Registration/LocationSearchService.swift` |
| [Data/MappingDraftStore.swift](../PalmOilFarmer/Features/Gardens/Mapping/MappingDraftStore.swift) | `Mapping/MappingDraftStore.swift` |
| [Data/PhotoLocationReader.swift](../PalmOilFarmer/Features/Gardens/Registration/PhotoLocationReader.swift) | `Registration/PhotoLocationReader.swift` |
| [Data/ReviewReportDownload.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewReportDownload.swift) | `Review/ReviewReportDownload.swift` |
| [Data/ReviewService.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewService.swift) | `Review/ReviewService.swift` |
| [Models/FertilizerDraft.swift](../PalmOilFarmer/Features/Gardens/History/FertilizerDraft.swift) | `History/FertilizerDraft.swift` |
| [Models/FertilizerRecommendationReport.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Models/FertilizerRecommendationReport.swift) | `Recommendations/Models/FertilizerRecommendationReport.swift` |
| [Models/FertilizerReference.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Models/FertilizerReference.swift) | `Recommendations/Models/FertilizerReference.swift` |
| [Models/Garden.swift](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift) | `Shared/Garden.swift` |
| [Models/GardenBoundary.swift](../PalmOilFarmer/Features/Gardens/Shared/GardenBoundary.swift) | `Shared/GardenBoundary.swift` |
| [Models/GardenDisplayMetrics.swift](../PalmOilFarmer/Features/Gardens/Shared/GardenDisplayMetrics.swift) | `Shared/GardenDisplayMetrics.swift` |
| [Models/GardenLocalReport.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Models/GardenLocalReport.swift) | `Recommendations/Models/GardenLocalReport.swift` |
| [Models/GardenLocation.swift](../PalmOilFarmer/Features/Gardens/Shared/GardenLocation.swift) | `Shared/GardenLocation.swift` |
| [Models/GardenReview.swift](../PalmOilFarmer/Features/Gardens/Review/GardenReview.swift) | `Review/GardenReview.swift` |
| [Models/MapDownloadItem.swift](../PalmOilFarmer/Features/Gardens/MapDownloads/MapDownloadItem.swift) | `MapDownloads/MapDownloadItem.swift` |
| [Models/MapDownloadState.swift](../PalmOilFarmer/Features/Gardens/MapDownloads/MapDownloadState.swift) | `MapDownloads/MapDownloadState.swift` |
| [Models/MappingDraft.swift](../PalmOilFarmer/Features/Gardens/Mapping/MappingDraft.swift) | `Mapping/MappingDraft.swift` |
| [Models/NutrientReference.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Models/NutrientReference.swift) | `Recommendations/Models/NutrientReference.swift` |
| [Models/RainfallDay.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Models/RainfallDay.swift) | `Recommendations/Models/RainfallDay.swift` |
| [Models/RainfallForecast.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Models/RainfallForecast.swift) | `Recommendations/Models/RainfallForecast.swift` |
| [Models/ReviewContactDetails.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewContactDetails.swift) | `Review/ReviewContactDetails.swift` |
| [Models/ReviewStatus.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewStatus.swift) | `Review/ReviewStatus.swift` |
| [Models/ReviewTimelineEntry.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewTimelineEntry.swift) | `Review/ReviewTimelineEntry.swift` |
| [Views/Components/BoundaryGuideIllustration.swift](../PalmOilFarmer/Features/Gardens/Registration/Components/BoundaryGuideIllustration.swift) | `Registration/Components/BoundaryGuideIllustration.swift` |
| [Views/Components/FertilizerAllocationSection.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Components/FertilizerAllocationSection.swift) | `Recommendations/Components/FertilizerAllocationSection.swift` |
| [Views/Components/GardenAreaIcon.swift](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenAreaIcon.swift) | `Shared/Components/GardenAreaIcon.swift` |
| [Views/Components/GardenMapView.swift](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenMapView.swift) | `Shared/Components/GardenMapView.swift` |
| [Views/Components/GardenSectionHeader.swift](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenSectionHeader.swift) | `Shared/Components/GardenSectionHeader.swift` |
| [Views/Components/HistoryValueRow.swift](../PalmOilFarmer/Features/Gardens/Shared/Components/HistoryValueRow.swift) | `Shared/Components/HistoryValueRow.swift` |
| [Views/Components/LocationMapPreview.swift](../PalmOilFarmer/Features/Gardens/Shared/Components/LocationMapPreview.swift) | `Shared/Components/LocationMapPreview.swift` |
| [Views/Components/MapDownloadCard.swift](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapDownloadCard.swift) | `MapDownloads/Components/MapDownloadCard.swift` |
| [Views/Components/MapDownloadProgressView.swift](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapDownloadProgressView.swift) | `MapDownloads/Components/MapDownloadProgressView.swift` |
| [Views/Components/MapHeroView.swift](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapHeroView.swift) | `MapDownloads/Components/MapHeroView.swift` |
| [Views/Components/SeedlingIcon.swift](../PalmOilFarmer/Features/Gardens/List/Components/SeedlingIcon.swift) | `List/Components/SeedlingIcon.swift` |
| [Views/History/Components/FertilizerEntryCard.swift](../PalmOilFarmer/Features/Gardens/History/Components/FertilizerEntryCard.swift) | `History/Components/FertilizerEntryCard.swift` |
| [Views/History/Components/GardenHistoryChart.swift](../PalmOilFarmer/Features/Gardens/History/Components/GardenHistoryChart.swift) | `History/Components/GardenHistoryChart.swift` |
| [Views/History/Components/GardenHistoryViews.swift](../PalmOilFarmer/Features/Gardens/History/Components/GardenHistoryViews.swift) | `History/Components/GardenHistoryViews.swift` |
| [Views/History/FertilizerHistoryScreen.swift](../PalmOilFarmer/Features/Gardens/History/FertilizerHistoryScreen.swift) | `History/FertilizerHistoryScreen.swift` |
| [Views/History/HarvestHistoryScreen.swift](../PalmOilFarmer/Features/Gardens/History/HarvestHistoryScreen.swift) | `History/HarvestHistoryScreen.swift` |
| [Views/List/Components/GardenCard.swift](../PalmOilFarmer/Features/Gardens/List/Components/GardenCard.swift) | `List/Components/GardenCard.swift` |
| [Views/List/Components/MappingDraftCard.swift](../PalmOilFarmer/Features/Gardens/List/Components/MappingDraftCard.swift) | `List/Components/MappingDraftCard.swift` |
| [Views/List/GardenListScreen.swift](../PalmOilFarmer/Features/Gardens/List/GardenListScreen.swift) | `List/GardenListScreen.swift` |
| [Views/Mapping/Components/BoundaryEditorLayout.swift](../PalmOilFarmer/Features/Gardens/Mapping/Components/BoundaryEditorLayout.swift) | `Mapping/Components/BoundaryEditorLayout.swift` |
| [Views/Mapping/GardenBoundaryScreen.swift](../PalmOilFarmer/Features/Gardens/Mapping/GardenBoundaryScreen.swift) | `Mapping/GardenBoundaryScreen.swift` |
| [Views/Mapping/MapDownloadScreen.swift](../PalmOilFarmer/Features/Gardens/MapDownloads/MapDownloadScreen.swift) | `MapDownloads/MapDownloadScreen.swift` |
| [Views/Profile/Components/GardenFertilizerHistorySection.swift](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenFertilizerHistorySection.swift) | `Profile/Components/GardenFertilizerHistorySection.swift` |
| [Views/Profile/Components/GardenHarvestHistorySection.swift](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenHarvestHistorySection.swift) | `Profile/Components/GardenHarvestHistorySection.swift` |
| [Views/Profile/Components/GardenProfileProgressView.swift](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenProfileProgressView.swift) | `Profile/Components/GardenProfileProgressView.swift` |
| [Views/Profile/Components/GardenSummaryView.swift](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenSummaryView.swift) | `Profile/Components/GardenSummaryView.swift` |
| [Views/Profile/GardenProfileScreen.swift](../PalmOilFarmer/Features/Gardens/Profile/GardenProfileScreen.swift) | `Profile/GardenProfileScreen.swift` |
| [Views/Recommendations/Components/AllocationOverviewMap.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Components/AllocationOverviewMap.swift) | `Recommendations/Components/AllocationOverviewMap.swift` |
| [Views/Recommendations/Components/BoundarySilhouette.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Components/BoundarySilhouette.swift) | `Recommendations/Components/BoundarySilhouette.swift` |
| [Views/Recommendations/Components/FertilizerCostTable.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Components/FertilizerCostTable.swift) | `Recommendations/Components/FertilizerCostTable.swift` |
| [Views/Recommendations/Components/NutrientProjectionChart.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Components/NutrientProjectionChart.swift) | `Recommendations/Components/NutrientProjectionChart.swift` |
| [Views/Recommendations/Components/RainfallForecastView.swift](../PalmOilFarmer/Features/Gardens/Recommendations/Components/RainfallForecastView.swift) | `Recommendations/Components/RainfallForecastView.swift` |
| [Views/Recommendations/FertilizerRecommendationScreen.swift](../PalmOilFarmer/Features/Gardens/Recommendations/FertilizerRecommendationScreen.swift) | `Recommendations/FertilizerRecommendationScreen.swift` |
| [Views/Recommendations/NutrientReferenceScreen.swift](../PalmOilFarmer/Features/Gardens/Recommendations/NutrientReferenceScreen.swift) | `Recommendations/NutrientReferenceScreen.swift` |
| [Views/Recommendations/RecommendationAreaMapScreen.swift](../PalmOilFarmer/Features/Gardens/Recommendations/RecommendationAreaMapScreen.swift) | `Recommendations/RecommendationAreaMapScreen.swift` |
| [Views/Recommendations/RecommendationAreaPickerScreen.swift](../PalmOilFarmer/Features/Gardens/Recommendations/RecommendationAreaPickerScreen.swift) | `Recommendations/RecommendationAreaPickerScreen.swift` |
| [Views/Registration/Components/GardenPhotoPickerView.swift](../PalmOilFarmer/Features/Gardens/Registration/Components/GardenPhotoPickerView.swift) | `Registration/Components/GardenPhotoPickerView.swift` |
| [Views/Registration/GardenDetailsScreen.swift](../PalmOilFarmer/Features/Gardens/Details/GardenDetailsScreen.swift) | `Details/GardenDetailsScreen.swift` |
| [Views/Registration/LocationSearchScreen.swift](../PalmOilFarmer/Features/Gardens/Registration/LocationSearchScreen.swift) | `Registration/LocationSearchScreen.swift` |
| [Views/Registration/PhotoLocationConfirmationScreen.swift](../PalmOilFarmer/Features/Gardens/Mapping/PhotoLocationConfirmationScreen.swift) | `Mapping/PhotoLocationConfirmationScreen.swift` |
| [Views/Registration/PlantingDatePickerScreen.swift](../PalmOilFarmer/Features/Gardens/Details/PlantingDatePickerScreen.swift) | `Details/PlantingDatePickerScreen.swift` |
| [Views/Registration/RegistrationFlow.swift](../PalmOilFarmer/Features/Gardens/Registration/RegistrationFlow.swift) | `Registration/RegistrationFlow.swift` |
| [Views/Review/Components/ConsentCheckbox.swift](../PalmOilFarmer/Features/Gardens/Review/Components/ConsentCheckbox.swift) | `Review/Components/ConsentCheckbox.swift` |
| [Views/Review/Components/ReviewDownloadProgressCard.swift](../PalmOilFarmer/Features/Gardens/Review/Components/ReviewDownloadProgressCard.swift) | `Review/Components/ReviewDownloadProgressCard.swift` |
| [Views/Review/Components/ReviewTimelineRow.swift](../PalmOilFarmer/Features/Gardens/Review/Components/ReviewTimelineRow.swift) | `Review/Components/ReviewTimelineRow.swift` |
| [Views/Review/ReviewContactFormScreen.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewContactFormScreen.swift) | `Review/ReviewContactFormScreen.swift` |
| [Views/Review/ReviewRequestScreen.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewRequestScreen.swift) | `Review/ReviewRequestScreen.swift` |
| [Views/Review/ReviewStatusScreen.swift](../PalmOilFarmer/Features/Gardens/Review/ReviewStatusScreen.swift) | `Review/ReviewStatusScreen.swift` |
