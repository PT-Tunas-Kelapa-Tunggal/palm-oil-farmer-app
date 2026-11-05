import SwiftUI

struct GardenDetailsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var flow: GardenDetailsFlow
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    private var boundary: GardenBoundary { flow.viewModel.boundary }
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    init(flow: GardenDetailsFlow, referenceMapImage: String? = nil, metrics: GardenDisplayMetrics? = nil) {
        _flow = State(initialValue: flow)
        self.referenceMapImage = referenceMapImage
        self.metrics = metrics
    }

    private var displayMetrics: GardenDisplayMetrics {
        metrics ?? GardenDisplayMetrics(boundary: boundary)
    }

    var body: some View {
        @Bindable var model = flow.viewModel
        @Bindable var coordinator = flow.coordinator
        let displayMetrics = displayMetrics
        let metricsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7))
            : AnyLayout(HStackLayout(spacing: 7))
        NavigationStack(path: $coordinator.path) {
            VStack(spacing: 0) {
                ScreenHeader(title: !model.isEditing ? "Data kebun" : "Edit kebun", onClose: {
                    isNameFocused = false
                    coordinator.close()
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
    
                        TextField("Nama Kebun", text: $model.name)
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
                                             value: model.plantingYear.map { "\(PlantingDatePickerView.monthNames[model.plantingMonth - 1]) \($0)" },
                                             systemImage: "calendar", trailingImage: "chevron.up.chevron.down") {
                                isNameFocused = false
                                coordinator.openPlantingDate()
                            }
                            Divider()
                            FormSelectionRow(title: "Jenis Tanah", placeholder: "Pilih jenis tanah",
                                             value: model.soilType?.displayName, systemImage: "leaf.fill") {
                                isNameFocused = false
                                coordinator.openSoilTypes()
                            }
                        }
                        .padding(16)
                        .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
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
                .bottomActionBar {
                    PrimaryActionButton(title: "Simpan", action: save)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 2)
                }
            }
            .containerBackground(.clear, for: .navigation)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GardenDetailsRoute.self) { _ in
                SelectionListView(
                    title: "Jenis Tanah", options: SoilType.allCases.map(\.displayName),
                    selected: model.soilType?.displayName,
                    footer: "Jenis tanah membantu kami memahami kondisi kebun Anda. Pilih yang paling mendekati."
                ) { selected in
                    model.soilType = SoilType.allCases.first { $0.displayName == selected }
                }
            }
            .sheet(isPresented: $coordinator.showsPlantingDate) {
                PlantingDatePickerView(month: model.plantingMonth, year: model.plantingYear ?? 2016) { month, year in
                    model.plantingMonth = month
                    model.plantingYear = year
                }
            }
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(!model.name.isEmpty)
        .alert("Kebun belum tersimpan", isPresented: $model.showsSaveError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text(model.errorMessage)
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
        .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.metric))
    }

    private func save() {
        isNameFocused = false
        _ = flow.viewModel.save()
    }
}

#if DEBUG
#Preview("12 Copy 3 · Data Kebun") {
    GardenDetailsView(location: GardenPreviewData.location, boundary: GardenPreviewData.boundary,
                      onSave: { _ in true }, referenceMapImage: "GardenBoundaryMap",
                      metrics: GardenPreviewData.metrics)
}
#endif
