import SwiftUI

struct GardenProfileSectionHeader: View {
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.weight(.semibold)).frame(minHeight: 29, alignment: .leading).accessibilityAddTraits(.isHeader)
            if let message { Text(message).font(.subheadline).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

#if DEBUG
#Preview("Judul bagian · Jenis pupuk", traits: .sizeThatFitsLayout) {
    GardenProfileSectionHeader(title: "Jenis Pupuk",
        message: "Data pupuk yang diaplikasikan dalam periode pemupukan terakhir")
        .padding().frame(width: 402)
}
#endif
