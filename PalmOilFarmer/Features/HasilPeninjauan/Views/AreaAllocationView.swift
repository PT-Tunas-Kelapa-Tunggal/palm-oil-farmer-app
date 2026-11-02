import SwiftUI

struct AreaAllocationView: View {
    let result: ReviewResult
    let onNavigateToArea: (AreaAllocation.Line) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var doseSize = 52
    @State private var viewModel: AreaAllocationViewModel

    init(
        result: ReviewResult,
        viewModel: AreaAllocationViewModel,
        onNavigateToArea: @escaping (AreaAllocation.Line) -> Void = { _ in }
    ) {
        self.result = result
        self.onNavigateToArea = onNavigateToArea
        _viewModel = State(initialValue: viewModel)
    }

    private var allocation: AreaAllocation { viewModel.allocation }

    /// Alerts belong to the topmost presentation, so the sheet and the screen each show their own.
    private func hasError(whileSheetIsOpen: Bool) -> Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && (viewModel.selectedLine != nil) == whileSheetIsOpen },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
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
                if case .uniform(_, _, let isFertilized) = allocation.distribution,
                   !dynamicTypeSize.isAccessibilitySize {
                    fertilizedButton(isFertilized: isFertilized)
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, KropsTheme.Spacing.compact)
                }
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $viewModel.selectedLine) { line in
            AreaDoseSheet(
                fertilizerName: allocation.selectedFertilizer,
                line: line,
                onNavigate: { onNavigateToArea(line) },
                onMarkFertilized: { Task { await viewModel.markFertilized(areaID: line.id) } }
            )
            .alert("Belum tersimpan", isPresented: hasError(whileSheetIsOpen: true)) {
                Button("Mengerti", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .alert("Belum tersimpan", isPresented: hasError(whileSheetIsOpen: false)) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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
        Button {
            viewModel.selectFertilizer(fertilizer.name)
        } label: {
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
        }
        .buttonStyle(.plain)
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
        case .uniform(let dose, let note, let isFertilized):
            VStack(spacing: KropsTheme.Spacing.screen) {
                uniformCard(dose: dose, note: note)
                // A pinned button would cover too much of the screen at accessibility text sizes.
                if dynamicTypeSize.isAccessibilitySize { fertilizedButton(isFertilized: isFertilized) }
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

    private func fertilizedButton(isFertilized: Bool) -> some View {
        Button {
            Task { await viewModel.markFertilized(areaID: nil) }
        } label: {
            Label("Sudah Dipupuk", systemImage: "checkmark")
                .labelStyle(.titleAndIcon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(KropsTheme.Spacing.compact)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(isFertilized)
        .opacity(isFertilized ? 0.45 : 1)
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
                viewModel.select(line)
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
        AreaAllocationView(result: .sample, viewModel: .preview())
    }
}
#Preview("Tabur Merata") {
    NavigationStack {
        AreaAllocationView(result: .sample, viewModel: .preview(fertilizer: "NPK 15-15-15"))
    }
}
#Preview("Urea per Area") {
    NavigationStack {
        AreaAllocationView(result: .sample, viewModel: .preview(fertilizer: "Urea"))
    }
}
#endif
