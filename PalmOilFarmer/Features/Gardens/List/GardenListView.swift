import SwiftUI

struct GardenListView: View {
    var gardens: [Garden] = []
    var drafts: [GardenDraft] = []
    var onSelectDraft: (GardenDraft) -> Void = { _ in }
    var onDeleteDraft: (GardenDraft) -> Void = { _ in }
    var downloads: [MapDownloadItem] = []
    var onSelectDownload: (MapDownloadItem) -> Void = { _ in }
    var referenceMapImage: String? = nil
    var previewMetrics: GardenDisplayMetrics? = nil
    var onSelectGarden: (Garden) -> Void = { _ in }
    let onRegisterGarden: () -> Void
    /// Debug builds only: opens developer tools.
    var onOpenDeveloperMode: (() -> Void)? = nil
    @State private var filter = GardenListFilter.all

    private var visibleGardens: [Garden] { gardens.filter(filter.includes) }
    private var visibleDrafts: [GardenDraft] { filter.includesDrafts ? drafts : [] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kebun")
                    .font(.largeTitle.bold())
                    .foregroundStyle(gardens.isEmpty && drafts.isEmpty ? KropsTheme.titleText : .primary)
                Spacer()
                if let onOpenDeveloperMode {
                    Button("Mode Developer", systemImage: "wrench.and.screwdriver", action: onOpenDeveloperMode)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
            }
            .padding(KropsTheme.Spacing.screen)

            if gardens.isEmpty && drafts.isEmpty && downloads.isEmpty {
                GeometryReader { geometry in
                    ScrollView {
                        EmptyStateView(
                            title: "Belum ada kebun terdaftar",
                            message: "Gambar batas kebun di peta untuk mulai memantau kondisi dan hasil panen."
                        ) {
                            SeedlingIcon()
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            } else {
                BadgedSegmentedControl(
                    options: GardenListFilter.allCases, selection: $filter,
                    title: \.rawValue, accessibilityName: \.accessibilityName,
                    badge: { $0.actionCount(gardens: gardens, drafts: drafts) }
                )
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .padding(.bottom, 12)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if visibleGardens.isEmpty && visibleDrafts.isEmpty && downloads.isEmpty {
                            Text(filter.emptyMessage)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 48)
                        }
                        ForEach(GardenListItem.newestFirst(gardens: visibleGardens, drafts: visibleDrafts)) { item in
                            switch item {
                            case .garden(let garden):
                                Button {
                                    onSelectGarden(garden)
                                } label: {
                                    GardenCard(garden: garden, referenceImage: referenceMapImage, metrics: previewMetrics)
                                }
                                .buttonStyle(.plain)
                            case .draft(let draft):
                                Button {
                                    onSelectDraft(draft)
                                } label: {
                                    GardenDraftCard(draft: draft)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Hapus draf", systemImage: "trash", role: .destructive) {
                                        onDeleteDraft(draft)
                                    }
                                }
                            }
                        }
                        ForEach(downloads) { item in
                            Button {
                                onSelectDownload(item)
                            } label: {
                                MapDownloadCard(location: item.location, state: item.state,
                                                referenceMapImage: item.referenceMapImage)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, KropsTheme.Spacing.screen)
                    .padding(.bottom, 12)
                    .animation(.snappy, value: filter)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: "Daftarkan Kebun", systemImage: "plus", action: onRegisterGarden)
                .padding(.horizontal, 34)
                .padding(.bottom, 2)
                .padding(.top, 24)
                .background { BottomBlurFade() }
        }
    }
}

struct GardenDraftCard: View {
    let draft: GardenDraft
    var referenceImage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            LocationMapPreview(location: draft.location, referenceImage: referenceImage)
                .frame(height: 201)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 8) {
                Text("Lanjutkan pemetaan")
                    .font(.title3.weight(.semibold))
                Label(draft.title, systemImage: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Buka peta untuk memetakan batas kebun")
    }
}

#Preview("01 · Kebun Kosong") {
    GardenListView(onRegisterGarden: {})
}

#if DEBUG
#Preview("Kebun · Draft") {
    GardenListView(drafts: [GardenDraft(location: GardenLocation(
        name: "Malang rapat", subtitle: "Gunung Kijang, Bintan",
        coordinate: GardenPreviewData.location.coordinate
    ))], onRegisterGarden: {})
}
#Preview("01 Copy · Daftar Kebun") {
    GardenListView(
        gardens: GardenPreviewData.gardens,
        referenceMapImage: "GardenCardMap",
        previewMetrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"),
        onRegisterGarden: {}
    )
}
#endif
