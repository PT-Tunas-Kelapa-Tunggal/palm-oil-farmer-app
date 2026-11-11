#if DEBUG
import SwiftUI

/// Each preview corresponds to one canvas-level frame in Sketch's Coded_UI page.
/// Reference-only service and system states never mutate the app's saved data.
struct CodedUIFramePreview: View {
    let index: Int

    private var download: MapDownloadItem {
        MapDownloadItem(id: UUID(), location: GardenPreviewData.location,
                        state: .referenceProgress, referenceMapImage: "CodedRegionCard")
    }

    var body: some View {
        Group {
            switch index {
            case 0:
                DashboardStaticView(onRegisterGarden: {})
            case 1:
                DashboardStaticView(gardens: [DashboardPreviewData.garden], downloads: [download],
                               referenceMapImage: "GardenCardMap",
                               previewMetrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"),
                               onRegisterGarden: {})
            case 2:
                DashboardStaticView(downloads: [download], onRegisterGarden: {})
            case 3:
                profile(garden: GardenPreviewData.garden, layout: .overview)
            case 4:
                profile(garden: GardenPreviewData.garden)
            case 5, 6:
                MapDownloadView(location: GardenPreviewData.location,
                                state: index == 5 ? .referenceProgress : .completed,
                                onMapBoundary: {}, referenceMapImage: "CodedRegionHero")
            case 7:
                GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(), onClose: {})
            case 8:
                profile(garden: GardenPreviewData.fertilizedGarden)
                    .sheet(isPresented: .constant(true)) {
                        GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(), onClose: {})
                    }
            case 9:
                SelectionListView(title: "Jenis Pupuk", options: FertilizerCatalogue.names, selected: "Urea",
                                  footer: "Pilih sesuai nama pupuk yang tertera pada karung. Jika tidak ada dalam daftar, pilih Lainnya.",
                                  onSelect: { _ in })
            case 10:
                ReviewRequestView(onSubmit: { _ in })
            case 11:
                ReviewContactFormView(onSubmit: { _ in throw ReviewServiceError.unavailable })
            case 12, 13:
                AppleSignInReferencePreview(isLoading: index == 13)
            case 14:
                profile(garden: GardenPreviewData.fertilizedGarden)
            case 15, 16, 17, 18:
                let status: ReviewStatus = index == 15 ? .scheduled : (index == 16 ? .inReview : (index == 17 ? .completed : .submitted))
                ReviewStatusView(gardenName: "Belakang Rumah", status: status,
                                 entries: ReviewTimelineEntry.referenceEntries(for: status), onViewResults: {})
            case 19:
                profile(garden: GardenPreviewData.completedGarden)
            case 20:
                profile(garden: GardenPreviewData.completedGarden, reviewStatus: .submitted)
            case 21:
                profile(garden: GardenPreviewData.completedGarden, reviewStatus: .completed)
            case 22, 23:
                FertilizerRecommendationView(report: RecommendationPreviewData.report,
                                            initialTab: index == 22 ? .nutrients : .allocation)
            case 24:
                profile(garden: GardenPreviewData.fertilizedGarden, layout: .chart)
            case 25:
                RegistrationFramePreview(step: .guide)
            case 26:
                RegistrationFramePreview(step: .photo)
            case 29:
                RegistrationFramePreview(step: .address)
            case 30:
                SearchFramePreview()
            case 31:
                SearchFramePreview(query: "Dumai")
            case 32:
                RegistrationFramePreview(step: .address, selectedLocation: GardenPreviewData.location)
            case 33:
                BoundaryFramePreview(state: .region)
            case 34:
                BoundaryFramePreview(state: .empty)
            case 35:
                BoundaryFramePreview(state: .partial)
            case 36:
                BoundaryFramePreview(state: .complete)
            case 37:
                details
            case 38:
                details.sheet(isPresented: .constant(true)) {
                    PlantingDatePickerView(onConfirm: { _, _ in })
                }
            case 39:
                SelectionListView(title: "Jenis Tanah", options: SoilType.allCases.map(\.displayName),
                                  selected: "Tanah Mineral",
                                  footer: "Jenis tanah membantu kami memahami kondisi kebun Anda. Pilih yang paling mendekati.",
                                  onSelect: { _ in })
            case 40:
                CodedPhotoGridReference()
            default:
                ScreenHeader(title: "Detail Kebun", systemImage: "chevron.left", onClose: {})
            }
        }
        .background {
            if [7, 10, 11].contains(index) {
                SheetGlassBackground()
            }
        }
        .environment(\.locale, Locale(identifier: "id_ID"))
        .id(index)
    }

    private var details: some View {
        GardenDetailsView(location: GardenPreviewData.location, boundary: GardenPreviewData.boundary,
                          onSave: { _ in true }, referenceMapImage: "GardenBoundaryMap", metrics: GardenPreviewData.metrics)
            .background { SheetGlassBackground() }
    }

    private func profile(garden: Garden, layout: GardenProfileReferenceLayout = .standard,
                         reviewStatus: ReviewStatus? = nil) -> some View {
        GardenProfileReferenceView(
            garden: garden, referenceMapImage: layout == .standard ? "CodedProfileMap" : "GardenProfileMap",
            metrics: GardenPreviewData.metrics, showsHeader: layout == .standard, layout: layout,
            chartValues: [1, 3, 1.5, 0.5], reviewStatus: reviewStatus
        )
    }
}

/// The Sketch gallery frame uses placeholders; production uses the native Photos picker.
struct CodedPhotoGridReference: View {
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Album Kamera", onClose: {})
            GeometryReader { geometry in
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
                    ForEach(0..<36) { _ in
                        Image(systemName: "photo.fill")
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.width / 4 - 2)
                            .background(Color(white: 0.95))
                    }
                }
            }
            .clipped()
        }
        .background { SheetGlassBackground() }
    }
}

#Preview("01 · Daftar Kebun / Kebun / Empty", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 0)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("02 · Profil Kebun / Kebun / Filled", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 1)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("03 · Daftar Kebun / Kebun / Map Downloading", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 2)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("04 · Daftar Kebun / 01 Kebun - Kosong Copy 2", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 3)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("05 · Profil Kebun / Detail Kebun / Missing Fertilizer History", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 4)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("06 · Daftar Kebun / Unduh Peta / Downloading", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 5)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("07 · Daftar Kebun / Unduh Peta / Completed", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 6)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("08 · Profil Kebun / Formulir Riwayat Pupuk / Filled", traits: .fixedLayout(width: 402, height: 980)) {
    CodedUIFramePreview(index: 7)
        .padding(.top, 62)
        .padding(.bottom, 34)
}

#Preview("09 · Profil Kebun / Detail Kebun / Missing Harvest History", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 8)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("10 · Profil Kebun / Pilih Jenis Pupuk / Selected", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 9)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("11 · Ajukan Peninjauan / Informasi Peninjauan / Logged Out", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 10)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("12 · Ajukan Peninjauan / Formulir Peninjauan / Empty", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 11)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("13 · Ajukan Peninjauan / Masuk Apple ID / Default", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 12)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("14 · Ajukan Peninjauan / Masuk Apple ID / Loading", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 13)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("15 · Profil Kebun / Detail Kebun / Missing Harvest History", traits: .fixedLayout(width: 402, height: 1315)) {
    CodedUIFramePreview(index: 14)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("16 · Ajukan Peninjauan / Status Pengajuan / Scheduled", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 15)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("17 · Ajukan Peninjauan / Status Pengajuan / In Review", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 16)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("18 · Ajukan Peninjauan / Status Pengajuan / Completed", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 17)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("19 · Ajukan Peninjauan / Status Pengajuan / Submitted", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 18)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("20 · Profil Kebun / Detail Kebun / Complete", traits: .fixedLayout(width: 402, height: 1160)) {
    CodedUIFramePreview(index: 19)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("21 · Profil Kebun / Detail Kebun / Complete", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 20)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("22 · Profil Kebun / Detail Kebun / Complete Copy 3", traits: .fixedLayout(width: 402, height: 877)) {
    CodedUIFramePreview(index: 21)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("23 · Rekomendasi Pupuk / Detail Kebun / Nutrient Projection", traits: .fixedLayout(width: 402, height: 968)) {
    CodedUIFramePreview(index: 22)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("24 · Rekomendasi Pupuk / Detail Kebun / Fertilizer Allocation", traits: .fixedLayout(width: 402, height: 1034)) {
    CodedUIFramePreview(index: 23)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("25 · Daftar Kebun / 01 Kebun - Kosong Copy 6", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 24)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("26 · Daftar Kebun / Panduan Petakan Batas / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 25)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("27 · Daftar Kebun / Lokasi dari Foto / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 26)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("30 · Daftar Kebun / Masukkan Kabupaten / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 29)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("31 · Daftar Kebun / Cari Kabupaten / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 30)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("32 · Daftar Kebun / Cari Kabupaten / Filled", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 31)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("33 · Daftar Kebun / Masukkan Kabupaten / Selected", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 32)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("34 · Daftar Kebun / Buat Batas Kebun / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 33)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("35 · Daftar Kebun / Buat Batas Kebun / Current Location", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 34)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("36 · Daftar Kebun / Buat Batas Kebun / Drawing", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 35)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("37 · Daftar Kebun / Buat Batas Kebun / Closed", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 36)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("38 · Daftar Kebun / Data Kebun / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 37)
        .padding(.top, 62)
        .padding(.bottom, 34)
}

#Preview("39 · Daftar Kebun / Pilih Tahun Tanam / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 38)
        .padding(.top, 62)
        .padding(.bottom, 34)
}

#Preview("40 · Daftar Kebun / Pilih Jenis Tanah / Selected", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 39)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("41 · Daftar Kebun / Pilih Foto Galeri / Default", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUIFramePreview(index: 40)
        .safeAreaPadding(.top, 62)
        .safeAreaPadding(.bottom, 34)
}

#Preview("42 · Stack", traits: .fixedLayout(width: 402, height: 72)) {
    CodedUIFramePreview(index: 41)
        .safeAreaPadding(.top, 0)
        .safeAreaPadding(.bottom, 0)
}
#endif
