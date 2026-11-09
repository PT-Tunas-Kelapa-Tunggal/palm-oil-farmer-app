import SwiftUI

struct RegistrationIconButton: View {
    let symbol: String
    let label: String
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .frame(width: RegistrationStyle.controlSize, height: RegistrationStyle.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isProminent ? RegistrationStyle.onAction : .primary)
        .background {
            if isProminent { Circle().fill(RegistrationStyle.actionTint) }
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(label)
    }
}
