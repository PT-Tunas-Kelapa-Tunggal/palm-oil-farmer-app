import SwiftUI

/// Dose details for one area, shown when its direction icon is tapped.
struct AreaDoseSheet: View {
    let fertilizerName: String
    let line: AreaAllocation.Line
    let onNavigate: () -> Void
    let onMarkFertilized: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var doseSize = 30

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
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(line.dose).font(.system(size: doseSize, weight: .bold))
                Text("kg/pohon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Label(line.status.title, systemImage: line.status.systemImage)
                .labelStyle(.titleAndIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
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
            Button(action: onNavigate) {
                HStack(spacing: 6) {
                    Text("Arahkan ke Area \(line.id)")
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .padding(KropsTheme.Spacing.compact)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.primary, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            }
            .buttonStyle(.plain)

            Button(action: onMarkFertilized) {
                Label("Sudah Dipupuk", systemImage: "checkmark")
                    .labelStyle(.titleAndIcon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(KropsTheme.Spacing.compact)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(KropsTheme.secondaryFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            }
            .buttonStyle(.plain)
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
