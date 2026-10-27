import SwiftUI

struct RegistrationIntroView: View {
    let onLocate: (GardenLocation) -> Void
    var referenceMapImage: String? = nil
    @State private var step: Step

    // Retained for the existing reference previews.
    enum Step: Int { case guide, photo, address }
    enum PhotoStatus { case idle, loading, missingLocation, failed }

    init(initialStep: Step = .guide, initialPhotoStatus: PhotoStatus = .idle,
         initialLocation: GardenLocation? = nil, referenceMapImage: String? = nil,
         onLocate: @escaping (GardenLocation) -> Void) {
        self.onLocate = onLocate
        self.referenceMapImage = referenceMapImage
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        Group {
            if step == .guide {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Petakan batas kebun").font(.title2.bold())
                        Text("Tandai titik titik di sepanjang batas kebun, pastikan seluruh bagian kebun masuk kedalam area pemetaan")
                            .font(.subheadline)
                        BoundaryGuideIllustration()
                            .frame(height: 141)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        StepIndicator(currentStep: 0, totalSteps: 3)
                        PrimaryActionButton(title: "Lanjut") { step = .address }
                    }
                    .padding(24)
                }
                .presentationDetents([.height(412), .large])
                .presentationDragIndicator(.visible)
            } else {
                LocationSearchView(onSelect: onLocate)
                    .presentationDetents([.large])
            }
        }
        .presentationBackgroundInteraction(.disabled)
    }
}

#Preview("Panduan Petakan Batas") {
    RegistrationIntroView(onLocate: { _ in })
}
#Preview("Cari alamat") {
    RegistrationIntroView(initialStep: .address, onLocate: { _ in })
}
