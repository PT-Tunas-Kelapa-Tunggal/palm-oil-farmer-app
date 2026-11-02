import SwiftUI

/// Dose details for one area, shown when its direction icon is tapped.
struct AreaDoseSheet: View {
    let fertilizerName: String
    let line: AreaAllocation.Line
    let onNavigate: () -> Void
    let onMarkFertilized: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: KropsTheme.Spacing.screen) {
                header
                dose
                photo
                // Pinned buttons would cover too much of the sheet at accessibility text sizes.
                if dynamicTypeSize.isAccessibilitySize { actions }
            }
            .padding(.horizontal, KropsTheme.Spacing.section)
            .padding(.top, KropsTheme.Spacing.section)
            .padding(.bottom, KropsTheme.Spacing.compact)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                actions
                    .padding(.horizontal, KropsTheme.Spacing.section)
                    .padding(.vertical, KropsTheme.Spacing.compact)
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.fraction(0.66), .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.background)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(fertilizerName).font(.title2.bold())
            Spacer(minLength: KropsTheme.Spacing.compact)
            Text("\(line.kilograms) kg").font(.title2)
        }
    }

    private var dose: some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            ReviewAmountText(value: line.dose, unit: "kg/pohon", size: 30, relativeTo: .title,
                             unitFont: .subheadline, unitIsSecondary: true)
            ReviewStatusLabel(status: line.status)
        }
        .accessibilityElement(children: .combine)
    }

    private var photo: some View {
        Group {
            if let photo = line.photo {
                Image(photo)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("Foto Area \(line.id)")
            } else {
                Rectangle()
                    .fill(KropsTheme.secondaryFill)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 170, height: 195)
        .clipShape(RoundedRectangle(cornerRadius: KropsTheme.Spacing.compact))
    }

    private var actions: some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            ReviewActionButton(title: "Arahkan ke Area \(line.id)",
                               systemImage: "arrow.triangle.turn.up.right.diamond.fill", action: onNavigate)
            ReviewActionButton(title: "Sudah Dipupuk", systemImage: "checkmark", iconLeads: true,
                               style: .muted, action: onMarkFertilized)
        }
    }
}

#if DEBUG
#Preview("Panel Area 2") {
    NavigationStack {
        AreaAllocationView(result: .sample, viewModel: .preview(fertilizer: "Urea", selectedLine: .ureaAreaTwo))
    }
}
#endif
