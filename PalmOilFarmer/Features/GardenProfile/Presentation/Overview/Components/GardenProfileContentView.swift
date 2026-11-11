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

    private var assessmentStatus: AssessmentReviewStatusCard.Status? {
        if let assessmentResultsState { return .results(assessmentResultsState) }
        if let assessmentContactName { return .inReview(contactName: assessmentContactName) }
        return nil
    }

    private var usesLightAssessmentLayout: Bool {
        colorScheme == .light && assessmentStatus != nil
    }

    var body: some View {
        let assessmentStatus = self.assessmentStatus
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    if showsHeader {
                        hero(topInset: geometry.safeAreaInsets.top)
                    } else {
                        map.frame(height: 201)
                    }
                    if usesLightAssessmentLayout, let assessmentStatus {
                        VStack(spacing: -32) {
                            GardenMetricsView(garden: garden, metrics: metrics, usesAssessmentBand: true)
                            assessmentCard(assessmentStatus)
                                .zIndex(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, showsHeader ? -40 : 16)

                        dataSection
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 48)
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
                            } else if isComplete {
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
            .ignoresSafeArea(edges: showsHeader ? .top : [])
        }
        .background((usesLightAssessmentLayout ? AssessmentPalette.lightBackground : GardenProfileStyle.background).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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

    private func hero(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Button(action: onBack) {
                    // The icon stays inside its 44 pt touch target at every text size.
                    Image(systemName: "chevron.left").font(.system(size: 22)).foregroundStyle(Color(uiColor: .label))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("Kembali")
                VStack(spacing: 0) {
                    Text(garden.name).font(.headline)
                    Text(garden.locationName).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                Menu {
                    Button("Ubah data kebun", systemImage: "pencil", action: onEditGarden)
                    if let onDelete { Button("Hapus kebun", systemImage: "trash", role: .destructive, action: onDelete) }
                } label: {
                    Image(systemName: "ellipsis").font(.title2).foregroundStyle(Color(uiColor: .label)).frame(width: 44, height: 44)
                }
                .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("Pilihan kebun")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.top, topInset)
            // Let long names and accessibility text expand the map header naturally.
            Spacer(minLength: 160)
        }
        .frame(minHeight: 360)
        .background {
            map.overlay(alignment: .top) {
                // Satellite imagery needs a dark scrim for readable white map labels.
                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)
            }
        }
        .contextMenu {
            Button("Ubah data kebun", systemImage: "pencil", action: onEditGarden)
            if let onDelete { Button("Hapus kebun", systemImage: "trash", role: .destructive, action: onDelete) }
        }
    }

    private var dataSection: some View {
        VStack(spacing: 8) {
            if profileJustSaved {
                Label("Profil kebun baru saja disimpan", systemImage: "sparkles")
                    .font(.caption).foregroundStyle(GardenProfileStyle.accent)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 14).padding(.top, 10)
            }
            GardenProfileSectionHeader(title: "Data Kebun", message: "Data yang Anda isi dan menjadi dasar hasil peninjauan.")
                .padding(.top, 8)
            dataRow("Identitas Kebun", subtitle: "Lokasi, luas, tahun tanam, jenis tanah", symbol: "square.dashed.inset.filled", action: onEditGarden)
            dataRow("Riwayat Panen dan Pemupukan", subtitle: "Dasar perhitungan kondisi hara", symbol: "doc.text", action: onViewSummary)
        }
        .foregroundStyle(usesLightAssessmentLayout ? AssessmentPalette.ink : Color.primary)
        .padding(profileJustSaved ? 4 : 0)
        .background(profileJustSaved ? GardenProfileStyle.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 24))
    }

    private func dataRow(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.subheadline).foregroundStyle(.secondary)
                    .frame(width: 36, height: 36).background(Color(uiColor: .tertiarySystemFill), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.tertiary)
            }
            .padding(16).frame(minHeight: 76)
            .background(usesLightAssessmentLayout ? .white : GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 24))
        }.buttonStyle(.plain)
    }

    private var readyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 36))
                .foregroundStyle(GardenProfileStyle.accent).frame(height: 41).accessibilityHidden(true)
            Text(currentReviewStatus == nil ? "Kebun Siap Ditinjau" : "Peninjauan Kebun").font(.title2.bold())
            Text(currentReviewStatus == nil
                 ? "Profil kebun sudah lengkap. Ajukan peninjauan agar petugas memeriksa seluruh pohon di kebun Anda dan memberi rekomendasi pupuk yang lebih tepat."
                 : "Profil kebun sudah diajukan. Lihat perkembangan atau hasil peninjauan kebun Anda.")
                .font(.body).foregroundStyle(.secondary)
            Button(action: onViewReviewInformation) {
                HStack(spacing: 4) {
                    Text("Tentang Peninjauan Kebun")
                    Image(systemName: "info.circle")
                }.font(.subheadline).foregroundStyle(GardenProfileStyle.accent).padding(.vertical, 4)
            }.buttonStyle(.plain)
            GardenProfileActionButton(title: reviewTitle, action: onReviewAction)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 20)
        .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 24))
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
