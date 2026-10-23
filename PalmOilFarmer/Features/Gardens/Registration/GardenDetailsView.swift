import SwiftUI

struct GardenDetailsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let locationName: String
    private let originalGarden: Garden?
    let boundary: GardenBoundary
    let onSave: (Garden) -> Bool
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isNameFocused: Bool
    @State private var plantingYear: Int?
    @State private var plantingMonth = 10
    @State private var showsPlantingDate = false
    @State private var showsSoilTypes = false
    @State private var soilType: SoilType?
    @State private var showsSaveError = false
    @State private var errorMessage = ""

    init(
        location: GardenLocation,
        boundary: GardenBoundary,
        onSave: @escaping (Garden) -> Bool,
        referenceMapImage: String? = nil,
        metrics: GardenDisplayMetrics? = nil
    ) {
        locationName = location.name
        originalGarden = nil
        self.boundary = boundary
        self.onSave = onSave
        self.referenceMapImage = referenceMapImage
        self.metrics = metrics
    }

    init(
        editing garden: Garden,
        referenceMapImage: String? = nil,
        metrics: GardenDisplayMetrics? = nil,
        onSave: @escaping (Garden) -> Bool
    ) {
        locationName = garden.locationName
        originalGarden = garden
        boundary = garden.boundary
        self.onSave = onSave
        self.referenceMapImage = referenceMapImage
        self.metrics = metrics
        _name = State(initialValue: garden.name)
        _plantingYear = State(initialValue: garden.plantingYear)
        // Older or externally edited files may contain a month outside the picker range.
        let storedMonth = garden.plantingMonth ?? 10
        _plantingMonth = State(initialValue: (1...12).contains(storedMonth) ? storedMonth : 10)
        _soilType = State(initialValue: garden.soilType)
    }

    private var displayMetrics: GardenDisplayMetrics {
        metrics ?? GardenDisplayMetrics(boundary: boundary)
    }

    var body: some View {
        let displayMetrics = displayMetrics
        let metricsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7))
            : AnyLayout(HStackLayout(spacing: 7))
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: originalGarden == nil ? "Data kebun" : "Edit kebun", onClose: {
                    isNameFocused = false
                    dismiss()
                })
                .simultaneousGesture(TapGesture().onEnded {
                    isNameFocused = false
                })
                ScrollView {
                    VStack(spacing: 0) {
                        GardenMapView(boundary: boundary, referenceImage: referenceMapImage, showsAnnotations: true)
                            .frame(height: 201)
                            .simultaneousGesture(TapGesture().onEnded {
                                isNameFocused = false
                            })
    
                        TextField("Nama Kebun", text: $name)
                            .font(.title)
                            .textInputAutocapitalization(.words)
                            .focused($isNameFocused)
                            .submitLabel(.done)
                            .onSubmit { isNameFocused = false }
                            .accessibilityIdentifier("gardenName")
                            .padding(16)
                            .frame(minHeight: 66)
    
                        metricsLayout {
                            detailMetric("Luas tanah", value: displayMetrics.area)
                            detailMetric("Perimeter", value: displayMetrics.perimeter)
                        }
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture { isNameFocused = false }
    
                        VStack(spacing: 16) {
                            FormSelectionRow(title: "Tahun Tanam", placeholder: "Pilih tahun tanam",
                                             value: plantingYear.map { "\(PlantingDatePickerView.monthNames[plantingMonth - 1]) \($0)" },
                                             systemImage: "calendar", trailingImage: "chevron.up.chevron.down") {
                                isNameFocused = false
                                showsPlantingDate = true
                            }
                            Divider()
                            FormSelectionRow(title: "Jenis Tanah", placeholder: "Pilih jenis tanah",
                                             value: soilType?.displayName, systemImage: "leaf.fill") {
                                isNameFocused = false
                                showsSoilTypes = true
                            }
                        }
                        .padding(16)
                        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, 8)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isNameFocused = false }
                }
                PrimaryActionButton(title: "Simpan", action: save)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 2)
            }
            .containerBackground(.clear, for: .navigation)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showsSoilTypes) {
                SelectionListView(
                    title: "Jenis Tanah", options: SoilType.allCases.map(\.displayName),
                    selected: soilType?.displayName,
                    footer: "Jenis tanah membantu kami memahami kondisi kebun Anda. Pilih yang paling mendekati."
                ) { selected in
                    soilType = SoilType.allCases.first { $0.displayName == selected }
                }
            }
            .sheet(isPresented: $showsPlantingDate) {
                PlantingDatePickerView(month: plantingMonth, year: plantingYear ?? 2016) { month, year in
                    plantingMonth = month
                    plantingYear = year
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(!name.isEmpty)
        .alert("Kebun belum tersimpan", isPresented: $showsSaveError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func detailMetric(_ title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.footnote)
            Text(value).font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 72)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.metric))
    }

    private func save() {
        isNameFocused = false
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let plantingYear, let soilType else {
            errorMessage = "Lengkapi nama kebun, tahun tanam, dan jenis tanah terlebih dahulu."
            showsSaveError = true
            return
        }
        errorMessage = "Data tidak dapat disimpan di perangkat. Coba lagi."
        var garden = Garden(
            id: originalGarden?.id ?? UUID(), name: trimmedName,
            locationName: locationName, boundary: boundary,
            plantingYear: plantingYear, soilType: soilType
        )
        garden.plantingMonth = plantingMonth
        garden.fertilizerRecords = originalGarden?.fertilizerRecords
        garden.harvestRecord = originalGarden?.harvestRecord
        garden.review = originalGarden?.review
        showsSaveError = !onSave(garden)
        if !showsSaveError && originalGarden != nil {
            dismiss()
        }
    }
}

#if DEBUG
#Preview("12 Copy 3 · Data Kebun") {
    GardenDetailsView(location: GardenPreviewData.location, boundary: GardenPreviewData.boundary,
                      onSave: { _ in true }, referenceMapImage: "GardenBoundaryMap",
                      metrics: GardenPreviewData.metrics)
}
#endif
