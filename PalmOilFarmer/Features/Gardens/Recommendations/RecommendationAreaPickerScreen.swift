import SwiftUI

struct RecommendationAreaPickerScreen: View {
    let areas: [FertilizerAllocationArea]
    @Binding var selectedAreaID: String
    @State private var pendingAreaID: String
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    init(areas: [FertilizerAllocationArea], selectedAreaID: Binding<String>) {
        self.areas = areas
        _selectedAreaID = selectedAreaID
        _pendingAreaID = State(initialValue: selectedAreaID.wrappedValue)
    }

    private var filteredAreas: [FertilizerAllocationArea] {
        areas.filter { query.isEmpty || $0.id.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Area Kebun", onClose: { dismiss() })
                .overlay(alignment: .trailing) {
                    Button {
                        selectedAreaID = pendingAreaID
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.white)
                            .background(.black, in: Circle())
                    }
                    .disabled(!areas.contains { $0.id == pendingAreaID })
                    .accessibilityLabel("Konfirmasi area")
                    .padding(.trailing, 12)
                }
            TextField("Cari kode area", text: $query)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(KropsTheme.tertiaryFill, in: Capsule())
                .padding(.horizontal, 16)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredAreas) { area in
                        Button { pendingAreaID = area.id } label: {
                            HStack(spacing: 16) {
                                Group {
                                    if let mapImage = area.mapImage {
                                        Image(mapImage).resizable().scaledToFill()
                                    } else if let boundary = area.boundary {
                                        GardenMapView(boundary: boundary)
                                    } else {
                                        Image(systemName: "map").font(.title)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(KropsTheme.secondaryFill)
                                    }
                                }
                                .frame(width: 68, height: 68).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text("Area " + area.id).font(.title3)
                                Spacer()
                                if pendingAreaID == area.id {
                                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(pendingAreaID == area.id ? .isSelected : [])
                    }
                    if filteredAreas.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                }
                .padding(16)
            }
        }
        .presentationDetents([.large])
    }
}
