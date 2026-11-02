import SwiftUI

struct AreaAllocationView: View {
    let result: ReviewResult
    let allocation: AreaAllocation
    let onMarkFertilized: () -> Void
    let onNavigateToArea: (AreaAllocation.Line) -> Void
    let onMarkAreaFertilized: (AreaAllocation.Line) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var doseSize = 52
    @State private var selectedLine: AreaAllocation.Line?

    init(
        result: ReviewResult,
        allocation: AreaAllocation,
        initialSelectedLine: AreaAllocation.Line? = nil,
        onMarkFertilized: @escaping () -> Void = {},
        onNavigateToArea: @escaping (AreaAllocation.Line) -> Void = { _ in },
        onMarkAreaFertilized: @escaping (AreaAllocation.Line) -> Void = { _ in }
    ) {
        self.result = result
        self.allocation = allocation
        self.onMarkFertilized = onMarkFertilized
        self.onNavigateToArea = onNavigateToArea
        self.onMarkAreaFertilized = onMarkAreaFertilized
        _selectedLine = State(initialValue: initialSelectedLine)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: KropsTheme.Spacing.section) {
                    VStack(spacing: 0) {
                        ReviewMapHero(result: result, documentIcon: "doc.text", topInset: geometry.safeAreaInsets.top)
                        fertilizerRow
                            .padding(.horizontal, KropsTheme.Spacing.screen)
                            .padding(.top, -52)
                    }
                    distributionContent
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                }
                .padding(.bottom, KropsTheme.Spacing.content)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if case .uniform = allocation.distribution, !dynamicTypeSize.isAccessibilitySize {
                    fertilizedButton
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, KropsTheme.Spacing.compact)
                }
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedLine) { line in
            AreaDoseSheet(
                fertilizerName: allocation.selectedFertilizer,
                line: line,
                onNavigate: { onNavigateToArea(line) },
                onMarkFertilized: { onMarkAreaFertilized(line) }
            )
        }
    }

    private var fertilizerRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: KropsTheme.Spacing.compact))
            : AnyLayout(HStackLayout(spacing: KropsTheme.Spacing.compact))
        return layout {
            ForEach(allocation.fertilizers) { fertilizer in
                fertilizerCard(fertilizer, isSelected: fertilizer.name == allocation.selectedFertilizer)
            }
        }
    }

    private func fertilizerCard(_ fertilizer: AreaAllocation.Fertilizer, isSelected: Bool) -> some View {
        VStack(spacing: KropsTheme.Spacing.field) {
            Text(fertilizer.name).font(.subheadline.weight(.semibold))
            Text("\(fertilizer.kilograms) kg").font(.title3.bold())
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .primary)
        .padding(KropsTheme.Spacing.compact)
        .frame(maxWidth: .infinity, minHeight: 104)
        .background {
            RoundedRectangle(cornerRadius: KropsTheme.Radius.card)
                .fill(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.background))
                .shadow(color: .black.opacity(isSelected ? 0.3 : 0), radius: 6, y: 3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var distributionContent: some View {
        switch allocation.distribution {
        case .perArea(let lines, let guidance):
            VStack(alignment: .leading, spacing: KropsTheme.Spacing.screen) {
                if let guidance {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(guidance.title).font(.title3.bold())
                        Text(guidance.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                areaList(lines)
                if let guidance {
                    Text(guidance.footnote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        case .uniform(let dose, let note):
            VStack(spacing: KropsTheme.Spacing.screen) {
                uniformCard(dose: dose, note: note)
                // A pinned button would cover too much of the screen at accessibility text sizes.
                if dynamicTypeSize.isAccessibilitySize { fertilizedButton }
            }
        }
    }

    private func uniformCard(dose: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.field) {
            Text("TABUR MERATA")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color(uiColor: .systemBackground))
                .padding(.horizontal, KropsTheme.Spacing.field)
                .padding(.vertical, 4)
                .background(.primary, in: Capsule())
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(dose)
                    .font(.system(size: doseSize, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("kg / pohon").font(.headline)
            }
            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(KropsTheme.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
    }

    private var fertilizedButton: some View {
        Button(action: onMarkFertilized) {
            Label("Sudah Dipupuk", systemImage: "checkmark")
                .labelStyle(.titleAndIcon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(KropsTheme.Spacing.compact)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private func areaList(_ lines: [AreaAllocation.Line]) -> some View {
        VStack(spacing: KropsTheme.Spacing.screen) {
            ForEach(lines) { line in
                areaRow(line)
                    .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private func areaRow(_ line: AreaAllocation.Line) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: KropsTheme.Spacing.compact) {
                HStack(spacing: KropsTheme.Spacing.field) {
                    areaThumbnail
                    areaTitle(line)
                }
                statusLabel(line)
                HStack {
                    doseText(line)
                    Spacer(minLength: 0)
                    actionIcon(line)
                }
            }
        } else {
            HStack(spacing: KropsTheme.Spacing.field) {
                areaThumbnail
                areaTitle(line)
                Spacer(minLength: 0)
                statusLabel(line)
                doseText(line)
                actionIcon(line)
            }
        }
    }

    private var areaThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: KropsTheme.Spacing.field)
                .fill(KropsTheme.secondaryFill)
            Rectangle()
                .stroke(.secondary, lineWidth: 1)
                .frame(width: 30, height: 26)
                .rotationEffect(.degrees(-16))
            Circle()
                .fill(.secondary)
                .frame(width: 7, height: 7)
        }
        .frame(width: 60, height: 60)
        .accessibilityHidden(true)
    }

    private func areaTitle(_ line: AreaAllocation.Line) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Area \(line.id)").font(.title3.weight(.semibold))
            Text("\(line.kilograms)kg")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .opacity(line.status == .fertilized ? 0.45 : 1)
    }

    private func statusLabel(_ line: AreaAllocation.Line) -> some View {
        Label(line.status.title, systemImage: line.status.systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(line.status == .fertilized ? .primary : .secondary)
    }

    private func doseText(_ line: AreaAllocation.Line) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(line.dose).font(.title3.bold())
                Text("kg").font(.footnote)
            }
            Text("/pohon")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .opacity(line.status == .fertilized ? 0.45 : 1)
    }

    @ViewBuilder
    private func actionIcon(_ line: AreaAllocation.Line) -> some View {
        if line.status == .fertilized {
            rowIcon("checkmark.circle.fill")
                .accessibilityHidden(true)
        } else {
            Button {
                selectedLine = line
            } label: {
                rowIcon("arrow.triangle.turn.up.right.diamond.fill")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, -8)
            .accessibilityLabel("Arahkan ke Area \(line.id)")
        }
    }

    private func rowIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.title2)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .frame(width: 28)
    }
}

#if DEBUG
#Preview("Alokasi per Area") {
    NavigationStack {
        AreaAllocationView(result: .sample, allocation: .sample)
    }
}
#Preview("Tabur Merata") {
    NavigationStack {
        AreaAllocationView(result: .sample, allocation: .uniformSample)
    }
}
#Preview("Urea per Area") {
    NavigationStack {
        AreaAllocationView(result: .sample, allocation: .ureaSample)
    }
}
#endif
