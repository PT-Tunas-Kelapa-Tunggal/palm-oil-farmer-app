import SwiftUI

/// A draft saved with "Lakukan Nanti", waiting for its boundary to be mapped.
struct DashboardDraftCard: View {
    let draft: DashboardDraft
    var referenceImage: String? = nil

    /// The shared map preview takes the app's location type; built only for drawing.
    private var mapLocation: GardenLocation {
        GardenLocation(name: draft.name, subtitle: draft.subtitle,
                       coordinate: GardenCoordinate(latitude: draft.coordinate.latitude,
                                                    longitude: draft.coordinate.longitude))
    }

    var body: some View {
        VStack(spacing: 0) {
            LocationMapPreview(location: mapLocation, referenceImage: referenceImage)
                .frame(height: 201)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 8) {
                Text("Lanjutkan pemetaan")
                    .font(.title3.weight(.semibold))
                Label(draft.title, systemImage: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Buka peta untuk memetakan batas kebun")
    }
}
