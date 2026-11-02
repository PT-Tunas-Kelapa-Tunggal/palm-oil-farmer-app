import SwiftUI

/// CodedUI3 styling is scoped to garden setup so recommendation screens keep their own design.
enum GardenFlowStyle {
    static let background = Color(uiColor: .systemBackground)
    static let card = Color(uiColor: .systemGray6)
}

struct GardenFlowActionButton: View {
    let title: String
    var systemImage: String? = nil
    var imagePlacement: HorizontalEdge = .trailing
    var isProminent = true
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage, imagePlacement == .leading { Image(systemName: systemImage) }
                Text(title)
                if let systemImage, imagePlacement == .trailing { Image(systemName: systemImage) }
            }
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isProminent ? Color.white : Color.primary)
        .glassEffect(
            .regular.tint(isProminent ? Color(white: 0.3) : .clear).interactive(),
            in: Capsule()
        )
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// The two segments describe the fertilizer and harvest forms, not persistence status.
struct GardenHistoryFormHeader: View {
    let step: Int
    let onBack: () -> Void
    let onConfirm: () -> Void
    var confirmationTitle: String? = nil

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: step == 1 ? "xmark" : "chevron.left")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(step == 1 ? "Tutup" : "Kembali")
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...2, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Color.secondary : Color.secondary.opacity(0.25))
                        .frame(width: 54, height: 6)
                }
            }
            .accessibilityLabel("Langkah \(step) dari 2")
            Spacer()
            Button(action: onConfirm) {
                Group {
                    if let confirmationTitle {
                        Text(confirmationTitle)
                    } else {
                        Image(systemName: "checkmark").font(.title2)
                    }
                }
                .padding(.horizontal, confirmationTitle == nil ? 0 : 12)
                .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule())
            .accessibilityLabel(confirmationTitle ?? "Simpan")
        }
        .padding(12)
    }
}

#Preview("Garden Flow Actions", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        GardenFlowActionButton(title: "Lanjut", action: {})
        GardenFlowActionButton(title: "Ajukan", systemImage: "paperplane.fill", action: {})
    }
    .padding(24)
    .frame(width: 402)
}
