import SwiftUI

struct GardenProfileSectionHeader: View {
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
            if let message { Text(message).font(.body).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

#if DEBUG
#Preview("Judul bagian · Jenis pupuk", traits: .sizeThatFitsLayout) {
    GardenProfileSectionHeader(title: "Jenis Pupuk",
        message: "Data pupuk yang diaplikasikan dalam periode pemupukan terakhir")
        .padding().frame(width: 402)
}
#endif
