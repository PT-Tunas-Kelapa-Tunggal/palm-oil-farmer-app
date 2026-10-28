# Peta halaman dan alur

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
Eksperimen: FindingWaypointFlow → tab Home (alur Gardens) / tab Pemupukan
                              → WaypointGardenListScreen → push WaypointMapScreen.
```

Alur review mempertahankan perilaku asal: tombol profil setelah ada status membuka hasil; status pengajuan dibuka setelah submit. Ketersediaan layanan dan data laporan berbeda dari sekadar keterhubungan screen. Submit tanpa transport hanya memakai simulasi pada DEBUG; Release menampilkan kegagalan layanan. Tidak ada endpoint baru dalam refactor.

## Komposisi halaman daftar

[GardenListScreen](../PalmOilFarmer/Features/Gardens/List/GardenListScreen.swift)

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

File komponennya: [MappingDraftCard](../PalmOilFarmer/Features/Gardens/List/Components/MappingDraftCard.swift), [GardenCard](../PalmOilFarmer/Features/Gardens/List/Components/GardenCard.swift), [GardenMapView](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenMapView.swift), [GardenAreaIcon](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenAreaIcon.swift), [LocationMapPreview](../PalmOilFarmer/Features/Gardens/Shared/Components/LocationMapPreview.swift), [MapDownloadCard](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapDownloadCard.swift), [MapDownloadProgressView](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapDownloadProgressView.swift), [EmptyStateView](../PalmOilFarmer/Core/DesignSystem/Components/EmptyStateView.swift), [SeedlingIcon](../PalmOilFarmer/Features/Gardens/List/Components/SeedlingIcon.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift).

Data: `GardenStore.gardens` dan `MappingDraftStore.drafts` → [AppFlow](../PalmOilFarmer/App/AppFlow.swift) → daftar. [AppFlow](../PalmOilFarmer/App/AppFlow.swift) menyaring draf yang ID-nya sudah menjadi kebun tersimpan. `onSelectGarden`, `onRegisterGarden`, `onResumeDraft` hanya callback; [AppFlow](../PalmOilFarmer/App/AppFlow.swift) memilih presentasi. `downloads` / `onSelectDownload`, reference image dan metrics disediakan API/preview, **tidak dipasok [AppFlow](../PalmOilFarmer/App/AppFlow.swift)**. Empty/loading/failure unduhan adalah state, bukan halaman baru.

## Register screen dan flow

Setiap entri memisahkan asal presentasi, komposisi, dan pemilik data. Komponen inline tetap disebutkan agar tidak perlu menebak file.

### Alur aplikasi

**File:** [AppFlow](../PalmOilFarmer/App/AppFlow.swift).

**Asal/status:** Aktif; WindowGroup dari [PalmOilFarmerApp](../PalmOilFarmer/App/PalmOilFarmerApp.swift)

**Komposisi:** NavigationStack dan [GardenListScreen](../PalmOilFarmer/Features/Gardens/List/GardenListScreen.swift); sheet/full screen/alert inline.

**Data dan output:** Memiliki [GardenStore](../PalmOilFarmer/Features/Gardens/Shared/GardenStore.swift), [MappingDraftStore](../PalmOilFarmer/Features/Gardens/Mapping/MappingDraftStore.swift), selectedGardenID, pendingLocation, mappingDraft, retrySearch. Save kebun → store.add, lalu remove draf; gagal save tetap ditampilkan.

**Varian/modal:** Push profil; sheet registration; full screen mapping. Bukan screen visual mandiri.

### Kebun

**File:** [GardenListScreen](../PalmOilFarmer/Features/Gardens/List/GardenListScreen.swift).

**Asal/status:** Aktif; konten NavigationStack [AppFlow](../PalmOilFarmer/App/AppFlow.swift)

**Komposisi:** Pohon komposisi terinci di atas.

**Data dan output:** Input arrays dan callbacks; tidak memiliki store atau write langsung.

**Varian/modal:** Kosong, draf, kebun; unduhan hanya reference/input tambahan.

### Detail Kebun

**File:** [GardenProfileScreen](../PalmOilFarmer/Features/Gardens/Profile/GardenProfileScreen.swift).

**Asal/status:** Aktif; push dari daftar melalui [AppFlow](../PalmOilFarmer/App/AppFlow.swift). Juga dipakai tab Home eksperimen.

**Komposisi:** [GardenSummaryView](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenSummaryView.swift), [GardenFertilizerHistorySection](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenFertilizerHistorySection.swift), [GardenHarvestHistorySection](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenHarvestHistorySection.swift), [GardenProfileProgressView](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenProfileProgressView.swift), [GardenHistoryChart](../PalmOilFarmer/Features/Gardens/History/Components/GardenHistoryChart.swift); [GardenProfileContent](../PalmOilFarmer/Features/Gardens/Profile/GardenProfileContent.swift) menyusun map/gradient, judul, ringkasan, riwayat, review action dan progress. ScrollView, toolbar dan presentasi tetap di screen.

**Data dan output:** [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift) terkini milik induk. State modal/editor/review/scroll lokal. onUpdate/onDelete/onUpdateReview diteruskan ke store. [ReviewService](../PalmOilFarmer/Features/Gardens/Review/ReviewService.swift) lewat environment; refresh tidak dipindah.

**Varian/modal:** standard aktif; overview/chart reference. Sheet edit, pupuk, panen, [ReviewSubmissionView](../PalmOilFarmer/Features/Gardens/Review/ReviewSubmissionView.swift) (NavigationStack informasi → kontak); push status/hasil; confirmation hapus dan alert kegagalan. Section riwayat memakai [FertilizerHistoryCard](../PalmOilFarmer/Features/Gardens/History/Components/GardenHistoryViews.swift), [HarvestHistoryCard](../PalmOilFarmer/Features/Gardens/History/Components/GardenHistoryViews.swift), [GardenSectionHeader](../PalmOilFarmer/Features/Gardens/Profile/Components/GardenSectionHeader.swift).

### Petakan batas kebun

**File:** [RegistrationFlow](../PalmOilFarmer/Features/Gardens/Registration/RegistrationFlow.swift).

**Asal/status:** Aktif; sheet dari [AppFlow](../PalmOilFarmer/App/AppFlow.swift), juga eksperimen Home.

**Komposisi:** Guide inline: Text, [BoundaryGuideIllustration](../PalmOilFarmer/Features/Gardens/Registration/Components/BoundaryGuideIllustration.swift), [StepIndicator](../PalmOilFarmer/Core/DesignSystem/Components/StepIndicator.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift). Cabang lain menampilkan [LocationSearchScreen](../PalmOilFarmer/Features/Gardens/Registration/LocationSearchScreen.swift).

**Data dan output:** step milik flow; onLocate mengirim [GardenLocation](../PalmOilFarmer/Features/Gardens/Shared/GardenLocation.swift) ke induk. Initial photo parameters dipertahankan untuk kompatibilitas preview meskipun tidak mengubah alur saat ini.

**Varian/modal:** guide → address melalui pergantian isi. Enum photo historis juga masuk cabang pencarian; bukan screen foto produksi tersendiri.

### Cari lokasi kebun

**File:** [LocationSearchScreen](../PalmOilFarmer/Features/Gardens/Registration/LocationSearchScreen.swift).

**Asal/status:** Aktif; pergantian isi [RegistrationFlow](../PalmOilFarmer/Features/Gardens/Registration/RegistrationFlow.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), field pencarian, hasil/current-location rows dan pesan inline; [GardenPhotoPickerView](../PalmOilFarmer/Features/Gardens/Registration/Components/GardenPhotoPickerView.swift).

**Data dan output:** State query/results/focus/photo/loading/error dan [CurrentLocationProvider](../PalmOilFarmer/Features/Gardens/Shared/CurrentLocationProvider.swift) lokal; closure searchLocations default [LocationSearchService](../PalmOilFarmer/Features/Gardens/Registration/LocationSearchService.swift). [PhotoLocationReader](../PalmOilFarmer/Features/Gardens/Registration/PhotoLocationReader.swift) membaca metadata. onSelect mengirim lokasi ke flow.

**Varian/modal:** Kosong, mencari, hasil, gagal, GPS dan foto. PhotosPicker sistem dibuka komponen foto; foto tanpa koordinat tetap error di screen yang sama.

### Petakan batas kebun

**File:** [GardenBoundaryScreen](../PalmOilFarmer/Features/Gardens/Mapping/GardenBoundaryScreen.swift).

**Asal/status:** Aktif; fullScreenCover [AppFlow](../PalmOilFarmer/App/AppFlow.swift) setelah pemilihan lokasi atau lanjut draf.

**Komposisi:** editor inline: MapReader/Map/annotation, [BoundaryEditorLayout](../PalmOilFarmer/Features/Gardens/Mapping/Components/BoundaryEditorLayout.swift), [BoundaryPointMarker](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenMapView.swift). [PhotoLocationConfirmationScreen](../PalmOilFarmer/Features/Gardens/Mapping/PhotoLocationConfirmationScreen.swift) menjadi cabang isi sebelum editor.

**Data dan output:** State boundary, camera, photoConfirmed, lokasi/error dan showsDetails tetap di screen. onSave → [AppFlow](../PalmOilFarmer/App/AppFlow.swift)/store; onDefer → [MappingDraftStore](../PalmOilFarmer/Features/Gardens/Mapping/MappingDraftStore.swift).save; onSearchAgain meminta induk membuka ulang pencarian.

**Varian/modal:** Kosong/garis/poligon, overview, resumesDraft, konfirmasi foto. Sheet [GardenDetailsScreen](../PalmOilFarmer/Features/Gardens/Details/GardenDetailsScreen.swift); dialog keluar dan error save/GPS. Task GPS tetap pada editor.

### Lokasi Ditemukan dari Foto

**File:** [PhotoLocationConfirmationScreen](../PalmOilFarmer/Features/Gardens/Mapping/PhotoLocationConfirmationScreen.swift).

**Asal/status:** Aktif bersyarat sumber photo; pergantian isi [GardenBoundaryScreen](../PalmOilFarmer/Features/Gardens/Mapping/GardenBoundaryScreen.swift).

**Komposisi:** Map/marker dan teks inline; [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift), [SheetGlassBackground](../PalmOilFarmer/Core/DesignSystem/Styles/SheetGlassBackground.swift).

**Data dan output:** Input location; callback onConfirm mengubah state induk; onSearchAgain meminta ulang pencarian dan dismiss induk. Tidak menyimpan data.

**Varian/modal:** Ya, Ini kebun saya → editor; Cari Lagi → tutup mapping dan buka registration.

### Data kebun / Edit kebun

**File:** [GardenDetailsScreen](../PalmOilFarmer/Features/Gardens/Details/GardenDetailsScreen.swift).

**Asal/status:** Aktif; sheet dari [GardenBoundaryScreen](../PalmOilFarmer/Features/Gardens/Mapping/GardenBoundaryScreen.swift) atau [GardenProfileScreen](../PalmOilFarmer/Features/Gardens/Profile/GardenProfileScreen.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), [GardenMapView](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenMapView.swift), [FormSelectionRow](../PalmOilFarmer/Core/DesignSystem/Components/FormSelectionRow.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift); text field dan detailMetric inline.

**Data dan output:** Draf name/year/month/soil serta focus/error lokal. Mode baru menggunakan location.id, edit mempertahankan originalGarden. onSave Bool menentukan sukses; store dimiliki induk.

**Varian/modal:** Sheet [PlantingDatePickerScreen](../PalmOilFarmer/Features/Gardens/Details/PlantingDatePickerScreen.swift), push [SelectionListScreen](../PalmOilFarmer/Core/DesignSystem/Components/SelectionListScreen.swift) tanah, alert validasi/save, tutup/batal. Dipakai lintas area tetapi satu implementasi di Registration.

### Tahun Tanam

**File:** [PlantingDatePickerScreen](../PalmOilFarmer/Features/Gardens/Details/PlantingDatePickerScreen.swift).

**Asal/status:** Aktif; sheet dari [GardenDetailsScreen](../PalmOilFarmer/Features/Gardens/Details/GardenDetailsScreen.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift) dan dua wheel Picker inline.

**Data dan output:** month/year lokal; onConfirm mengirim pilihan ke draf GardenDetails; belum menyimpan kebun.

**Varian/modal:** Batal dismiss tanpa callback; konfirmasi mengirim nilai. Detent besar pada accessibility Dynamic Type.

### Jenis Tanah / Jenis Pupuk

**File:** [SelectionListScreen](../PalmOilFarmer/Core/DesignSystem/Components/SelectionListScreen.swift).

**Asal/status:** Aktif; push dari [GardenDetailsScreen](../PalmOilFarmer/Features/Gardens/Details/GardenDetailsScreen.swift) atau [FertilizerHistoryScreen](../PalmOilFarmer/Features/Gardens/History/FertilizerHistoryScreen.swift).

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift) dan daftar pilihan/checkmark/footer inline di design system.

**Data dan output:** Input strings, pilihan dan onSelect; tidak mengenal [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift)/[SoilType](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift)/[FertilizerDraft](../PalmOilFarmer/Features/Gardens/History/FertilizerDraft.swift). Induk mengubah draf.

**Varian/modal:** Konten generik berdasarkan caller. Tidak membuat salinan halaman domain hanya untuk nama Screen.

### Riwayat Pemupukan

**File:** [FertilizerHistoryScreen](../PalmOilFarmer/Features/Gardens/History/FertilizerHistoryScreen.swift).

**Asal/status:** Aktif; sheet dari profil.

**Komposisi:** NavigationStack, [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), [FertilizerEntryCard](../PalmOilFarmer/Features/Gardens/History/Components/FertilizerEntryCard.swift), tombol tambah dan context menu inline.

**Data dan output:** drafts, selectedDraftID, error lokal. [FertilizerEntryCard](../PalmOilFarmer/Features/Gardens/History/Components/FertilizerEntryCard.swift) memakai binding ke draft. onSave records → profil → [GardenStore](../PalmOilFarmer/Features/Gardens/Shared/GardenStore.swift).update.

**Varian/modal:** Push [SelectionListScreen](../PalmOilFarmer/Core/DesignSystem/Components/SelectionListScreen.swift) pupuk, tambah/hapus draft, validasi dan gagal save tetap di editor. Preview includesEmptyDraft berada di GardenHistoryPreviews.

### Riwayat Panen

**File:** [HarvestHistoryScreen](../PalmOilFarmer/Features/Gardens/History/HarvestHistoryScreen.swift).

**Asal/status:** Aktif; sheet dari profil.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), kartu frekuensi dan berat, Stepper/Picker inline.

**Data dan output:** frequency/weight/error lokal; onSave [HarvestRecord](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift) → profil → store.

**Varian/modal:** Default atau nilai lama, validasi, batal/simpan. UI tidak ditutup bila save gagal.

### Permintaan Peninjauan

**File:** [ReviewRequestScreen](../PalmOilFarmer/Features/Gardens/Review/ReviewRequestScreen.swift).

**Asal/status:** Aktif; root NavigationStack di sheet profil.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), teks penjelasan/persyaratan dan [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift) inline; [ConsentCheckbox](../PalmOilFarmer/Features/Gardens/Review/Components/ConsentCheckbox.swift).

**Data dan output:** hasConsent dan showsConsentError lokal; onContinue memicu state showsReviewForm di profil setelah persetujuan. Tidak mengirim atau menyimpan permintaan.

**Varian/modal:** Push [ReviewContactFormScreen](../PalmOilFarmer/Features/Gardens/Review/ReviewContactFormScreen.swift); dapat menutup sheet.

### Permintaan Peninjauan — data kontak

**File:** [ReviewContactFormScreen](../PalmOilFarmer/Features/Gardens/Review/ReviewContactFormScreen.swift).

**Asal/status:** Aktif; push di sheet review profil.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), contactField inline, [ConsentCheckbox](../PalmOilFarmer/Features/Gardens/Review/Components/ConsentCheckbox.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift).

**Data dan output:** name/phone/address/consent/focus/submitting/error lokal. onSubmit async diteruskan ReviewSubmissionView dari submitReview pada profil, memanggil [ReviewService](../PalmOilFarmer/Features/Gardens/Review/ReviewService.swift) dan saveReview; receivedReview di profil menjaga retry jika persistence gagal.

**Varian/modal:** Validasi, submitting, error; interaksi tutup dinonaktifkan saat submit. Berhasil: profil menutup sheet lalu push status.

### Status Pengajuan

**File:** [ReviewStatusScreen](../PalmOilFarmer/Features/Gardens/Review/ReviewStatusScreen.swift).

**Asal/status:** Aktif; push profil sesudah submit sukses.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), [ReviewTimelineRow](../PalmOilFarmer/Features/Gardens/Review/Components/ReviewTimelineRow.swift), [ReviewDownloadProgressCard](../PalmOilFarmer/Features/Gardens/Review/Components/ReviewDownloadProgressCard.swift), ShareLink, tombol hasil inline.

**Data dan output:** Input status/entries dari [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift).review atau reference. State menunjuk [ReviewReportDownload](../PalmOilFarmer/Features/Gardens/Review/ReviewReportDownload.swift).shared, onRefresh/onViewResults/onAdvanceDemo callback ke profil.

**Varian/modal:** submitted/scheduled/inReview/completed; unduhan progressing/saved/error jika URL tersedia. Simulasi DEBUG dapat maju melalui callback; hasil membuka rekomendasi.

### Hasil peninjauan / informasi kebun

**File:** [FertilizerRecommendationScreen](../PalmOilFarmer/Features/Gardens/Recommendations/FertilizerRecommendationScreen.swift).

**Asal/status:** Aktif; push profil/status. Reference menyediakan laporan contoh yang lebih lengkap.

**Komposisi:** reportPicker dan susunan tab inline. [BoundarySilhouette](../PalmOilFarmer/Features/Gardens/Recommendations/Components/BoundarySilhouette.swift), [NutrientProjectionChart](../PalmOilFarmer/Features/Gardens/Recommendations/Components/NutrientProjectionChart.swift), [FertilizerCostTable](../PalmOilFarmer/Features/Gardens/Recommendations/Components/FertilizerCostTable.swift), [RainfallForecastView](../PalmOilFarmer/Features/Gardens/Recommendations/Components/RainfallForecastView.swift), [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift); fallback tanpa [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift) memakai [AllocationOverviewMap](../PalmOilFarmer/Features/Gardens/Recommendations/Components/AllocationOverviewMap.swift) dan [FertilizerAllocationSection](../PalmOilFarmer/Features/Gardens/Recommendations/Components/FertilizerAllocationSection.swift).

**Data dan output:** report dan optional garden input; selectedTab/selectedAreaID/selectedReference lokal. Tidak menyimpan kebun. Report .local tidak mengarang data hara/biaya/cuaca.

**Varian/modal:** Tab nutrients/allocation/rainfall termasuk state data kosong. Sheet nutrient reference; jika garden nil, picker dan map area laporan. Root memasok garden sehingga alokasi memakai [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift).

### Referensi pupuk untuk unsur hara

**File:** [NutrientReferenceScreen](../PalmOilFarmer/Features/Gardens/Recommendations/NutrientReferenceScreen.swift).

**Asal/status:** Aktif bersyarat laporan punya nutrientReferences; sheet rekomendasi.

**Komposisi:** Teks referensi, daftar pupuk, divider dan catatan inline.

**Data dan output:** Input [NutrientReference](../PalmOilFarmer/Features/Gardens/Recommendations/Models/NutrientReference.swift) saja; tidak menyimpan atau memiliki store.

**Varian/modal:** Detent medium/large; data contoh tersedia di reference preview.

### Area Kebun — area laporan

**File:** [RecommendationAreaPickerScreen](../PalmOilFarmer/Features/Gardens/Recommendations/RecommendationAreaPickerScreen.swift).

**Asal/status:** Reference/preview dari rekomendasi tanpa [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift); sheet.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), pencarian, row/thumbnail inline dengan [GardenMapView](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenMapView.swift) atau gambar reference.

**Data dan output:** areas input, binding selectedAreaID, pendingAreaID dan query lokal. Konfirmasi menerbitkan pilihan, batal tidak.

**Varian/modal:** Daftar/filter kosong; tidak mengubah data tersimpan. Root saat ini memakai [BlockAreaPickerScreen](../PalmOilFarmer/Features/FindingBlock/Views/BlockAreaPickerScreen.swift).

### Navigasi — area laporan

**File:** [RecommendationAreaMapScreen](../PalmOilFarmer/Features/Gardens/Recommendations/RecommendationAreaMapScreen.swift).

**Asal/status:** Reference/preview; full screen dari rekomendasi tanpa [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift).

**Komposisi:** Map polygon/marker/garis, [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), distance/status card inline.

**Data dan output:** Input boundary/areas/selectedArea. Camera dan [WaypointLocationSession](../PalmOilFarmer/Features/FindingWaypoint/Data/WaypointLocationSession.swift) lokal, task berdasarkan scenePhase. Tidak menyimpan geometri.

**Varian/modal:** GPS/no target/akurasi rendah/pengaturan; close dismiss. Sesi tetap milik screen ini.

### Unduh Peta

**File:** [MapDownloadScreen](../PalmOilFarmer/Features/Gardens/MapDownloads/MapDownloadScreen.swift).

**Asal/status:** Reference/preview; CodedUIFrameCatalog. Tidak dibuka [AppFlow](../PalmOilFarmer/App/AppFlow.swift).

**Komposisi:** [MapHeroView](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapHeroView.swift), [LocationMapPreview](../PalmOilFarmer/Features/Gardens/Shared/Components/LocationMapPreview.swift) atau gambar reference, [MapDownloadProgressView](../PalmOilFarmer/Features/Gardens/MapDownloads/Components/MapDownloadProgressView.swift), [PrimaryActionButton](../PalmOilFarmer/Core/DesignSystem/Components/PrimaryActionButton.swift).

**Data dan output:** Input location/state/onMapBoundary; tidak ada downloader baru atau persistence. State unduhan disediakan caller.

**Varian/modal:** downloading/completed/failed; completed memanggil onMapBoundary. Pernyataan UI unduhan adalah reference, bukan bukti implementasi offline map.

### Area Kebun — blok kebun

**File:** [BlockAreaPickerScreen](../PalmOilFarmer/Features/FindingBlock/Views/BlockAreaPickerScreen.swift).

**Asal/status:** Aktif; sheet dari [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift) dalam tab alokasi.

**Komposisi:** [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift), field query, rows/checkmark inline, [BlockAreaThumbnail](../PalmOilFarmer/Features/FindingBlock/Views/Components/BlockAreaThumbnail.swift).

**Data dan output:** blocks input; selectedID binding milik [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift); pendingID/query lokal. Konfirmasi menerbitkan pilihan, batal hanya dismiss.

**Varian/modal:** Filter dan kosong. Tidak menulis [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift) atau laporan.

### Navigasi — blok kebun

**File:** [FindingBlockMapScreen](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockMapScreen.swift).

**Asal/status:** Aktif; full screen dari [FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift).

**Komposisi:** TimelineView/Map, [BlockMapOverlay](../PalmOilFarmer/Features/FindingBlock/Views/Components/BlockMapOverlay.swift), [ScreenHeader](../PalmOilFarmer/Core/DesignSystem/Components/ScreenHeader.swift); distanceCard/marker/accuracy/garis inline.

**Data dan output:** [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift)/zones input, selectedZoneID binding ke komponen alokasi; camera, [BlockLocationSession](../PalmOilFarmer/Features/FindingBlock/Data/BlockLocationSession.swift), hasFramedLocation lokal. Scene phase mengatur task GPS.

**Varian/modal:** GPS belum tersedia/stale/akurasi rendah/izin; Pengaturan membuka sistem, X menutup. Tidak menyimpan zona atau mengubah batas.

### Home / Pemupukan eksperimen

**File:** [FindingWaypointFlow](../PalmOilFarmer/Features/FindingWaypoint/Views/FindingWaypointFlow.swift).

**Asal/status:** Eksperimen; preview terpisah, bukan WindowGroup aplikasi.

**Komposisi:** TabView dua tab, NavigationStack, [GardenListScreen](../PalmOilFarmer/Features/Gardens/List/GardenListScreen.swift) dan [WaypointGardenListScreen](../PalmOilFarmer/Features/FindingWaypoint/Views/WaypointGardenListScreen.swift).

**Data dan output:** Memiliki [GardenStore](../PalmOilFarmer/Features/Gardens/Shared/GardenStore.swift) sendiri untuk eksperimen, state navigasi/registration/mapping. Store memakai penyimpanan kebun yang sama jika flow sengaja dijalankan.

**Varian/modal:** Tab Home memakai profil dan registration Gardens; tab Pemupukan membuka daftar zona. Tidak diaktifkan oleh refactor.

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

**Data dan output:** [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift)/zones input; pilihan zona/camera/guidance dan [WaypointLocationSession](../PalmOilFarmer/Features/FindingWaypoint/Data/WaypointLocationSession.swift) lokal.

**Varian/modal:** Pilih zona 1–6, mulai/hentikan panduan, follow/frame garden, status izin/akurasi. Tidak mengaktifkan tracking latar atau menyimpan hasil.

## Bagian alokasi bukan halaman

[FindingBlockView](../PalmOilFarmer/Features/FindingBlock/Views/FindingBlockView.swift) ditanam dalam [FertilizerRecommendationScreen](../PalmOilFarmer/Features/Gardens/Recommendations/FertilizerRecommendationScreen.swift). Ia menerima [Garden](../PalmOilFarmer/Features/Gardens/Shared/Garden.swift) dan optional report, menghitung blocks dengan [BlockZoning](../PalmOilFarmer/Features/FindingBlock/Models/BlockZoning.swift), serta memiliki selectedBlockID, camera, loading dan state presentasi. Komposisinya Map + [BlockMapOverlay](../PalmOilFarmer/Features/FindingBlock/Views/Components/BlockMapOverlay.swift), tombol pilih area/Buka Map, [FertilizerAllocationSection](../PalmOilFarmer/Features/Gardens/Recommendations/Components/FertilizerAllocationSection.swift) atau teks periode kosong. Task pembagian blok tetap memakai identity boundary.points. Navigasi picker/map adalah tujuan anak, bukan komponen yang terus terlihat di halaman induk.

## Reference, fixture, dan komponen generik

- [CodedUIFrameCatalog](../PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUIFrameCatalog.swift): [CodedUIFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUIFrameCatalog.swift) memilih frame daftar/unduhan/profil/review/rekomendasi dan mock foto; bukan router produksi.
- [CodedUI2FlowPreviews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUI2FlowPreviews.swift): komposisi varian mapping, registration, profil dan rekomendasi.
- [NamaTest2Previews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift): [RegistrationFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift), [SearchFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift), [PhotoPickerFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift), [BoundaryFramePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/NamaTest2Previews.swift); peta dan control state reference, bukan screen tambahan dari root.
- [GlassSheetFlowPreviews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/GlassSheetFlowPreviews.swift): sheet registration di atas daftar.
- [GardenHistoryPreviews](../PalmOilFarmer/PreviewSupport/ReferenceScreens/GardenHistoryPreviews.swift): editor dan kartu riwayat.
- [AppleSignInReferencePreview](../PalmOilFarmer/PreviewSupport/ReferenceScreens/AppleSignInReferencePreview.swift): reference masuk dengan Apple, tidak terhubung ke app.
- [Fixtures](../PalmOilFarmer/PreviewSupport/Fixtures): [GardenPreviewData](../PalmOilFarmer/PreviewSupport/Fixtures/GardenPreviewData.swift), [RecommendationPreviewData](../PalmOilFarmer/PreviewSupport/Fixtures/RecommendationPreviewData.swift), [WaypointPreviewData](../PalmOilFarmer/PreviewSupport/Fixtures/WaypointPreviewData.swift); data contoh DEBUG, bukan sumber produksi.
- [DesignSystemCatalog](../PalmOilFarmer/Core/DesignSystem/Catalog/DesignSystemCatalog.swift): katalog UI generik light/dark/Dynamic Type; bukan halaman aplikasi.

Contoh penelusuran: cari **Kebun** → [GardenListScreen](../PalmOilFarmer/Features/Gardens/List/GardenListScreen.swift) → [GardenCard](../PalmOilFarmer/Features/Gardens/List/Components/GardenCard.swift) di List/Components → [GardenMapView](../PalmOilFarmer/Features/Gardens/Shared/Components/GardenMapView.swift) di Shared/Components. Untuk klik kartu, kembali ke callback onSelectGarden → [AppFlow](../PalmOilFarmer/App/AppFlow.swift) → [GardenProfileScreen](../PalmOilFarmer/Features/Gardens/Profile/GardenProfileScreen.swift); profil bukan anak komposisi [GardenCard](../PalmOilFarmer/Features/Gardens/List/Components/GardenCard.swift).
