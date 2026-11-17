import SwiftUI

struct GardenCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let garden: Garden
    var referenceImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil

    private var displayMetrics: GardenDisplayMetrics {
        metrics ?? GardenDisplayMetrics(boundary: garden.boundary)
    }

    /// Supplied when a dated fertilizer plan is available; never inferred from sample report text.
    var fertilizerSchedule: String? = nil

    var body: some View {
        VStack(spacing: -24) {
            VStack(spacing: 0) {
                GardenMapView(boundary: garden.boundary, referenceImage: referenceImage)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    Text(garden.name).font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                        : AnyLayout(HStackLayout(spacing: 4))
                    layout {
                        VStack(alignment: .leading, spacing: 6) {
                            metric(displayMetrics.area, symbol: "area")
                            metric(garden.soilType.rawValue, symbol: "leaf")
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            metric(displayMetrics.perimeter, symbol: "square.dashed")
                            metric(String(garden.plantingYear), symbol: "calendar")
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.font(.footnote)
                }.frame(minHeight: 82).padding(10)
                if fertilizerSchedule == nil {
                    VStack(spacing: 0) {
                        Divider()
                        GardenStageLabel(stage: garden.stage, visitDate: garden.review?.visitDate)
                    }.padding(.horizontal, 10).padding(.top, 4).padding(.bottom, 2)
                }
            }
            .padding(8)
            .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 24))
            .zIndex(1)
            if let fertilizerSchedule {
                HStack(spacing: 12) {
                    Image(systemName: "calendar").font(.body)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Jadwal Pemupukan").font(.footnote).opacity(0.75)
                        Text(fertilizerSchedule).font(.body.weight(.semibold))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.body).opacity(0.65)
                }
                .foregroundStyle(.white).padding(.horizontal, 16).padding(.top, 36).padding(.bottom, 16)
                .background(Color(red: 0.075, green: 0.49, blue: 0.23), in: RoundedRectangle(cornerRadius: 32))
                .padding(.horizontal, 8)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private func metric(_ value: String, symbol: String) -> some View {
        HStack(spacing: 6) {
            Group {
                if symbol == "area" { GardenAreaIcon() }
                else { Image(systemName: symbol) }
            }.font(.system(size: 13)).foregroundStyle(GardenProfileStyle.accent).frame(width: 16)
            Text(value)
        }
    }
}

struct GardenStageLabel: View {
    let stage: GardenStage
    var visitDate: Date? = nil

    private var content: (text: String, symbol: String) {
        switch stage {
        case .incomplete: ("Lengkapi profil kebun", "doc.text")
        case .readyForReview: ("Ajukan peninjauan", "doc.text")
        case .inReview(.scheduled):
            (visitDate.map { "Kunjungan " + $0.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "id_ID"))) }
                ?? "Kunjungan petugas dijadwalkan", "clock")
        case .inReview: ("Dalam proses peninjauan", "clock")
        case .results(let downloaded):
            (downloaded ? "Lihat hasil peninjauan" : "Unduh hasil peninjauan", "arrow.down")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: content.symbol).font(.system(size: 16)).foregroundStyle(GardenProfileStyle.accent).frame(width: 16)
            Text(content.text).frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Garden Card", traits: .sizeThatFitsLayout) {
    GardenCard(garden: GardenPreviewData.garden, referenceImage: "GardenCardMap",
               metrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"))
        .padding(16)
        .frame(width: 402)
        .background(KropsTheme.background)
}
#endif
