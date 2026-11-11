import SwiftUI

/// Status pill badge reflecting evaluation state: Kurang (Deficient), Berlebih (Excess), or Cukup (Sufficient).
public struct NutrientStatusPill: View {
    public let status: NutrientStatus

    private let alertColor = Color(red: 1.0, green: 0.31, blue: 0.09) // #FF4F18

    public init(status: NutrientStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))

            Text(status.displayName)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(textColor)
        .background {
            if status == .excess {
                Capsule()
                    .strokeBorder(alertColor, lineWidth: 1)
            } else {
                Capsule()
                    .fill(backgroundColor)
            }
        }
    }

    private var iconName: String {
        switch status {
        case .deficient:
            return "arrow.down"
        case .excess:
            return "arrow.up"
        case .sufficient:
            return "checkmark"
        }
    }

    private var textColor: Color {
        switch status {
        case .deficient:
            return .white
        case .excess:
            return alertColor
        case .sufficient:
            return Color(red: 0.08, green: 0.08, blue: 0.09)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .deficient:
            return alertColor
        case .excess:
            return .clear
        case .sufficient:
            return Color(uiColor: .systemGray5)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        NutrientStatusPill(status: .deficient)
        NutrientStatusPill(status: .excess)
        NutrientStatusPill(status: .sufficient)
    }
    .padding()
}

