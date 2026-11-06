import SwiftUI

/// A selectable row for search results and alternative location sources.
struct LocationOptionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize = 36
    let title: String
    let subtitle: String
    let symbol: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 14))
        Button(action: action) {
            layout {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color(uiColor: .systemGray5), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                if isLoading {
                    ProgressView()
                } else if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
            .contentShape(RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
