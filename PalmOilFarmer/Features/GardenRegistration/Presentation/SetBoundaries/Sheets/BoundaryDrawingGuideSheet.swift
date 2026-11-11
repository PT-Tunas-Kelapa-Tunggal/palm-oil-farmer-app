import SwiftUI

/// SHEET content on the boundary map, stage `.guide`: two pages ("zoom", "tandai sudut").
struct BoundaryDrawingGuideSheet: View {
    var step: BoundaryDrawingGuideStep = .zoom
    let onContinue: () -> Void

    var body: some View {
        DynamicSheet(animation: .bouncy, size: .small) {
            content
        }
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled)
        .presentationCompactAdaptation(.sheet)
        .preferredColorScheme(.light)
    }

    private var content: some View {
        VStack(spacing: KropsTheme.Spacing.field) {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: KropsTheme.Spacing.field) {
                        HStack(spacing: KropsTheme.Spacing.compact) {
                            ForEach(BoundaryDrawingGuideStep.allCases, id: \.self) { page in
                                Circle()
                                    .fill(page == step ? RegistrationStyle.onAction : RegistrationStyle.onAction.opacity(0.3))
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Panduan \(step.rawValue + 1) dari 2")

                        VStack(spacing: KropsTheme.Spacing.compact) {
                            Text(step.title)
                                .font(.title2.bold())
                                .accessibilityAddTraits(.isHeader)
                            Text(step.message)
                                .font(KropsTheme.Typography.body)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .id(step)
                        .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            RegistrationPrimaryButton(title: step.buttonTitle, action: onContinue)
                .accessibilityIdentifier("boundaryGuideContinue")
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.top, KropsTheme.Spacing.screen)
        .padding(.bottom, KropsTheme.Spacing.field)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
#Preview("Sheet panduan · Zoom") {
    RegistrationSheetPreview(backdrop: "RegistrationGuideSatellite") {
        BoundaryDrawingGuideSheet(onContinue: {})
    }
}

#Preview("Sheet panduan · Tandai sudut") {
    RegistrationSheetPreview(backdrop: "RegistrationGuideSatellite") {
        BoundaryDrawingGuideSheet(step: .tap, onContinue: {})
    }
}

#Preview("Sheet panduan · Teks besar") {
    RegistrationSheetPreview(backdrop: "RegistrationGuideSatellite") {
        BoundaryDrawingGuideSheet(step: .tap, onContinue: {})
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
#endif
