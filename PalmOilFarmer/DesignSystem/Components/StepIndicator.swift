import SwiftUI

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step == currentStep ? Color.secondary : Color.secondary.opacity(0.25))
                    .frame(width: step == currentStep ? 41 : 21, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityLabel("Langkah \(currentStep + 1) dari \(totalSteps)")
    }
}

#if DEBUG
#Preview("Registration Steps", traits: .sizeThatFitsLayout) {
    VStack(spacing: 8) {
        ForEach(0..<3) { step in
            StepIndicator(currentStep: step, totalSteps: 3)
        }
    }
    .frame(width: 338)
    .padding()
    .background(KropsTheme.surfaceBackground)
}
#endif
