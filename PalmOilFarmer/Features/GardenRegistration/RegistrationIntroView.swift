import SwiftUI

/// Registration starts with the boundary guide, then grows into the address search in the same sheet.
struct RegistrationIntroView: View {
    @ScaledMetric(relativeTo: .body) private var contentHeight = 141
    @State private var flow: GardenRegistrationFlow

    typealias Step = GardenRegistrationStep

    init(flow: GardenRegistrationFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        Group {
            switch flow.coordinator.step {
            case .guide:
                guide.fittedSheetHeight()
            case .search:
                LocationSearchView(flow: flow).presentationDetents([.large])
            }
        }
        .presentationDragIndicator(flow.coordinator.step == .guide ? .visible : .hidden)
        .presentationBackgroundInteraction(.disabled)
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Petakan batas kebun")
                .font(.title2.bold())
                .padding(.bottom, 10)

            Text("Tandai titik titik di sepanjang batas kebun, pastikan seluruh bagian kebun masuk kedalam area pemetaan")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 60, alignment: .topLeading)
                .padding(.bottom, 16)

            BoundaryGuideIllustration()
                .frame(height: contentHeight)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.bottom, 24)

            PrimaryActionButton(title: "Lanjut") {
                withAnimation { flow.coordinator.continueToSearch() }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
}

#Preview("02 · Panduan Petakan Batas") {
    RegistrationIntroView(onLocate: { _ in })
}

#if DEBUG
#Preview("03 · Cari Alamat") {
    RegistrationIntroView(initialStep: .search, onLocate: { _ in })
}
#endif
