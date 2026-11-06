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
        let metricsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7))
            : AnyLayout(HStackLayout(spacing: 7))
        VStack(spacing: 0) {
            RegistrationHeader(title: model.isEditing ? "Edit kebun" : "Data kebun") {
                isNameFocused = false
                coordinator.close()
            }
            ScrollView {
                VStack(spacing: 0) {
                    GardenMapView(boundary: boundary, referenceImage: referenceMapImage, showsAnnotations: true)
                        .frame(height: RegistrationStyle.mapHeight)
                        .simultaneousGesture(TapGesture().onEnded { isNameFocused = false })
                    metricsLayout {
                        detailMetric("Luas tanah", value: displayMetrics.area)
                        detailMetric("Perimeter", value: displayMetrics.perimeter)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    VStack(spacing: 0) {
                        RegistrationFormField(title: "Nama Kebun") {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
                                TextField("cth: Pinggir jalan, Hilir sungai", text: $model.name)
                                    .textInputAutocapitalization(.words)
                                    .focused($isNameFocused)
                                    .submitLabel(.done)
                                    .onSubmit { isNameFocused = false }
                                    .accessibilityLabel("Nama Kebun")
                                    .accessibilityIdentifier("gardenName")
                            }
                        }
                        Divider()
                        RegistrationFormField(title: "Tahun Tanam") {
                            Button {
                                isNameFocused = false
                                coordinator.openPlantingDate()
                            } label: {
                                selectionLabel(
                                    model.plantingYear.map { "\(PlantingDatePickerView.monthNames[model.plantingMonth - 1]) \($0)" },
                                    placeholder: "Pilih tahun tanam", symbol: "calendar", trailing: "chevron.right"
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Tahun Tanam")
                            .accessibilityValue(model.plantingYear.map(String.init) ?? "Belum dipilih")
                        }
                        Divider()
                        RegistrationFormField(title: "Jenis Tanah") {
                            Menu {
                                Picker("Jenis Tanah", selection: $model.soilType) {
                                    Text("Belum dipilih").tag(Optional<SoilType>.none)
                                    ForEach(SoilType.allCases) { soil in
                                        Text(soil.displayName).tag(Optional(soil))
                                    }
                                }
                            } label: {
                                selectionLabel(model.soilType?.displayName,
                                               placeholder: "Pilih jenis tanah", symbol: "sprinkler",
                                               trailing: "chevron.up.chevron.down")
                            }
                            .tint(.primary)
                            .onChange(of: model.soilType) { isNameFocused = false }
                            .accessibilityLabel("Jenis Tanah")
                            .accessibilityValue(model.soilType?.displayName ?? "Belum dipilih")
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
                    .padding(.horizontal, 16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .bottomActionBar {
                RegistrationPrimaryButton(title: "Simpan", action: save)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 2)
            }
        }
        .background(RegistrationStyle.background)
        .sheet(isPresented: $coordinator.showsPlantingDate) {
            PlantingDatePickerView(month: model.plantingMonth, year: model.plantingYear ?? Calendar.current.component(.year, from: .now)) { month, year in
                model.plantingMonth = month
                model.plantingYear = year
            }
        }
        .presentationBackground(RegistrationStyle.background)
        .presentationDragIndicator(.hidden)
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

    private func selectionLabel(_ value: String?, placeholder: String, symbol: String, trailing: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(value ?? placeholder)
                .foregroundStyle(value == nil ? Color(uiColor: .placeholderText) : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: trailing).font(.footnote).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func detailMetric(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.footnote)
            Text(value).font(.headline)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func save() {
        isNameFocused = false
        _ = flow.viewModel.save()
    }
}

struct RegistrationFormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.body.weight(.semibold)).foregroundStyle(.secondary)
            content()
                .font(.title3)
                .frame(minHeight: 52)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("COdedUI5 · Data Kebun") {
    GardenDetailsView(location: GardenPreviewData.location, boundary: GardenPreviewData.boundary,
                      onSave: { _ in true }, referenceMapImage: "GardenBoundaryMap",
                      metrics: GardenPreviewData.metrics)
}
#endif
