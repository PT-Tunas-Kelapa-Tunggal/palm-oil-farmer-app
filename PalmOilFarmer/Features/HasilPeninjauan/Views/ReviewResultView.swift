import SwiftUI

/// Loads the review result, then shows it or the matching empty or error state.
struct ReviewResultView: View {
    @State private var viewModel: ReviewResultViewModel

    init(viewModel: ReviewResultViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loading:
                ProgressView("Memuat hasil peninjauan")
            case .loaded(let content):
                ReviewResultContentView(result: content.result, history: content.history)
            case .empty:
                ContentUnavailableView("Hasil peninjauan belum tersedia", systemImage: "chart.bar.doc.horizontal")
            case .failed(let message):
                ContentUnavailableView {
                    Label("Hasil peninjauan belum dapat dimuat", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Coba lagi") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .task {
            // Returning to this screen must not replace loaded content with a spinner.
            if case .loading = viewModel.phase { await viewModel.load() }
        }
    }
}

struct ReviewResultContentView: View {
    let result: ReviewResult
    let history: ReviewHistory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var totalColumnWidth = 96
    @ScaledMetric(relativeTo: .subheadline) private var priceColumnWidth = 116
    @State private var showsHistory = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: KropsTheme.Spacing.section) {
                    hero(topInset: geometry.safeAreaInsets.top)
                    Group {
                        VStack(spacing: KropsTheme.Spacing.compact) {
                            nutrientSection
                            summaryCard
                        }
                        budgetSection
                    }
                    .padding(.horizontal, KropsTheme.Spacing.screen)
                }
                .padding(.bottom, KropsTheme.Spacing.content)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsHistory) {
            ReviewHistorySheet(history: history)
        }
    }

    private func hero(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            ReviewMapHero(result: result, documentIcon: "doc", topInset: topInset)
            metricRow
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .padding(.top, -32)
        }
    }

    private var metricRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: KropsTheme.Spacing.compact))
            : AnyLayout(HStackLayout(spacing: KropsTheme.Spacing.compact))
        return layout {
            ForEach(result.metrics) { metric in
                VStack(spacing: 2) {
                    Text(metric.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(metric.value).font(.headline)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 72)
                .padding(.horizontal, 4)
                .reviewCard(padding: 0, cornerRadius: KropsTheme.Radius.metric)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var nutrientSection: some View {
        VStack(spacing: KropsTheme.Spacing.field) {
            ReviewSectionHeader(title: "Kondisi Hara Per Tahun", subtitle: "Kondisi hara dengan perawatan saat ini")
            LazyVGrid(columns: nutrientColumns, spacing: KropsTheme.Spacing.compact) {
                ForEach(result.nutrients) { nutrient in
                    nutrientCard(nutrient)
                }
            }
        }
    }

    private var nutrientColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: KropsTheme.Spacing.compact), GridItem(.flexible())]
    }

    private func nutrientCard(_ nutrient: ReviewResult.Nutrient) -> some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.compact) {
            HStack(spacing: 4) {
                Text("\(nutrient.name) (\(nutrient.symbol))")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Image(systemName: "info.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            ReviewAmountText(value: "\(nutrient.kilograms)", unit: "kg")
                .foregroundStyle(.secondary)
            Label(nutrient.status.title, systemImage: nutrient.status.systemImage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .reviewCard(padding: KropsTheme.Spacing.screen)
        .accessibilityElement(children: .combine)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.section) {
            Text(result.summary)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
            ReviewActionButton(title: "Lihat Rekomendasi Pemupukan", systemImage: "arrow.right",
                               font: .subheadline.weight(.semibold), minHeight: 48) { showsHistory = true }
        }
        .reviewCard()
    }

    private var budgetSection: some View {
        VStack(spacing: KropsTheme.Spacing.field) {
            ReviewSectionHeader(title: "Estimasi Anggaran Belanja Pupuk",
                                subtitle: "Rekomendasi kebutuhan pupuk dan Anggaran belanja untuk memenuhi hara ideal")
            VStack(spacing: 0) {
                if !dynamicTypeSize.isAccessibilitySize { budgetHeaderRow }
                ForEach(result.budgetLines) { line in
                    if line.id != result.budgetLines.first?.id || !dynamicTypeSize.isAccessibilitySize { Divider() }
                    if dynamicTypeSize.isAccessibilitySize {
                        stackedBudgetRow(line)
                    } else {
                        budgetRow(line)
                    }
                }
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: KropsTheme.Spacing.compact))
        }
    }

    /// Fixed table columns would push the page wider than the screen at accessibility text sizes.
    private func stackedBudgetRow(_ line: ReviewResult.BudgetLine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(line.name).fontWeight(.semibold)
            Text("Total (kg): \(line.kilograms)")
            Text("Harga: \(line.price)")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KropsTheme.Spacing.field)
    }

    private var budgetHeaderRow: some View {
        tableRow {
            Text("Jenis Pupuk").padding(tableCellInsets).frame(maxWidth: .infinity, alignment: .leading)
        } total: {
            Text("Total (kg)")
        } price: {
            Text("Harga")
        }
        .foregroundStyle(.secondary)
        .background(KropsTheme.secondaryFill)
    }

    private func budgetRow(_ line: ReviewResult.BudgetLine) -> some View {
        tableRow {
            HStack(spacing: 4) {
                Text(line.name).fontWeight(.semibold)
                Spacer(minLength: 0)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(tableCellInsets)
            .frame(maxWidth: .infinity)
        } total: {
            Text("\(line.kilograms)").fontWeight(.semibold)
        } price: {
            Text(line.price).fontWeight(.semibold)
        }
    }

    private var tableCellInsets: EdgeInsets {
        EdgeInsets(top: KropsTheme.Spacing.compact, leading: KropsTheme.Spacing.compact,
                   bottom: KropsTheme.Spacing.compact, trailing: KropsTheme.Spacing.compact)
    }

    private func tableRow<Name: View, Total: View, Price: View>(
        @ViewBuilder name: () -> Name,
        @ViewBuilder total: () -> Total,
        @ViewBuilder price: () -> Price
    ) -> some View {
        HStack(spacing: 0) {
            name()
            Divider()
            total()
                .padding(.vertical, KropsTheme.Spacing.compact)
                .frame(width: totalColumnWidth)
            Divider()
            price()
                .padding(.vertical, KropsTheme.Spacing.compact)
                .frame(width: priceColumnWidth)
        }
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
#Preview("Hasil Peninjauan") {
    NavigationStack {
        ReviewResultView(viewModel: .preview)
    }
}
#endif
