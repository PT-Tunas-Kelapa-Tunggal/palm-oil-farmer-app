import SwiftUI

/// Layout of the "Profil Kebun" screen only (map header, metrics, cards).
struct GardenProfileContentView: View {
    let garden: Garden
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    var profileJustSaved = false
    let currentReviewStatus: ReviewStatus?
    let isComplete: Bool
    let onBack: () -> Void
    let onEditGarden: () -> Void
    let onEditProfile: () -> Void
    let onReviewAction: () -> Void
    let onViewSummary: () -> Void
    let onViewReviewInformation: () -> Void
    var onDelete: (() -> Void)? = nil
    var assessmentContactName: String? = nil
    var assessmentResultsState: AssessmentResultsViewModel.State? = nil
    var assessmentCompletedAt: Date? = nil
    var assessmentResultByteCount: Int64? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAtScrollTop = true
    @State private var refreshPullDistance: CGFloat = 0

    private let heroHeight: CGFloat = 360

    private var assessmentStatus: AssessmentReviewStatusCard.Status? {
        if let assessmentResultsState { return .results(assessmentResultsState) }
        if currentReviewStatus == .completed {
            return .finished(completedAt: assessmentCompletedAt, byteCount: assessmentResultByteCount)
        }
        if let assessmentContactName { return .inReview(contactName: assessmentContactName) }
        return nil
    }

    private var usesLightAssessmentLayout: Bool {
        colorScheme == .light
    }

    var body: some View {
        let assessmentStatus = self.assessmentStatus
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if showsHeader {
                    heroBackground(height: heroHeight + refreshPullDistance)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        if showsHeader {
                            Color.clear.frame(height: heroHeight)
                        } else {
                            map.frame(height: 201)
                        }
                    if usesLightAssessmentLayout {
                        VStack(spacing: -32) {
                            GardenMetricsView(garden: garden, metrics: metrics, usesAssessmentBand: true)
                            Group {
                                if let assessmentStatus {
                                    assessmentCard(assessmentStatus)
                                } else if isComplete && currentReviewStatus == nil {
                                    lightReadyCard
                                } else if !isComplete {
                                    lightCompletionCard
                                } else {
                                    readyCard
                                }
                            }
                            .zIndex(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, showsHeader ? -40 : 16)

                        if isComplete || assessmentStatus != nil {
                            dataSection
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 48)
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    } else {
                        GardenMetricsView(garden: garden, metrics: metrics)
                            .padding(.horizontal, 16)
                            .padding(.top, showsHeader ? -37 : 16)

                        VStack(spacing: 8) {
                            if let assessmentStatus {
                                assessmentCard(assessmentStatus)
                                if assessmentStatus.phase == .inReview {
                                    dataRow("Lihat Profil Kebun", subtitle: "Riwayat panen dan pemupukan",
                                            symbol: "leaf", action: onViewSummary)
                                        .transition(.opacity)
                                } else {
                                    dataSection
                                        .transition(.opacity)
                                }
                            } else if isComplete || currentReviewStatus != nil {
                                readyCard
                                dataSection
                            } else {
                                GardenProfileCompletionCard(onComplete: onEditProfile)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 48)
                    }
                    }
                    .animation(reduceMotion || assessmentResultsState == nil ? nil : .smooth(duration: 0.35),
                               value: assessmentStatus?.phase)
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { scrollGeometry in
                    scrollGeometry.contentOffset.y + scrollGeometry.contentInsets.top
                } action: { _, offset in
                    isAtScrollTop = offset < 48
                    refreshPullDistance = showsHeader ? max(0, -offset) : 0
                }

                if showsHeader && isAtScrollTop {
                    heroNavigation(topInset: geometry.safeAreaInsets.top)
                }
            }
            .ignoresSafeArea(edges: showsHeader ? .top : [])
        }
        .background(KropsTheme.surfaceBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .navigationTitle(isAtScrollTop ? "" : garden.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !isAtScrollTop {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                    }
                    .tint(.white)
                    .accessibilityLabel("Kembali")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !isAtScrollTop {
                    Menu {
                        Button("Ubah data kebun", systemImage: "pencil", action: onEditGarden)
                        if let onDelete {
                            Button("Hapus kebun", systemImage: "trash", role: .destructive, action: onDelete)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .tint(.white)
                    .accessibilityLabel("Pilihan kebun")
                }
            }
        }
        .toolbarBackground(Color.black.opacity(0.78), for: .navigationBar)
        .toolbarBackground(isAtScrollTop ? .hidden : .visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func assessmentCard(_ status: AssessmentReviewStatusCard.Status) -> some View {
        AssessmentReviewStatusCard(
            status: status,
            completedAt: assessmentCompletedAt,
            expectedByteCount: assessmentResultByteCount,
            onAction: onReviewAction
        )
    }

    private var map: some View {
        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
    }

    private func heroNavigation(topInset: CGFloat) -> some View {
        HStack(alignment: .center) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Spacer()

            VStack(spacing: 2) {
                Text(garden.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(garden.locationName)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)

            Spacer()

            Menu {
                Button("Ubah data kebun", systemImage: "pencil", action: onEditGarden)
                if let onDelete {
                    Button("Hapus kebun", systemImage: "trash", role: .destructive, action: onDelete)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Pilihan kebun")
        }
        .padding(.horizontal, 16)
        .padding(.top, max(topInset, 60))
    }

    private func heroBackground(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Keep the MapKit viewport fixed while revealing more of it during a pull.
            map
                .frame(maxWidth: .infinity)
                .frame(height: 720)
                .offset(y: -180)
                .frame(height: height, alignment: .top)
                .clipped()

            LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: height)
                .allowsHitTesting(false)
        }
        .frame(height: height)
        .clipped()
        .contextMenu {
            Button("Ubah data kebun", systemImage: "pencil", action: onEditGarden)
            if let onDelete { Button("Hapus kebun", systemImage: "trash", role: .destructive, action: onDelete) }
        }
    }

    private var dataSection: some View {
        VStack(spacing: 8) {
            if profileJustSaved {
                Label("Profil kebun baru saja disimpan", systemImage: "sparkles")
                    .font(.caption).foregroundStyle(KropsTheme.accentPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 14).padding(.top, 10)
            }
            GardenProfileSectionHeader(title: "Data Kebun", message: "Data yang Anda isi dan menjadi dasar hasil peninjauan.")
                .padding(.top, 8)
            dataRow("Identitas Kebun", subtitle: "Lokasi, luas, tahun tanam, jenis tanah", symbol: "square.dashed.inset.filled", action: onEditGarden)
            dataRow("Riwayat Panen dan Pemupukan", subtitle: "Dasar perhitungan kondisi hara", symbol: "doc.text", action: onViewSummary)
        }
        .foregroundStyle(KropsTheme.labelPrimary)
        .padding(profileJustSaved ? 4 : 0)
        .background(profileJustSaved ? KropsTheme.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 24))
    }

    private func dataRow(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.subheadline).foregroundStyle(.secondary)
                    .frame(width: 36, height: 36).background(KropsTheme.fillBlack8, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.tertiary)
            }
            .padding(16).frame(minHeight: 76)
            .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 24))
        }.buttonStyle(.plain)
    }

    private var readyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 36))
                .foregroundStyle(KropsTheme.accentHero).frame(height: 41).accessibilityHidden(true)
            Text(currentReviewStatus == nil ? "Kebun Siap Ditinjau" : "Peninjauan Kebun").font(.title2.bold())
            Text(currentReviewStatus == nil
                 ? "Profil kebun sudah lengkap. Ajukan peninjauan agar petugas memeriksa seluruh pohon di kebun Anda dan memberi rekomendasi pupuk yang lebih tepat."
                 : "Profil kebun sudah diajukan. Lihat perkembangan atau hasil peninjauan kebun Anda.")
                .font(.body).foregroundStyle(.secondary)
            Button(action: onViewReviewInformation) {
                HStack(spacing: 4) {
                    Text("Tentang Peninjauan Kebun")
                    Image(systemName: "info.circle").foregroundStyle(KropsTheme.accentHero)
                }.font(.subheadline).foregroundStyle(KropsTheme.labelPrimary).padding(.vertical, 4)
            }.buttonStyle(.plain)
            GardenProfileActionButton(
                title: reviewTitle,
                action: onReviewAction
            )
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 20)
        .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 24))
    }

    private var lightReadyCard: some View {
        AssessmentGardenStatusCard {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(KropsTheme.accentHero)
                .frame(height: 44)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Kebun Siap Ditinjau")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Profil kebun sudah lengkap. Ajukan peninjauan agar petugas memeriksa seluruh pohon di kebun Anda dan memberi rekomendasi pupuk yang lebih tepat.")
                    .font(.body)
                    .foregroundStyle(KropsTheme.labelSecondary)
            }

            Button(action: onViewReviewInformation) {
                HStack(spacing: 5) {
                    Text("Tentang Peninjauan Kebun")
                    Image(systemName: "info.circle")
                        .foregroundStyle(KropsTheme.accentHero)
                }
                .font(.subheadline)
                .foregroundStyle(KropsTheme.labelPrimary)
            }
            .buttonStyle(.plain)
        } actions: {
            Button(action: onReviewAction) {
                Text("Ajukan Peninjauan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .glassEffect(.regular.tint(KropsTheme.surfaceInverse).interactive(), in: Capsule())
        }
    }

    private var lightCompletionCard: some View {
        AssessmentGardenStatusCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lengkapi profil kebun")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Isi riwayat panen dan pemupukan agar hasil peninjauan lebih sesuai dengan kebun Anda.")
                        .font(.body)
                        .foregroundStyle(KropsTheme.labelSecondary)
                }
                completionExplanation(
                    "Riwayat Panen",
                    message: "Membantu memperkirakan kebutuhan kebun dari hasil panen yang sudah didapat.",
                    symbol: "chart.xyaxis.line"
                )
                completionExplanation(
                    "Riwayat Pemupukan",
                    message: "Menjadi pembanding antara pupuk yang sudah diberikan dan kebutuhan kebun.",
                    symbol: "leaf"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        } actions: {
            Button(action: currentReviewStatus == nil ? onEditProfile : onReviewAction) {
                Text(currentReviewStatus == nil ? "Lengkapi Profil Kebun" : "Lihat Status Peninjauan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .glassEffect(.regular.tint(KropsTheme.surfaceInverse).interactive(), in: Capsule())
        }
    }

    private func completionExplanation(_ title: String, message: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(KropsTheme.accentHero)
                .frame(width: 36, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(KropsTheme.labelSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewTitle: String {
        switch currentReviewStatus {
        case nil: "Ajukan Peninjauan"
        case .completed: "Lihat hasil peninjauan"
        default: "Lihat status peninjauan"
        }
    }
}

#if DEBUG
#Preview("Profil kebun · Belum lengkap") {
    GardenProfileCanvasFixtures.content(complete: false)
}
#Preview("Profil kebun · Siap ditinjau") {
    GardenProfileCanvasFixtures.content(complete: true)
}
#endif
