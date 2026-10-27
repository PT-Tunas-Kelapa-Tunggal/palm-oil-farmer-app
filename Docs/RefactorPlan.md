# Rencana refactor SwiftUI — 27 Oktober 2026

Status: inventaris historis sebelum refactor. Pengguna menyetujui baseline dan penyelesaian pada 27 Oktober 2026; baseline tersimpan di `df36f86`. Peta source final ada di [Architecture](Architecture.md) dan [ScreenMap](ScreenMap.md).

## Baseline yang diusulkan

Branch saat diperiksa: `main`, HEAD `c5264f265cb2778cf4a87d267d475b13b10a853d`, upstream `origin/main`.
Remote: `https://github.com/hatamisg/palm-oil.git`. Tidak ada perubahan staged.
Usulan: buat branch `codex/refactor-swiftui-structure`, simpan 47 file (46 file aplikasi/dokumen fitur dan satu panduan) di bawah sebagai commit baseline terpisah setelah persetujuan pengguna, lalu commit refactor per perubahan logis. Dokumen rencana ini dicatat terpisah dari daftar pekerjaan lama. Push belum diminta.

```text
 M PalmOilFarmer/App/ContentView.swift
 M PalmOilFarmer/App/PalmOilFarmerApp.swift
 M PalmOilFarmer/DesignSystem/Components/ScreenHeader.swift
 M PalmOilFarmer/Features/Gardens/Components/GardenMapView.swift
 M PalmOilFarmer/Features/Gardens/Data/GardenStore.swift
 M PalmOilFarmer/Features/Gardens/Data/LocationSearchService.swift
 M PalmOilFarmer/Features/Gardens/List/GardenCard.swift
 M PalmOilFarmer/Features/Gardens/List/GardenListView.swift
 M PalmOilFarmer/Features/Gardens/Mapping/BoundaryEditorLayout.swift
 M PalmOilFarmer/Features/Gardens/Mapping/GardenBoundaryView.swift
 M PalmOilFarmer/Features/Gardens/Models/Garden.swift
 M PalmOilFarmer/Features/Gardens/Models/GardenLocation.swift
 M PalmOilFarmer/Features/Gardens/Profile/GardenProfileView.swift
 M PalmOilFarmer/Features/Gardens/Recommendations/FertilizerRecommendationReport.swift
 M PalmOilFarmer/Features/Gardens/Recommendations/FertilizerRecommendationView.swift
 M PalmOilFarmer/Features/Gardens/Registration/GardenDetailsView.swift
 M PalmOilFarmer/Features/Gardens/Registration/GardenPhotoPickerView.swift
 M PalmOilFarmer/Features/Gardens/Registration/LocationMapPreview.swift
 M PalmOilFarmer/Features/Gardens/Registration/LocationSearchView.swift
 M PalmOilFarmer/Features/Gardens/Registration/RegistrationIntroView.swift
 M PalmOilFarmer/Features/Gardens/Review/ReviewContactDetails.swift
 M PalmOilFarmer/Features/Gardens/Review/ReviewContactFormView.swift
 M PalmOilFarmer/Features/Gardens/Review/ReviewRequestView.swift
 M PalmOilFarmer/Features/Gardens/Review/ReviewStatusView.swift
 M PalmOilFarmer/PreviewSupport/Fixtures/RecommendationPreviewData.swift
 M PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUIFrameCatalog.swift
?? PANDUAN-REFACTOR-STRUKTUR-SWIFTUI.md
?? PalmOilFarmer/Features/FindingBlock/BlockAllocation.swift
?? PalmOilFarmer/Features/FindingBlock/BlockLocationSession.swift
?? PalmOilFarmer/Features/FindingBlock/BlockMapOverlay.swift
?? PalmOilFarmer/Features/FindingBlock/BlockThumbnail.swift
?? PalmOilFarmer/Features/FindingBlock/BlockZoning.swift
?? PalmOilFarmer/Features/FindingBlock/FindingBlockImplementation.md
?? PalmOilFarmer/Features/FindingBlock/FindingBlockMapView.swift
?? PalmOilFarmer/Features/FindingBlock/FindingBlockView.swift
?? PalmOilFarmer/Features/FindingBlock/GardenLocalReport.swift
?? PalmOilFarmer/Features/Gardens/CodedUI2Implementation.md
?? PalmOilFarmer/Features/Gardens/Data/MappingDraftStore.swift
?? PalmOilFarmer/Features/Gardens/Recommendations/AllocationOverviewMap.swift
?? PalmOilFarmer/Features/Gardens/Recommendations/RecommendationAreaMapView.swift
?? PalmOilFarmer/Features/Gardens/Recommendations/RecommendationDetails.swift
?? PalmOilFarmer/Features/Gardens/Registration/PhotoLocationConfirmationView.swift
?? PalmOilFarmer/Features/Gardens/Review/ReviewReportDownload.swift
?? PalmOilFarmer/Features/Gardens/Review/ReviewService.swift
?? PalmOilFarmer/PreviewSupport/ReferenceScreens/CodedUI2FlowPreviews.swift
?? PalmOilFarmerTests/CodedUI2FlowTests.swift
?? PalmOilFarmerTests/FindingBlockTests.swift
```

## Inventaris dan rencana perpindahan

Scope: seluruh aplikasi, mulai Gardens/List, diikuti area Gardens lain, FindingBlock, FindingWaypoint, design system, resources, dan dokumentasi.

| Asal / simbol | Tujuan | Alasan / pemanggil terdampak |
| --- | --- | --- |
| Gardens/List/GardenListView.swift | Gardens/Views/List/GardenListScreen.swift | Halaman utama; ContentView, FindingWaypointView, CodedUIFrameCatalog, GlassSheetFlowPreviews, NamaTest2Previews, preview lokal |
| Gardens/List/GardenCard.swift | Gardens/Views/List/Components/GardenCard.swift | Komponen lokal daftar |
| Kartu draf inline di GardenListView | Gardens/Views/List/Components/MappingDraftCard.swift | Perjelas komposisi tanpa memindahkan callback atau kepemilikan store |
| Gardens/Registration/LocationMapPreview.swift | Gardens/Views/Components/LocationMapPreview.swift | Dipakai daftar dan unduhan di samping registration |
| Mapping/MapDownloadView.swift: MapDownloadItem + MapDownloadState | Gardens/Models/MapDownloadItem.swift | Data unduhan terpisah dari UI; List dan reference previews |
| Mapping/MapDownloadView.swift: MapDownloadProgressView + MapDownloadCard | Gardens/Views/Components/ (file per komponen) | Dipakai halaman unduhan dan daftar |
| Mapping/MapDownloadView.swift: MapDownloadView | Gardens/Views/Mapping/MapDownloadScreen.swift | Halaman reference; perbarui CodedUIFrameCatalog dan preview lokal |
| Gardens/Profile, Registration, Mapping, History, Review, Recommendations | Gardens/Views/area terkait | Pisahkan screen, flow, komponen sesuai tujuan presentasi aktual; perbarui semua pemanggil termasuk preview dan eksperimen |
| History/FertilizerDraft, Recommendations/FertilizerRecommendationReport, Review/ReviewContactDetails | Gardens/Models/ | Nilai domain, bukan UI |
| Review/ReviewStatusView, Review/ReviewService, Recommendations/RecommendationDetails, Data/MappingDraftStore | Models, Data, Views berdasarkan tipe | File campuran; pisahkan model dari UI/layanan tanpa mengubah kontrak |
| Review/ReviewReportDownload, Review/ReviewService | Gardens/Data/ | Operasi laporan dan layanan |
| FindingBlock/*.swift | FindingBlock/Models, Data, Views | FindingBlockView adalah bagian rekomendasi; map menjadi tujuan full screen |
| FindingWaypoint/*.swift | FindingWaypoint/Models, Data, Views | Pertahankan sebagai eksperimen; tidak menjadi root app |
| DesignSystem/ | Core/DesignSystem/ | UI generik; hilangkan dependensi SeedlingIcon hanya pada preview generik |
| Assets.xcassets/ | Resources/Assets.xcassets/ | Pindahkan satu kesatuan tanpa rename aset |
| README dan dokumen fitur | README, Docs/Architecture.md, Docs/ScreenMap.md | Peta komposisi dan navigasi terpisah, link menuju path final; dokumentasi tidak menjadi resource app |

## Fakta yang sudah diperiksa

- Root aktual: PalmOilFarmerApp → ContentView → GardenListView.
- ContentView memiliki GardenStore dan MappingDraftStore, push profil, sheet registration, full screen pemetaan; callback store menangani penyimpanan.
- Daftar memiliki cabang kosong, draf, kebun, unduhan opsional. Root tidak memasok unduhan.
- GardenDetails dipakai untuk pendaftaran dan edit profil. Profile memiliki sheet editor, riwayat, review, serta tujuan hasil/status.
- FindingBlock ditanam dalam rekomendasi dan membuka picker/peta. FindingWaypoint merupakan root eksperimen terpisah.
- Proyek memakai filesystem synchronized groups, satu app target dan satu test target, generated Info.plist, deployment iOS 27.0.
- Tidak ditemukan AGENTS.md pada repo atau direktori induk yang diperiksa.

## Verifikasi yang direncanakan

Build/test baseline setelah disepakati; Debug dan Release final; referensi rename, membership, aset dan link dokumen; test persistence, CodedUI2FlowTests, FindingBlockTests sesuai kontrak terdampak. Pemeriksaan visual/interaksi dilakukan jika simulator tersedia, dan keterbatasan dicatat tanpa mengubah deployment/signing.

Toolchain default menunjuk Command Line Tools; Xcode.app ditemukan di /Applications. Gunakan DEVELOPER_DIR hanya untuk perintah verifikasi agar konfigurasi global tetap sama. Belum ada build/test sukses yang diklaim.
