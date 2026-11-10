import SwiftUI

struct FertilizerScheduleView: View {
    @Bindable var viewModel: FertilizerScheduleViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FertilizerScheduleStyle.screenBackground.ignoresSafeArea())
            .environment(\.colorScheme, .dark)
            .navigationBarBackButtonHidden(true)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .task { await viewModel.load() }
            .navigationDestination(item: $viewModel.destination) { _ in
                FertilizerExampleScreen()
            }
            .sheet(item: presentedSheet) { sheet in
                FertilizerPeriodSheet(sheet: sheet, onClose: viewModel.closePeriod, onSelectStep: viewModel.selectStep)
            }
    }

    private var presentedSheet: Binding<FertilizerSchedulePresentation.PeriodSheet?> {
        Binding(
            get: { viewModel.presentedPeriod },
            set: { if $0 == nil { viewModel.closePeriod() } }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().tint(.white)
        case .failed(let message):
            VStack(spacing: KropsTheme.Spacing.field) {
                Text(message).font(.headline).multilineTextAlignment(.center)
                Button("Coba lagi") { Task { await viewModel.load() } }
                    .buttonStyle(.glass)
            }
            .padding(KropsTheme.Spacing.content)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) { backButton.padding(.horizontal, KropsTheme.Spacing.screen) }
        case .loaded(let presentation):
            loaded(presentation)
        }
    }

    private var backButton: some View {
        GardenProfileIconButton(symbol: "chevron.left", label: "Kembali") { dismiss() }
    }

    private func loaded(_ presentation: FertilizerSchedulePresentation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KropsTheme.Spacing.section) {
                header(presentation.subtitle)

                if presentation.isEmpty {
                    Text("Belum ada jadwal pemupukan")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }

                if let hero = presentation.hero {
                    heroCard(hero)
                }

                if let subtitle = presentation.nextPeriodsSubtitle {
                    section(title: "Periode Selanjutnya", subtitle: subtitle) {
                        ForEach(presentation.nextPeriods) { card in
                            nextPeriodCard(card)
                        }
                    }
                }

                if !presentation.completedPeriods.isEmpty {
                    section(title: "Sudah Selesai", subtitle: "Catatan pupuk yang sudah diberikan.") {
                        ForEach(presentation.completedPeriods) { card in
                            completedCard(card)
                        }
                    }
                }
            }
            .padding(.horizontal, KropsTheme.Spacing.screen)
            .padding(.bottom, KropsTheme.Spacing.content)
        }
    }

    private func header(_ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            backButton.padding(.bottom, 18)
            Text("Jadwal Pemupukan")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }

    // MARK: Hero

    private func heroCard(_ hero: FertilizerSchedulePresentation.Hero) -> some View {
        VStack(spacing: 0) {
            switch hero {
            case .active(let range, let dayTitle, let daySubtitle, let rows):
                Label {
                    Text("Sedang berlangsung")
                } icon: {
                    Circle().fill(FertilizerScheduleStyle.accent).frame(width: 8, height: 8)
                }
                .labelStyle(DotLabelStyle())
                .font(.footnote.weight(.semibold))
                .padding(.bottom, 14)

                dateRow(range)

                VStack(spacing: 0) {
                    Text(dayTitle).font(.title.bold())
                    Text(daySubtitle).font(.headline).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .padding(.top, 18)
                .padding(.bottom, 20)

                FertilizerTimelineList(rows: rows, onSelectStep: viewModel.selectStep)

            case .upcoming(let periodID, let title, let range):
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pemupukan terdekat").font(.subheadline).foregroundStyle(.secondary)
                    Text(title).font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .padding(.bottom, 20)

                dateRow(range)

                Button { viewModel.openPeriod(periodID) } label: {
                    HStack(spacing: 6) {
                        Text("Lihat pupuk")
                        Image(systemName: "chevron.right").font(.footnote.weight(.bold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 14)
            }
        }
        .padding(20)
        .modifier(WhiteCard(radius: FertilizerScheduleStyle.heroRadius))
    }

    private func dateRow(_ range: FertilizerSchedulePresentation.DateRange) -> some View {
        HStack(alignment: .center, spacing: 8) {
            dateColumn(label: "Mulai", day: range.startDay, detail: range.startDetail, alignment: .leading)
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    DottedLine()
                    SeedlingIcon()
                        .scaleEffect(18 / 52)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(FertilizerScheduleStyle.accent, in: Circle())
                    DottedLine()
                }
                Text(range.length).font(.caption).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            dateColumn(label: "Selesai", day: range.endDay, detail: range.endDetail, alignment: .trailing)
        }
    }

    private func dateColumn(label: String, day: String, detail: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(day).font(.title.bold())
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    // MARK: Sections

    private func section(title: String, subtitle: String, @ViewBuilder cards: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, KropsTheme.Spacing.screen)
            .padding(.top, 8)
            cards()
        }
    }

    private func nextPeriodCard(_ card: FertilizerSchedulePresentation.NextPeriodCard) -> some View {
        Button { viewModel.openPeriod(card.id) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.caption).font(.footnote).foregroundStyle(.secondary)
                        Text(card.title).font(.title3.weight(.bold))
                    }
                    Spacer(minLength: 8)
                    chevron
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { chips(card.fertilizers) }
                    VStack(alignment: .leading, spacing: 8) { chips(card.fertilizers) }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(WhiteCard(radius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func chips(_ names: [String]) -> some View {
        ForEach(names.indices, id: \.self) { index in
            Text(names[index])
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FertilizerScheduleStyle.neutralFill, in: Capsule())
        }
    }

    private func completedCard(_ card: FertilizerSchedulePresentation.CompletedPeriodCard) -> some View {
        Button { viewModel.openPeriod(card.id) } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FertilizerScheduleStyle.accent)
                    .frame(width: 36, height: 36)
                    .background(FertilizerScheduleStyle.accentSoft, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.caption).font(.footnote).foregroundStyle(.secondary)
                    Text(card.title).font(.title3.weight(.bold))
                }
                Spacer(minLength: 8)
                chevron
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(WhiteCard(radius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.title), \(card.caption), selesai")
        .accessibilityAddTraits(.isButton)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.body.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
}

/// White surface with dark content in both appearances, as in the design.
private struct WhiteCard: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .background(.white, in: RoundedRectangle(cornerRadius: radius))
            .environment(\.colorScheme, .light)
    }
}

private struct DotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
            configuration.title
        }
    }
}

private struct DottedLine: View {
    var body: some View {
        Line()
            .stroke(Color(white: 0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 4]))
            .frame(height: 2)
            .frame(minWidth: 12, maxWidth: .infinity)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

#if DEBUG
private typealias PreviewData = FertilizerSchedulePreviewData

@MainActor
private func previewModel(
    _ scenario: PreviewData.Scenario, error: (any Error & Sendable)? = nil, sheet: UUID? = nil
) -> FertilizerScheduleViewModel {
    let model = FertilizerScheduleViewModel(
        gardenID: PreviewData.ID.garden,
        repository: StubFertilizerScheduleRepository(schedule: scenario.schedule, error: error),
        now: { scenario.today },
        calendar: PreviewData.calendar
    )
    model.presentedPeriodID = sheet
    return model
}

private struct SchedulePreview: View {
    @State var viewModel: FertilizerScheduleViewModel

    var body: some View {
        NavigationStack {
            FertilizerScheduleView(viewModel: viewModel)
        }
        .environment(\.locale, Locale(identifier: "id_ID"))
    }
}

#Preview("Sebelum periode") { SchedulePreview(viewModel: previewModel(PreviewData.beforePeriod)) }
#Preview("Hari ke-5 · Dolomit") { SchedulePreview(viewModel: previewModel(PreviewData.day5Dolomit)) }
#Preview("Hari ke-12 · Jeda") { SchedulePreview(viewModel: previewModel(PreviewData.day12Gap)) }
#Preview("Hari ke-21 · NPK") { SchedulePreview(viewModel: previewModel(PreviewData.day21NPK)) }
#Preview("Hari ke-21 · Jeda") { SchedulePreview(viewModel: previewModel(PreviewData.day21Gap)) }
#Preview("Hari ke-25 · Urea") { SchedulePreview(viewModel: previewModel(PreviewData.day25Urea)) }
#Preview("Antar periode") { SchedulePreview(viewModel: previewModel(PreviewData.betweenPeriods)) }
#Preview("Sheet Pemupukan 3") {
    SchedulePreview(viewModel: previewModel(PreviewData.betweenPeriods, sheet: PreviewData.ID.period3))
}
#Preview("Gagal memuat") {
    SchedulePreview(viewModel: previewModel(PreviewData.day12Gap, error: StubFertilizerScheduleRepository.LoadError()))
}
#Preview("Hari ke-12 · Gelap") {
    SchedulePreview(viewModel: previewModel(PreviewData.day12Gap)).preferredColorScheme(.dark)
}
#Preview("Hari ke-12 · Teks XXL") {
    SchedulePreview(viewModel: previewModel(PreviewData.day12Gap)).dynamicTypeSize(.accessibility4)
}
#endif
