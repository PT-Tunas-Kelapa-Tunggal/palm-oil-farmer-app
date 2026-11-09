import SwiftUI

/// Shared layout for the production screen and the existing value-based previews.
struct GardenListContent: View {
    let presentation: GardenListPresentation
    @Binding var selectedFilter: GardenListFilter
    let showsFilter: Bool
    var onSelectDraft: (GardenDraft) -> Void = { _ in }
    var onDeleteDraft: (GardenDraft) -> Void = { _ in }
    var downloads: [MapDownloadItem] = []
    var onSelectDownload: (MapDownloadItem) -> Void = { _ in }
    var referenceMapImage: String? = nil
    var fertilizerSchedules: [UUID: String] = [:]
    var previewMetrics: GardenDisplayMetrics? = nil
    var onSelectGarden: (Garden) -> Void = { _ in }
    let onRegisterGarden: () -> Void
    var onOpenDeveloperMode: (() -> Void)? = nil
    @State private var developerTrigger = 0

    private var filter: GardenListFilter { presentation.filter }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kebun")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    // Debug builds: hold the title to open Mode Developer, hidden from test participants.
                    .onLongPressGesture(minimumDuration: 1.5) {
                        guard let onOpenDeveloperMode else { return }
                        developerTrigger += 1
                        onOpenDeveloperMode()
                    }
                    .sensoryFeedback(.success, trigger: developerTrigger)
                Spacer()
                if !presentation.isEmpty || !downloads.isEmpty {
                    Button(action: onRegisterGarden) {
                        Image(systemName: "plus").font(.system(size: 22)).frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel("Daftarkan Kebun")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            if presentation.isEmpty && downloads.isEmpty {
                GeometryReader { geometry in
                    ScrollView {
                        GardenRegistrationEmptyState()
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            } else {
                if showsFilter {
                    BadgedSegmentedControl(
                        options: GardenListFilter.allCases, selection: $selectedFilter,
                        title: \.rawValue, accessibilityName: \.accessibilityName,
                        badge: { presentation.actionCount(for: $0) }
                    )
                    .padding(.horizontal, KropsTheme.Spacing.screen)
                    .padding(.bottom, 12)
                }
                if presentation.hasNoVisibleItems && downloads.isEmpty {
                    GeometryReader { geometry in
                        ScrollView {
                            EmptyStateView(title: filter.emptyTitle, message: filter.emptyMessage, messageFont: .body) {
                                Image(systemName: filter.emptySymbol)
                                    .font(.system(size: 40, weight: .regular))
                                    .frame(width: 88, height: 88)
                                    .background(KropsTheme.cardFill, in: Circle())
                            }
                            .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.8)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    .transition(.opacity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(presentation.items) { item in
                                switch item {
                                case .garden(let garden):
                                    Button {
                                        onSelectGarden(garden)
                                    } label: {
                                        GardenCard(garden: garden, referenceImage: referenceMapImage, metrics: previewMetrics, fertilizerSchedule: fertilizerSchedules[garden.id])
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
        }
        .background {
            if presentation.isEmpty && downloads.isEmpty {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                RadialGradient(colors: [RegistrationStyle.actionTint.opacity(0.12), .clear],
                               center: .center, startRadius: 30, endRadius: 320)
                    .ignoresSafeArea()
            } else {
                GardenProfileStyle.background.ignoresSafeArea()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if presentation.isEmpty && downloads.isEmpty {
                RegistrationPrimaryButton(title: "Daftarkan Kebun", systemImage: "plus", action: onRegisterGarden)
                    .padding(.horizontal, 34)
                    .padding(.bottom, 2)
                    .padding(.top, 24)
                    .background { BottomBlurFade() }
            }
        }
    }
}
