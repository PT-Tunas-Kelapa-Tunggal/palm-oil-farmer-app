import SwiftUI

struct ConsentCheckbox: View {
    @Binding var isChecked: Bool
    let message: String

    var body: some View {
        Button { isChecked.toggle() } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                Text(message).font(.body)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(message)
        .accessibilityValue(isChecked ? "Disetujui" : "Belum disetujui")
    }
}
