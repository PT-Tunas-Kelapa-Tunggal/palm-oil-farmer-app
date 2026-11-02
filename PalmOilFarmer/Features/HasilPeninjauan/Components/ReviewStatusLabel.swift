import SwiftUI

/// Shows how an area's fertilizer dose changed, or that it is already done.
struct ReviewStatusLabel: View {
    let status: AreaAllocation.Status

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(status == .fertilized ? .primary : .secondary)
    }
}
