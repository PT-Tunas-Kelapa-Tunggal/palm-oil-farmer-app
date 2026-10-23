import SwiftUI

/// A segmented control whose segments can carry a count badge, which the system Picker cannot show.
struct BadgedSegmentedControl<Value: Hashable & Identifiable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    var accessibilityName: (Value) -> String = { _ in "" }
    var badge: (Value) -> Int = { _ in 0 }
    @Namespace private var selectionSpace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                let isSelected = option == selection
                let count = badge(option)
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    HStack(spacing: 6) {
                        Text(title(option))
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        if count > 0 {
                            Text(count, format: .number)
                                .font(.caption2.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(KropsTheme.primary, in: Capsule())
                        }
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                                .matchedGeometryEffect(id: "selection", in: selectionSpace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityName(option).isEmpty ? title(option) : accessibilityName(option))
                .accessibilityValue(count > 0 ? "\(count) perlu tindakan" : "")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(KropsTheme.cardFill, in: Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }
}
