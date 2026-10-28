# Peta halaman dan alur

Lokasi file mengikuti struktur Features langsung dan Shared/Gardens; lihat [Architecture](Architecture.md).

Peta source setelah refactor. **Aktif** berarti terhubung dari root; data atau prasyarat tertentu tetap dapat diperlukan. **Reference/preview** tidak terhubung melalui input root saat ini. **Eksperimen** hanya melalui entry point terpisah. Nama tipe di bawah merupakan tautan ke file relatif repo.

## Alur navigasi (bukan pohon komposisi)

```text
PalmOilFarmerApp → AppFlow → GardenListScreen
├── pilih kebun → push GardenProfileScreen
│   ├── edit → sheet GardenDetailsScreen (editing)
│   │   ├── push SelectionListScreen (jenis tanah)
│   │   └── sheet PlantingDatePickerScreen
│   ├── riwayat → sheet FertilizerHistoryScreen / HarvestHistoryScreen
│   │   └── pupuk → push SelectionListScreen (jenis pupuk)
│   ├── ajukan → sheet NavigationStack: ReviewRequestScreen
│   │   └── push ReviewContactFormScreen → simpan → tutup sheet → push ReviewStatusScreen
│   ├── lihat hasil → push FertilizerRecommendationScreen
│   └── ReviewStatusScreen → callback profil → push FertilizerRecommendationScreen
│       ├── referensi hara → sheet NutrientReferenceScreen (jika data tersedia)
│       └── alokasi + Garden → FindingBlockView tertanam
│           ├── sheet BlockAreaPickerScreen
│           └── full screen FindingBlockMapScreen
├── daftar → sheet RegistrationFlow
│   └── guide inline → ganti isi LocationSearchScreen
│       └── pilih lokasi → tutup sheet → full screen GardenBoundaryScreen
│           ├── sumber foto → PhotoLocationConfirmationScreen (ganti isi)
│           ├── konfirmasi batas → sheet GardenDetailsScreen (baru) → save → daftar
│           └── tunda (jika diizinkan) → simpan MappingDraft → daftar
└── lanjutkan draf → full screen GardenBoundaryScreen (resumesDraft)

Reference: daftar dengan downloads → callback supplied preview;
           MapDownloadScreen → onMapBoundary callback (root tidak memasok downloads).
Reference: rekomendasi tanpa Garden → sheet RecommendationAreaPickerScreen
                                   → full screen RecommendationAreaMapScreen.
Eksperimen: FindingWaypointFlow → tab Home (pengelolaan kebun) / tab Pemupukan
                              → WaypointGardenListScreen → push WaypointMapScreen.
```

Alur review mempertahankan perilaku asal: tombol profil setelah ada status membuka hasil; status pengajuan dibuka setelah submit. Ketersediaan layanan dan data laporan berbeda dari sekadar keterhubungan screen. Submit tanpa transport hanya memakai simulasi pada DEBUG; Release menampilkan kegagalan layanan. Tidak ada endpoint baru dalam refactor.

## Komposisi halaman daftar

[GardenListScreen](../PalmOilFarmer/Features/GardenList/GardenListScreen.swift)

```text
Judul Text inline
├── kosong (gardens, drafts, downloads semua kosong)
│   └── EmptyStateView → SeedlingIcon
├── drafts → Button inline → MappingDraftCard → LocationMapPreview
├── gardens → Button inline → GardenCard → GardenMapView + GardenAreaIcon
├── downloads opsional → Button inline → MapDownloadCard
│   ├── gambar reference atau LocationMapPreview
│   └── MapDownloadProgressView
└── safeAreaInset → PrimaryActionButton
```

File komponennya: [MappingDraftCard](../PalmOilFarmer/Features/GardenList/Components/MappingDraftCard.swift), [GardenCard](../PalmOilFarmer/Features/GardenList/Components/GardenCard.swift), [GardenMapView](../PalmOilFarmer/Shared/Gardens/Components/GardenMapView.swift), [GardenAreaIcon](../PalmOilFarmer/Shared/Gardens/Components/GardenAreaIcon.swift), [LocationMapPreview](../PalmOilFarmer/Shared/Gardens/Components/LocationMapPreview.swift), [MapDownloadCard](../PalmOilFarmer/Features/MapDownloads/Components/MapDownloadCard.swift), [MapDownloadProgressView](../PalmOilFarmer/Features/MapDownloads/Components/MapDownloadProgressView.swift), [EmptyStateView](../PalmOilFarmer/Core/DesignSystem/Components/EmptyStateView.swift), [SeedlingIcon](../PalmOilFarmer/Features/GardenList/Components/SeedlingIcon.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift).

Data: `GardenStore.gardens` dan `MappingDraftStore.drafts` → [AppFlow](../PalmOilFarmer/App/AppFlow.swift) → daftar. [AppFlow](../PalmOilFarmer/App/AppFlow.swift) menyaring draf yang ID-nya sudah menjadi kebun tersimpan. `onSelectGarden`, `onRegisterGarden`, `onResumeDraft` hanya callback; [AppFlow](../PalmOilFarmer/App/AppFlow.swift) memilih presentasi. `downloads` / `onSelectDownload`, reference image dan metrics disediakan API/preview, **tidak dipasok [AppFlow](../PalmOilFarmer/App/AppFlow.swift)**. Empty/loading/failure unduhan adalah state, bukan halaman baru.

## Register screen dan flow

Setiap entri memisahkan asal presentasi, komposisi, dan pemilik data. Komponen inline tetap disebutkan agar tidak perlu menebak file.

### Alur aplikasi

**File:** [AppFlow](../PalmOilFarmer/App/AppFlow.swift).

**Asal/status:** Aktif; WindowGroup dari [PalmOilFarmerApp](../PalmOilFarmer/App/PalmOilFarmerApp.swift)

**Komposisi:** NavigationStack dan [GardenListScreen](../PalmOilFarmer/Features/GardenList/GardenListScreen.swift); sheet/full screen/alert inline.

**Data dan output:** Memiliki [GardenStore](../PalmOilFarmer/Shared/Gardens/GardenStore.swift), [MappingDraftStore](../PalmOilFarmer/Features/GardenMapping/MappingDraftStore.swift), selectedGardenID, pendingLocation, mappingDraft, retrySearch. Save kebun → store.add, lalu remove draf; gagal save tetap ditampilkan.

**Varian/modal:** Push profil; sheet registration; full screen mapping. Bukan screen visual mandiri.

### Kebun

**File:** [GardenListScreen](../PalmOilFarmer/Features/GardenList/GardenListScreen.swift).

**Asal/status:** Aktif; konten NavigationStack [AppFlow](../PalmOilFarmer/App/AppFlow.swift)

**Komposisi:** Pohon komposisi terinci di atas.

**Data dan output:** Input arrays dan callbacks; tidak memiliki store atau write langsung.

**Varian/modal:** Kosong, draf, kebun; unduhan hanya reference/input tambahan.

### Detail Kebun

**File:** [GardenProfileScreen](../PalmOilFarmer/Features/GardenProfile/GardenProfileScreen.swift).

**Asal/status:** Aktif; push dari daftar melalui [AppFlow](../PalmOilFarmer/App/AppFlow.swift). Juga dipakai tab Home eksperimen.

**Komposisi:** [GardenSummaryView](../PalmOilFarmer/Features/GardenProfile/Components/GardenSummaryView.swift), [GardenFertilizerHistorySection](../PalmOilFarmer/Features/GardenProfile/Components/GardenFertilizerHistorySection.swift), [GardenHarvestHistorySection](../PalmOilFarmer/Features/GardenProfile/Components/GardenHarvestHistorySection.swift), [GardenProfileProgressView](../PalmOilFarmer/Features/GardenProfile/Components/GardenProfileProgressView.swift), [GardenHistoryChart](../PalmOilFarmer/Features/GardenHistory/Components/GardenHistoryChart.swift); [GardenProfileContent](../PalmOilFarmer/Features/GardenProfile/GardenProfileContent.swift) menyusun map/gradient, judul, ringkasan, riwayat, review action dan progress. ScrollView, toolbar dan presentasi tetap di screen.

**Data dan output:** [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift) terkini milik induk. State modal/editor/review/scroll lokal. onUpdate/onDelete/onUpdateReview diteruskan ke store. [ReviewService](../PalmOilFarmer/Features/GardenReview/ReviewService.swift) lewat environment; refresh tidak dipindah.

**Varian/modal:** standard aktif; overview/chart reference. Sheet edit, pupuk, panen, [ReviewSubmissionView](../PalmOilFarmer/Features/GardenReview/ReviewSubmissionView.swift) (NavigationStack informasi → kontak); push status/hasil; confirmation hapus dan alert kegagalan. Section riwayat memakai [FertilizerHistoryCard](../PalmOilFarmer/Features/GardenHistory/Components/GardenHistoryViews.swift), [HarvestHistoryCard](../PalmOilFarmer/Features/GardenHistory/Components/GardenHistoryViews.swift), [GardenSectionHeader](../PalmOilFarmer/Features/GardenProfile/Components/GardenSectionHeader.swift).

### Petakan batas kebun

**File:** [RegistrationFlow](../PalmOilFarmer/Features/GardenRegistration/RegistrationFlow.swift).

**Asal/status:** Aktif; sheet dari [AppFlow](../PalmOilFarmer/App/AppFlow.swift), juga eksperimen Home.

**Komposisi:** Guide inline: Text, [BoundaryGuideIllustration](../PalmOilFarmer/Features/GardenRegistration/Components/BoundaryGuideIllustration.swift), [StepIndicator](../PalmOilFarmer/Core/DesignSystem/Components/StepIndicator.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift). Cabang lain menampilkan [LocationSearchScreen](../PalmOilFarmer/Features/GardenRegistration/LocationSearchScreen.swift).

**Data dan output:** step milik flow; onLocate mengirim [GardenLocation](../PalmOilFarmer/Shared/Gardens/GardenLocation.swift) ke induk. Initial photo parameters dipertahankan untuk kompatibilitas preview meskipun tidak mengubah alur saat ini.

**Varian/modal:** guide → address melalui pergantian isi. Enum photo historis juga masuk cabang pencarian; bukan screen foto produksi tersendiri.

### Cari lokasi kebun

**File:** [LocationSearchScreen](../PalmOilFarmer/Features/GardenRegistration/LocationSearchScreen.swift).

**Asal/status:** Aktif; pergantian isi [RegistrationFlow](../PalmOilFarmer/Features/GardenRegistration/RegistrationFlow.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), field pencarian, hasil/current-location rows dan pesan inline; [GardenPhotoPickerView](../PalmOilFarmer/Features/GardenRegistration/Components/GardenPhotoPickerView.swift).

**Data dan output:** State query/results/focus/photo/loading/error dan [CurrentLocationProvider](../PalmOilFarmer/Shared/Gardens/CurrentLocationProvider.swift) lokal; closure searchLocations default [LocationSearchService](../PalmOilFarmer/Features/GardenRegistration/LocationSearchService.swift). [PhotoLocationReader](../PalmOilFarmer/Features/GardenRegistration/PhotoLocationReader.swift) membaca metadata. onSelect mengirim lokasi ke flow.

**Varian/modal:** Kosong, mencari, hasil, gagal, GPS dan foto. PhotosPicker sistem dibuka komponen foto; foto tanpa koordinat tetap error di screen yang sama.

### Petakan batas kebun

**File:** [GardenBoundaryScreen](../PalmOilFarmer/Features/GardenMapping/GardenBoundaryScreen.swift).

**Asal/status:** Aktif; fullScreenCover [AppFlow](../PalmOilFarmer/App/AppFlow.swift) setelah pemilihan lokasi atau lanjut draf.

**Komposisi:** editor inline: MapReader/Map/annotation, [BoundaryEditorLayout](../PalmOilFarmer/Features/GardenMapping/Components/BoundaryEditorLayout.swift), [BoundaryPointMarker](../PalmOilFarmer/Shared/Gardens/Components/GardenMapView.swift). [PhotoLocationConfirmationScreen](../PalmOilFarmer/Features/GardenMapping/PhotoLocationConfirmationScreen.swift) menjadi cabang isi sebelum editor.

**Data dan output:** State boundary, camera, photoConfirmed, lokasi/error dan showsDetails tetap di screen. onSave → [AppFlow](../PalmOilFarmer/App/AppFlow.swift)/store; onDefer → [MappingDraftStore](../PalmOilFarmer/Features/GardenMapping/MappingDraftStore.swift).save; onSearchAgain meminta induk membuka ulang pencarian.

**Varian/modal:** Kosong/garis/poligon, overview, resumesDraft, konfirmasi foto. Sheet [GardenDetailsScreen](../PalmOilFarmer/Features/GardenDetails/GardenDetailsScreen.swift); dialog keluar dan error save/GPS. Task GPS tetap pada editor.

### Lokasi Ditemukan dari Foto

**File:** [PhotoLocationConfirmationScreen](../PalmOilFarmer/Features/GardenMapping/PhotoLocationConfirmationScreen.swift).

**Asal/status:** Aktif bersyarat sumber photo; pergantian isi [GardenBoundaryScreen](../PalmOilFarmer/Features/GardenMapping/GardenBoundaryScreen.swift).

**Komposisi:** Map/marker dan teks inline; [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift), [SheetGlassBackground](../PalmOilFarmer/Core/DesignSystem/Styles/SheetGlassBackground.swift).

**Data dan output:** Input location; callback onConfirm mengubah state induk; onSearchAgain meminta ulang pencarian dan dismiss induk. Tidak menyimpan data.

**Varian/modal:** Ya, Ini kebun saya → editor; Cari Lagi → tutup mapping dan buka registration.

### Data kebun / Edit kebun

**File:** [GardenDetailsScreen](../PalmOilFarmer/Features/GardenDetails/GardenDetailsScreen.swift).

**Asal/status:** Aktif; sheet dari [GardenBoundaryScreen](../PalmOilFarmer/Features/GardenMapping/GardenBoundaryScreen.swift) atau [GardenProfileScreen](../PalmOilFarmer/Features/GardenProfile/GardenProfileScreen.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), [GardenMapView](../PalmOilFarmer/Shared/Gardens/Components/GardenMapView.swift), [FormSelectionRow](../PalmOilFarmer/Core/DesignSystem/Components/FormSelectionRow.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift); text field dan detailMetric inline.

**Data dan output:** Draf name/year/month/soil serta focus/error lokal. Mode baru menggunakan location.id, edit mempertahankan originalGarden. onSave Bool menentukan sukses; store dimiliki induk.

**Varian/modal:** Sheet [PlantingDatePickerScreen](../PalmOilFarmer/Features/GardenDetails/PlantingDatePickerScreen.swift), push [SelectionListScreen](../PalmOilFarmer/Core/DesignSystem/Components/SelectionListScreen.swift) tanah, alert validasi/save, tutup/batal. Dipakai lintas area tetapi satu implementasi di Registration.

### Tahun Tanam

**File:** [PlantingDatePickerScreen](../PalmOilFarmer/Features/GardenDetails/PlantingDatePickerScreen.swift).

**Asal/status:** Aktif; sheet dari [GardenDetailsScreen](../PalmOilFarmer/Features/GardenDetails/GardenDetailsScreen.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift) dan dua wheel Picker inline.

**Data dan output:** month/year lokal; onConfirm mengirim pilihan ke draf GardenDetails; belum menyimpan kebun.

**Varian/modal:** Batal dismiss tanpa callback; konfirmasi mengirim nilai. Detent besar pada accessibility Dynamic Type.

### Jenis Tanah / Jenis Pupuk

**File:** [SelectionListScreen](../PalmOilFarmer/Core/DesignSystem/Components/SelectionListScreen.swift).

**Asal/status:** Aktif; push dari [GardenDetailsScreen](../PalmOilFarmer/Features/GardenDetails/GardenDetailsScreen.swift) atau [FertilizerHistoryScreen](../PalmOilFarmer/Features/GardenHistory/FertilizerHistoryScreen.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift) dan daftar pilihan/checkmark/footer inline di design system.

**Data dan output:** Input strings, pilihan dan onSelect; tidak mengenal [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift)/[SoilType](../PalmOilFarmer/Shared/Gardens/Garden.swift)/[FertilizerDraft](../PalmOilFarmer/Features/GardenHistory/FertilizerDraft.swift). Induk mengubah draf.

**Varian/modal:** Konten generik berdasarkan caller. Tidak membuat salinan halaman domain hanya untuk nama Screen.

### Riwayat Pemupukan

**File:** [FertilizerHistoryScreen](../PalmOilFarmer/Features/GardenHistory/FertilizerHistoryScreen.swift).

**Asal/status:** Aktif; sheet dari profil.

**Komposisi:** NavigationStack, [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), [FertilizerEntryCard](../PalmOilFarmer/Features/GardenHistory/Components/FertilizerEntryCard.swift), tombol tambah dan context menu inline.

**Data dan output:** drafts, selectedDraftID, error lokal. [FertilizerEntryCard](../PalmOilFarmer/Features/GardenHistory/Components/FertilizerEntryCard.swift) memakai binding ke draft. onSave records → profil → [GardenStore](../PalmOilFarmer/Shared/Gardens/GardenStore.swift).update.

**Varian/modal:** Push [SelectionListScreen](../PalmOilFarmer/Core/DesignSystem/Components/SelectionListScreen.swift) pupuk, tambah/hapus draft, validasi dan gagal save tetap di editor. Preview includesEmptyDraft berada di GardenHistoryPreviews.

### Riwayat Panen

**File:** [HarvestHistoryScreen](../PalmOilFarmer/Features/GardenHistory/HarvestHistoryScreen.swift).

**Asal/status:** Aktif; sheet dari profil.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), kartu frekuensi dan berat, Stepper/Picker inline.

**Data dan output:** frequency/weight/error lokal; onSave [HarvestRecord](../PalmOilFarmer/Shared/Gardens/Garden.swift) → profil → store.

**Varian/modal:** Default atau nilai lama, validasi, batal/simpan. UI tidak ditutup bila save gagal.

### Permintaan Peninjauan

**File:** [ReviewRequestScreen](../PalmOilFarmer/Features/GardenReview/ReviewRequestScreen.swift).

**Asal/status:** Aktif; root NavigationStack di sheet profil.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), teks penjelasan/persyaratan dan [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift) inline; [ConsentCheckbox](../PalmOilFarmer/Features/GardenReview/Components/ConsentCheckbox.swift).

**Data dan output:** hasConsent dan showsConsentError lokal; onContinue memicu state showsReviewForm di profil setelah persetujuan. Tidak mengirim atau menyimpan permintaan.

**Varian/modal:** Push [ReviewContactFormScreen](../PalmOilFarmer/Features/GardenReview/ReviewContactFormScreen.swift); dapat menutup sheet.

### Permintaan Peninjauan — data kontak

**File:** [ReviewContactFormScreen](../PalmOilFarmer/Features/GardenReview/ReviewContactFormScreen.swift).

**Asal/status:** Aktif; push di sheet review profil.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), contactField inline, [ConsentCheckbox](../PalmOilFarmer/Features/GardenReview/Components/ConsentCheckbox.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift).

**Data dan output:** name/phone/address/consent/focus/submitting/error lokal. onSubmit async diteruskan ReviewSubmissionView dari submitReview pada profil, memanggil [ReviewService](../PalmOilFarmer/Features/GardenReview/ReviewService.swift) dan saveReview; receivedReview di profil menjaga retry jika persistence gagal.

**Varian/modal:** Validasi, submitting, error; interaksi tutup dinonaktifkan saat submit. Berhasil: profil menutup sheet lalu push status.

### Status Pengajuan

**File:** [ReviewStatusScreen](../PalmOilFarmer/Features/GardenReview/ReviewStatusScreen.swift).

**Asal/status:** Aktif; push profil sesudah submit sukses.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), [ReviewTimelineRow](../PalmOilFarmer/Features/GardenReview/Components/ReviewTimelineRow.swift), [ReviewDownloadProgressCard](../PalmOilFarmer/Features/GardenReview/Components/ReviewDownloadProgressCard.swift), ShareLink, tombol hasil inline.

**Data dan output:** Input status/entries dari [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift).review atau reference. State menunjuk [ReviewReportDownload](../PalmOilFarmer/Features/GardenReview/ReviewReportDownload.swift).shared, onRefresh/onViewResults/onAdvanceDemo callback ke profil.

**Varian/modal:** submitted/scheduled/inReview/completed; unduhan progressing/saved/error jika URL tersedia. Simulasi DEBUG dapat maju melalui callback; hasil membuka rekomendasi.

### Hasil peninjauan / informasi kebun

**File:** [FertilizerRecommendationScreen](../PalmOilFarmer/Features/FertilizerRecommendations/FertilizerRecommendationScreen.swift).

**Asal/status:** Aktif; push profil/status. Reference menyediakan laporan contoh yang lebih lengkap.

**Komposisi:** reportPicker dan susunan tab inline. [BoundarySilhouette](../PalmOilFarmer/Features/FertilizerRecommendations/Components/BoundarySilhouette.swift), [NutrientProjectionChart](../PalmOilFarmer/Features/FertilizerRecommendations/Components/NutrientProjectionChart.swift), [FertilizerCostTable](../PalmOilFarmer/Features/FertilizerRecommendations/Components/FertilizerCostTable.swift), [RainfallForecastView](../PalmOilFarmer/Features/FertilizerRecommendations/Components/RainfallForecastView.swift), [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift); fallback tanpa [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift) memakai [AllocationOverviewMap](../PalmOilFarmer/Features/FertilizerRecommendations/Components/AllocationOverviewMap.swift) dan [FertilizerAllocationSection](../PalmOilFarmer/Features/FertilizerRecommendations/Components/FertilizerAllocationSection.swift).

**Data dan output:** report dan optional garden input; selectedTab/selectedAreaID/selectedReference lokal. Tidak menyimpan kebun. Report .local tidak mengarang data hara/biaya/cuaca.

**Varian/modal:** Tab nutrients/allocation/rainfall termasuk state data kosong. Sheet nutrient reference; jika garden nil, picker dan map area laporan. Root memasok garden sehingga alokasi memakai [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift).

### Referensi pupuk untuk unsur hara

**File:** [NutrientReferenceScreen](../PalmOilFarmer/Features/FertilizerRecommendations/NutrientReferenceScreen.swift).

**Asal/status:** Aktif bersyarat laporan punya nutrientReferences; sheet rekomendasi.

**Komposisi:** Teks referensi, daftar pupuk, divider dan catatan inline.

**Data dan output:** Input [NutrientReference](../PalmOilFarmer/Features/FertilizerRecommendations/Models/NutrientReference.swift) saja; tidak menyimpan atau memiliki store.

**Varian/modal:** Detent medium/large; data contoh tersedia di reference preview.

### Area Kebun — area laporan

**File:** [RecommendationAreaPickerScreen](../PalmOilFarmer/Features/FertilizerRecommendations/RecommendationAreaPickerScreen.swift).

**Asal/status:** Reference/preview dari rekomendasi tanpa [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift); sheet.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), pencarian, row/thumbnail inline dengan [GardenMapView](../PalmOilFarmer/Shared/Gardens/Components/GardenMapView.swift) atau gambar reference.

**Data dan output:** areas input, binding selectedAreaID, pendingAreaID dan query lokal. Konfirmasi menerbitkan pilihan, batal tidak.

**Varian/modal:** Daftar/filter kosong; tidak mengubah data tersimpan. Root saat ini memakai [BlockAreaPickerScreen](../PalmOilFarmer/Features/FindingBlock/Views/BlockAreaPickerScreen.swift).

### Navigasi — area laporan

**File:** [RecommendationAreaMapScreen](../PalmOilFarmer/Features/FertilizerRecommendations/RecommendationAreaMapScreen.swift).

**Asal/status:** Reference/preview; full screen dari rekomendasi tanpa [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift).

**Komposisi:** Map polygon/marker/garis, [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), distance/status card inline.

**Data dan output:** Input boundary/areas/selectedArea. Camera dan [WaypointLocationSession](../PalmOilFarmer/Features/FindingWaypoint/Data/WaypointLocationSession.swift) lokal, task berdasarkan scenePhase. Tidak menyimpan geometri.

**Varian/modal:** GPS/no target/akurasi rendah/pengaturan; close dismiss. Sesi tetap milik screen ini.

### Unduh Peta

**File:** [MapDownloadScreen](../PalmOilFarmer/Features/MapDownloads/MapDownloadScreen.swift).

**Asal/status:** Reference/preview; CodedUIFrameCatalog. Tidak dibuka [AppFlow](../PalmOilFarmer/App/AppFlow.swift).

**Komposisi:** [MapHeroView](../PalmOilFarmer/Features/MapDownloads/Components/MapHeroView.swift), [LocationMapPreview](../PalmOilFarmer/Shared/Gardens/Components/LocationMapPreview.swift) atau gambar reference, [MapDownloadProgressView](../PalmOilFarmer/Features/MapDownloads/Components/MapDownloadProgressView.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift).

**Data dan output:** Input location/state/onMapBoundary; tidak ada downloader baru atau persistence. State unduhan disediakan caller.

**Varian/modal:** downloading/completed/failed; completed memanggil onMapBoundary. Pernyataan UI unduhan adalah reference, bukan bukti implementasi offline map.

### Area Kebun — blok kebun

**File:** [BlockAreaPickerScreen](../PalmOilFarmer/Features/FindingBlock/Views/BlockAreaPickerScreen.swift).

**Asal/status:** Aktif; sheet dari [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift) dalam tab alokasi.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), field query, rows/checkmark inline, [BlockAreaThumbnail](../PalmOilFarmer/Features/FindingBlock/Views/Components/BlockAreaThumbnail.swift).

**Data dan output:** blocks input; selectedID binding milik [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift); pendingID/query lokal. Konfirmasi menerbitkan pilihan, batal hanya dismiss.

**Varian/modal:** Filter dan kosong. Tidak menulis [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift) atau laporan.

### Navigasi — blok kebun

**File:** [FindingBlockMapScreen](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockMapScreen.swift).

**Asal/status:** Aktif; full screen dari [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift).

**Komposisi:** TimelineView/Map, [BlockMapOverlay](../PalmOilFarmer/Features/FindingBlock/Views/Components/BlockMapOverlay.swift), [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift); distanceCard/marker/accuracy/garis inline.

**Data dan output:** [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift)/zones input, selectedZoneID binding ke komponen alokasi; camera, [BlockLocationSession](../PalmOilFarmer/Features/FindingBlock/Data/BlockLocationSession.swift), hasFramedLocation lokal. Scene phase mengatur task GPS.

**Varian/modal:** GPS belum tersedia/stale/akurasi rendah/izin; Pengaturan membuka sistem, X menutup. Tidak menyimpan zona atau mengubah batas.

### Home / Pemupukan eksperimen

**File:** [FindingWaypointFlow](../PalmOilFarmer/Features/FindingWaypoint/Views/FindingWaypointFlow.swift).

**Asal/status:** Eksperimen; preview terpisah, bukan WindowGroup aplikasi.

**Komposisi:** TabView dua tab, NavigationStack, [GardenListScreen](../PalmOilFarmer/Features/GardenList/GardenListScreen.swift) dan [WaypointGardenListScreen](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointGardenListScreen.swift).

**Data dan output:** Memiliki [GardenStore](../PalmOilFarmer/Shared/Gardens/GardenStore.swift) sendiri untuk eksperimen, state navigasi/registration/mapping. Store memakai penyimpanan kebun yang sama jika flow sengaja dijalankan.

**Varian/modal:** Tab Home memakai GardenProfile dan GardenRegistration; tab Pemupukan membuka daftar zona. Tidak diaktifkan oleh refactor.

### Pemupukan eksperimen

**File:** [WaypointGardenListScreen](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointGardenListScreen.swift).

**Asal/status:** Eksperimen; tab Pemupukan [FindingWaypointFlow](../PalmOilFarmer/Features/FindingWaypoint/Views/FindingWaypointFlow.swift).

**Komposisi:** Teks pengantar, empty state dan private [WaypointGardenCard](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointGardenListScreen.swift) inline; [WaypointZoneThumbnail](../PalmOilFarmer/Features/FindingWaypoint/Views/Components/WaypointZoneThumbnail.swift).

**Data dan output:** gardens input; setiap kartu memiliki zones lokal dihitung lewat task(id: boundary.points) memakai [WaypointZoning](../PalmOilFarmer/Features/FindingWaypoint/Models/WaypointZoning.swift).

**Varian/modal:** Push [WaypointMapScreen](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointMapScreen.swift); link disabled jika bukan enam zona. Tidak menyimpan zona.

### Peta zona / panduan eksperimen

**File:** [WaypointMapScreen](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointMapScreen.swift).

**Asal/status:** Eksperimen; push dari kartu [WaypointGardenListScreen](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointGardenListScreen.swift).

**Komposisi:** Map, zone picker, tombol panduan, distance/status controls inline; memakai [WaypointPalette](../PalmOilFarmer/Features/FindingWaypoint/Views/Components/WaypointZoneThumbnail.swift).

**Data dan output:** [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift)/zones input; pilihan zona/camera/guidance dan [WaypointLocationSession](../PalmOilFarmer/Features/FindingWaypoint/Data/WaypointLocationSession.swift) lokal.

**Varian/modal:** Pilih zona 1–6, mulai/hentikan panduan, follow/frame garden, status izin/akurasi. Tidak mengaktifkan tracking latar atau menyimpan hasil.

## Bagian alokasi bukan halaman

[FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift) ditanam dalam [FertilizerRecommendationScreen](../PalmOilFarmer/Features/FertilizerRecommendations/FertilizerRecommendationScreen.swift). Ia menerima [Garden](../PalmOilFarmer/Shared/Gardens/Garden.swift) dan optional report, menghitung blocks dengan [BlockZoning](../PalmOilFarmer/Features/FindingBlock/Models/BlockZoning.swift), serta memiliki selectedBlockID, camera, loading dan state presentasi. Komposisinya Map + [BlockMapOverlay](../PalmOilFarmer/Features/FindingBlock/Views/Components/BlockMapOverlay.swift), tombol pilih area/Buka Map, [FertilizerAllocationSection](../PalmOilFarmer/Features/FertilizerRecommendations/Components/FertilizerAllocationSection.swift) atau teks periode kosong. Task pembagian blok tetap memakai identity boundary.points. Navigasi picker/map adalah tujuan anak, bukan komponen yang terus terlihat di halaman induk.

## Reference, fixture, dan komponen generik

- [CodedUIFrameCatalog](../PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUIFrameCatalog.swift): [CodedUIFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUIFrameCatalog.swift) memilih frame daftar/unduhan/profil/review/rekomendasi dan mock foto; bukan router produksi.
- [CodedUI2FlowPreviews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUI2FlowPreviews.swift): komposisi varian mapping, registration, profil dan rekomendasi.
- [NamaTest2Previews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift): [RegistrationFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift), [SearchFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift), [PhotoPickerFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift), [BoundaryFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift); peta dan control state reference, bukan screen tambahan dari root.
- [GlassSheetFlowPreviews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/GlassSheetFlowPreviews.swift): sheet registration di atas daftar.
- [GardenHistoryPreviews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/GardenHistoryPreviews.swift): editor dan kartu riwayat.
- [AppleSignInReferencePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/AppleSignInReferencePreview.swift): reference masuk dengan Apple, tidak terhubung ke app.
- [Fixtures](../PalmOilFarmer/PreviewSupport/Fixtures): [GardenPreviewData](../PalmOilFarmer/PreviewSupport/Fixtures/GardenPreviewData.swift), [RecommendationPreviewData](../PalmOilFarmer/PreviewSupport/Fixtures/RecommendationPreviewData.swift), [WaypointPreviewData](../PalmOilFarmer/PreviewSupport/Fixtures/WaypointPreviewData.swift); data contoh DEBUG, bukan sumber produksi.
- [DesignSystemCatalog](../PalmOilFarmer/Core/DesignSystem/Catalog/DesignSystemCatalog.swift): katalog UI generik light/dark/Dynamic Type; bukan halaman aplikasi.

Contoh penelusuran: cari **Kebun** → [GardenListScreen](../PalmOilFarmer/Features/GardenList/GardenListScreen.swift) → [GardenCard](../PalmOilFarmer/Features/GardenList/Components/GardenCard.swift) di GardenList/Components → [GardenMapView](../PalmOilFarmer/Shared/Gardens/Components/GardenMapView.swift) di Shared/Gardens/Components. Untuk klik kartu, kembali ke callback onSelectGarden → [AppFlow](../PalmOilFarmer/App/AppFlow.swift) → [GardenProfileScreen](../PalmOilFarmer/Features/GardenProfile/GardenProfileScreen.swift); profil bukan anak komposisi [GardenCard](../PalmOilFarmer/Features/GardenList/Components/GardenCard.swift).
