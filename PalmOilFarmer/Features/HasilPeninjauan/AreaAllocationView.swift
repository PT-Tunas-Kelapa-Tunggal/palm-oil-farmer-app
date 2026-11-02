import SwiftUI

struct AreaAllocationView: View {
    let result: ReviewResult
    let allocation: AreaAllocation

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                    areaList
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                }
                .padding(.bottom, KropsTheme.Spacing.content)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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

    private var areaList: some View {
        VStack(spacing: KropsTheme.Spacing.screen) {
            ForEach(allocation.lines) { line in
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

    private func actionIcon(_ line: AreaAllocation.Line) -> some View {
        Image(systemName: line.status == .fertilized
              ? "checkmark.circle.fill"
              : "arrow.triangle.turn.up.right.diamond.fill")
            .font(.title2)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .frame(width: 28)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Alokasi per Area") {
    NavigationStack {
        AreaAllocationView(result: .sample, allocation: .sample)
    }
}
#endif
