import SwiftUI

/// Profile layout only. Presentation and navigation belong to the screen and coordinator.
struct GardenProfileContentView: View {
    let garden: Garden
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    let currentReviewStatus: ReviewStatus?
    let isComplete: Bool
    let onBack: () -> Void
    let onEditGarden: () -> Void
    let onEditProfile: () -> Void
    let onReviewAction: () -> Void
    let onViewSummary: () -> Void
    let onViewReviewInformation: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    if showsHeader {
                        hero(topInset: geometry.safeAreaInsets.top)
                    } else {
                        map.frame(height: 201)
                    }
                    GardenMetricsView(garden: garden, metrics: metrics)
                        .padding(.horizontal, 18).padding(.top, showsHeader ? -31 : 16)
                    VStack(spacing: 16) {
                        if isComplete {
                            readyCard
                            Button(action: onViewSummary) {
                                HStack(spacing: 12) {
                                    Image(systemName: "leaf")
                                    Text("Lihat Profil Kebun").font(.body.weight(.medium))
                                    Spacer(minLength: 4)
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                                .padding(16).frame(minHeight: 53)
                                .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 24))
                            }
                            .buttonStyle(.plain)
                        } else {
                            GardenProfileCompletionCard(onComplete: onEditProfile)
                        }
                    }
                    .padding(16).padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: showsHeader ? .top : [])
        }
        .background(GardenProfileStyle.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var map: some View {
        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
    }

    private func hero(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Button(action: onBack) {
                    // The icon stays inside its 44 pt touch target at every text size.
                    Image(systemName: "chevron.left").font(.system(size: 22))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("Kembali")
                if isComplete {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(garden.name).font(.title.bold())
                        Text(garden.locationName).font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(garden.name).font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.top, 8)
                    Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.top, topInset + 8)
            // Let long names and accessibility text expand the map header naturally.
            Spacer(minLength: 160)
        }
        .frame(minHeight: 368)
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

    private var readyCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill").font(.largeTitle).padding(.top, 16)
                    .accessibilityHidden(true)
                VStack(spacing: 4) {
                    Text(currentReviewStatus == nil ? "Kebun Siap Ditinjau" : "Peninjauan Kebun").font(.title.bold())
                    Text(currentReviewStatus == nil
                         ? "Profil Kebun sudah Lengkap. Ajukan peninjauan untuk mengetahui kondisi seluruh kebun lebih cepat dan akurat"
                         : "Profil kebun sudah diajukan. Lihat perkembangan atau hasil peninjauan kebun Anda.")
                        .font(.body)
                }
                Button(action: onViewReviewInformation) {
                    HStack(spacing: 5) {
                        Text("Tentang Pengajuan Kebun")
                        Image(systemName: "info.circle")
                    }
                        .labelStyle(.titleAndIcon).font(.body).foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8).multilineTextAlignment(.center)
            GardenProfileActionButton(title: reviewTitle, symbol: currentReviewStatus == nil ? "paperplane.fill" : "chevron.right",
                                action: onReviewAction)
        }
        .padding(.horizontal, 16).padding(.vertical, 24)
        .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 28))
    }

    private var reviewTitle: String {
        switch currentReviewStatus {
        case nil: "Ajukan Sekarang"
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
