import SwiftUI

struct GardenSectionHeader: View {
    let title: String
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
            Button(action: onEdit) {
                Label("Ubah", systemImage: "pencil.line")
                    .font(.subheadline)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 25)
    }
}
