import SwiftUI

struct HistoryValueRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let value: String

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            Text(title)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 4) }
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
        .frame(minHeight: 20)
        .accessibilityElement(children: .combine)
    }
}
