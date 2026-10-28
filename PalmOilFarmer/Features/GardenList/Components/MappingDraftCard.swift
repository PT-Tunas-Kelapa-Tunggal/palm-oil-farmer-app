import SwiftUI

struct MappingDraftCard: View {
    let draft: MappingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LocationMapPreview(location: draft.location)
                .frame(height: 180)
                .clipped()
            VStack(alignment: .leading, spacing: 8) {
                Label(draft.location.name, systemImage: "location")
                    .font(.subheadline)
                HStack {
                    Text("Lanjutkan pemetaan").font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .padding(16)
        }
        .foregroundStyle(.primary)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
