import SwiftUI

/// Floating glass menu dropdown allowing the farmer to select an alternative NPK formulation.
/// Matches Sketch: "Organism / Menu Picker / NPK Type" and the floating menu design.
public struct NPKPickerMenuView: View {
    public let options: [NPKOption]
    public let selectedOptionId: String
    public let height: CGFloat?
    public let onSelect: (NPKOption) -> Void

    public init(
        options: [NPKOption],
        selectedOptionId: String,
        height: CGFloat? = nil,
        onSelect: @escaping (NPKOption) -> Void
    ) {
        self.options = options
        self.selectedOptionId = selectedOptionId
        self.height = height
        self.onSelect = onSelect
    }

    public static func estimatedHeight(for options: [NPKOption]) -> CGFloat {
        16 + options.reduce(CGFloat.zero) { total, option in
            total + (option.tag == nil ? 64 : 82)
        }
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(options) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        // Checkmark column
                        Group {
                            if option.id == selectedOptionId {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: 20, height: 20, alignment: .center)

                        // Title & Subtitle column
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.name)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

                            Text("\(option.weightKg) kg, \(option.formattedPrice)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.72))

                            if let tag = option.tag {
                                Text(tag)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.72))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            }
        }
        .scrollIndicators(.visible)
        .padding(.vertical, 8)
        .frame(height: height ?? Self.estimatedHeight(for: options))
        .frame(width: 250)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 30, x: 0, y: 14)
    }
}

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.96, blue: 0.97).ignoresSafeArea()

        NPKPickerMenuView(
            options: FertilizerEstimationOverview.sample.npkOptions,
            selectedOptionId: "npk-15",
            onSelect: { _ in }
        )
    }
}
