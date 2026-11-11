import SwiftUI

/// "Data Kebun" / "Edit Kebun" sheet.
struct GardenDetailsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: GardenDetailsViewModel
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    private var boundary: GardenBoundary { viewModel.boundary }
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    init(viewModel: GardenDetailsViewModel, referenceMapImage: String? = nil, metrics: GardenDisplayMetrics? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.referenceMapImage = referenceMapImage
        self.metrics = metrics
    }

    private var displayMetrics: GardenDisplayMetrics {
        metrics ?? GardenDisplayMetrics(boundary: boundary)
    }

    var body: some View {
        DynamicSheet(animation: .bouncy, size: .large) {
            sheetContent
        }
        .presentationBackgroundInteraction(.disabled)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    @ViewBuilder
    private var sheetContent: some View {
        @Bindable var viewModel = viewModel
        let metricsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7))
            : AnyLayout(HStackLayout(spacing: 7))
        VStack(spacing: 0) {
            RegistrationHeader(title: viewModel.isEditing ? "Edit Kebun" : "Data Kebun") {
                isNameFocused = false
                viewModel.close()
            }
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 176)
                            .overlay {
                                GardenMapView(boundary: boundary, referenceImage: referenceMapImage, showsAnnotations: true)
                            }
                            .clipped()
                            .simultaneousGesture(TapGesture().onEnded { isNameFocused = false })
                        metricsLayout {
                            detailMetric("Luas", value: displayMetrics.area)
                            Divider().frame(height: 36)
                            detailMetric("Keliling", value: displayMetrics.perimeter)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(RegistrationStyle.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    VStack(spacing: 0) {
                        RegistrationFormField(title: "Nama Kebun") {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
                                TextField("cth: Pinggir jalan, Hilir sungai", text: $viewModel.name)
                                    .textInputAutocapitalization(.words)
                                    .focused($isNameFocused)
                                    .submitLabel(.done)
                                    .onSubmit { isNameFocused = false }
                                    .accessibilityLabel("Nama Kebun")
                                    .accessibilityIdentifier("gardenName")
                            }
                        }
                        RegistrationFormField(title: "Tahun Tanam") {
                            Button {
                                isNameFocused = false
                                viewModel.openPlantingDate()
                            } label: {
                                selectionLabel(
                                    viewModel.plantingYear.map { "\(PlantingDatePickerView.monthNames[viewModel.plantingMonth - 1]) \($0)" },
                                    placeholder: "Pilih tahun tanam", symbol: "calendar", trailing: "chevron.right"
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Tahun Tanam")
                            .accessibilityValue(viewModel.plantingYear.map(String.init) ?? "Belum dipilih")
                        }
                        RegistrationFormField(title: "Jenis Tanah") {
                            Menu {
                                Picker("Jenis Tanah", selection: $viewModel.soilType) {
                                    ForEach(SoilType.allCases) { soil in
                                        Text(soil.displayName).tag(Optional(soil))
                                    }
                                }
                            } label: {
                                selectionLabel(viewModel.soilType?.displayName,
                                               placeholder: "Pilih jenis tanah", symbol: "leaf",
                                               trailing: "chevron.up.chevron.down")
                            }
                            .tint(.primary)
                            .onChange(of: viewModel.soilType) { isNameFocused = false }
                            .accessibilityLabel("Jenis Tanah")
                            .accessibilityValue(viewModel.soilType?.displayName ?? "Belum dipilih")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background {
                        RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius)
                            .fill(RegistrationStyle.surface)
                            .onTapGesture { isNameFocused = false }
                    }
                    .padding(.horizontal, 16)
                }
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isNameFocused = false }
                }
            }
            .scrollBounceBehavior(.always)
            .scrollDismissesKeyboard(.immediately)
            .background {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { isNameFocused = false }
            }
            .bottomActionBar {
                RegistrationPrimaryButton(title: "Simpan Kebun", action: save)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 2)
            }
        }
        .background(RegistrationStyle.background)
        .sheet(isPresented: $viewModel.showsPlantingDate) {
            PlantingDatePickerView(month: viewModel.plantingMonth, year: viewModel.plantingYear ?? Calendar.current.component(.year, from: .now)) { month, year in
                viewModel.plantingMonth = month
                viewModel.plantingYear = year
            }
        }
        .presentationBackground(RegistrationStyle.background)
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .alert("Kebun belum tersimpan", isPresented: $viewModel.showsSaveError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
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
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: title == "Luas" ? "square.dashed.inset.filled" : "square.dashed")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .labelStyle(RegistrationMetricLabelStyle())
            Text(value).font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func save() {
        isNameFocused = false
        _ = viewModel.save()
    }
}

private struct RegistrationMetricLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(RegistrationStyle.actionTint)
            configuration.title
        }
    }
}

#if DEBUG
#Preview("Sheet Data Kebun · Kosong") {
    RegistrationSheetPreview(backdrop: "RegistrationClosedSatellite") {
        GardenDetailsView(viewModel: GardenRegistrationPreview.detailsViewModel(),
                          referenceMapImage: "RegistrationBoundaryMap", metrics: GardenPreviewData.metrics)
    }
}

#Preview("Sheet Data Kebun · Edit kebun") {
    RegistrationSheetPreview(backdrop: "RegistrationClosedSatellite") {
        GardenDetailsView(viewModel: GardenRegistrationPreview.detailsViewModel(editing: GardenPreviewData.garden),
                          referenceMapImage: "RegistrationBoundaryMap", metrics: GardenPreviewData.metrics)
    }
}

#Preview("Sheet Data Kebun · Teks besar") {
    RegistrationSheetPreview(backdrop: "RegistrationClosedSatellite") {
        GardenDetailsView(viewModel: GardenRegistrationPreview.detailsViewModel(editing: GardenPreviewData.garden),
                          referenceMapImage: "RegistrationBoundaryMap", metrics: GardenPreviewData.metrics)
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
#endif
