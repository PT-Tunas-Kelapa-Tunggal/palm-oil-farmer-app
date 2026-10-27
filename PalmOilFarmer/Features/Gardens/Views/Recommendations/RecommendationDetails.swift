import SwiftUI
import Charts
import MapKit

struct NutrientReference: Identifiable, Codable {
    let id: String
    let title: String
    let explanation: String
    let fertilizers: [FertilizerReference]
    let note: String
}

struct FertilizerReference: Identifiable, Codable {
    let name: String
    let detail: String
    var id: String { name }
}

struct RainfallDay: Identifiable, Codable {
    let id: String
    let symbol: String
    let precipitationMillimeters: Double
}

struct RainfallForecast: Codable {
    let dateRange: String
    let headline: String
    let days: [RainfallDay]
    let summary: String
}

struct NutrientReferenceScreen: View {
    let reference: NutrientReference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(reference.title).font(.title2.bold())
                Text(reference.explanation).font(.subheadline)
                Text("Pupuk yang mengandung " + reference.title.components(separatedBy: " (")[0].lowercased())
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(reference.fertilizers) { fertilizer in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fertilizer.name).font(.headline)
                        Text(fertilizer.detail).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    if fertilizer.id != reference.fertilizers.last?.id { Divider() }
                }
                Text(reference.note).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct RainfallForecastView: View {
    let forecast: RainfallForecast

    var body: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prakiraan hujan · " + forecast.dateRange)
                    .font(.footnote).foregroundStyle(.secondary)
                Text(forecast.headline).font(.headline)
                HStack(spacing: 4) {
                    ForEach(forecast.days) { day in
                        VStack(spacing: 8) {
                            Image(systemName: day.symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                            Spacer(minLength: 0)
                            Text(day.id).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("\(day.id), \(day.precipitationMillimeters.formatted()) milimeter hujan")
                    }
                }
                .frame(height: 92)
                .overlay {
                    Chart(forecast.days) { day in
                        LineMark(x: .value("Hari", day.id), y: .value("Hujan", day.precipitationMillimeters))
                            .foregroundStyle(Color.gray)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: 0...max(1, (forecast.days.map(\.precipitationMillimeters).max() ?? 0) * 2))
                    .padding(.horizontal, 10)
                    .padding(.top, 25)
                    .padding(.bottom, 24)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 24))
            Text(forecast.summary)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 24))
        }
    }
}

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
