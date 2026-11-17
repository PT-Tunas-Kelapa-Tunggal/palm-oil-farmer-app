#if DEBUG
import SwiftUI

enum GardenProfileReferenceStep: Int {
    case fertilizer = 1
    case harvest = 2

    var title: String {
        self == .fertilizer ? "Riwayat pemupukan" : "Riwayat panen"
    }
    var message: String {
        self == .fertilizer
            ? "Riwayat pupuk membantu menentukan jenis dan jumlah pupuk yang tepat untuk kebun Anda."
            : "Riwayat panen menjadi dasar untuk memantau naik turunnya hasil kebun Anda."
    }
    var actionTitle: String {
        self == .fertilizer ? "Lengkapi riwayat pemupukan" : "Lengkapi riwayat panen"
    }
}

struct GardenProfileProgressReferenceView: View {
    let step: GardenProfileReferenceStep
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lengkapi profil kebun")
                .font(.headline)

            HStack(spacing: 0) {
                progressNode("point.topleft.down.to.point.bottomright.curvepath", index: 0)
                progressLine(completed: true)
                progressNode("bag.fill", index: 1)
                progressLine(completed: step == .harvest)
                progressNode("leaf.fill", index: 2)
            }
            .padding(.vertical, 16)
            .accessibilityLabel("Profil kebun, langkah \(step.rawValue + 1) dari 3")

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title).font(.title3.weight(.semibold))
                Text(step.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ProfileCalloutShape(pointerFraction: step == .fertilizer ? 0.5 : 0.96)
                    .fill(KropsTheme.surfaceCard)
            }

            Button(action: onContinue) {
                HStack {
                    Text(step.actionTitle).font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.subheadline)
                }
                .padding(16)
                .frame(minHeight: 52)
                .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func progressNode(_ symbol: String, index: Int) -> some View {
        Group {
            if index == 0 {
                GardenAreaIcon()
            } else {
                Image(systemName: symbol).font(.subheadline)
            }
        }
            .foregroundStyle(.white)
            .frame(width: 33, height: 33)
            .background(index <= step.rawValue ? KropsTheme.surfaceInverse : KropsTheme.separatorOpaque, in: Circle())
            .overlay {
                if index > step.rawValue {
                    Circle().fill(Color(uiColor: .systemGray3))
                }
            }
            .accessibilityHidden(true)
    }

    private func progressLine(completed: Bool) -> some View {
        Rectangle()
            .fill(completed ? KropsTheme.surfaceInverse : KropsTheme.separatorOpaque)
            .frame(height: 8)
    }
}

private struct ProfileCalloutShape: Shape {
    let pointerFraction: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            let radius: CGFloat = 24
            let x = min(max(rect.width * pointerFraction, 16), rect.width - 16)
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: x - 14, y: 0))
            path.addQuadCurve(to: CGPoint(x: x - 5, y: -6), control: CGPoint(x: x - 8, y: -3))
            path.addQuadCurve(to: CGPoint(x: x + 5, y: -6), control: CGPoint(x: x, y: -13))
            path.addQuadCurve(to: CGPoint(x: min(x + 14, rect.width), y: 0),
                              control: CGPoint(x: x + 8, y: -3))
            if x + 14 < rect.width - radius {
                path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
            }
            path.addQuadCurve(to: CGPoint(x: rect.width, y: radius),
                              control: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
            path.addQuadCurve(to: CGPoint(x: rect.width - radius, y: rect.height),
                              control: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: radius, y: rect.height))
            path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - radius),
                              control: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addQuadCurve(to: CGPoint(x: radius, y: 0), control: .zero)
            path.closeSubpath()
        }
    }
}

#Preview("Fertilizer Step", traits: .sizeThatFitsLayout) {
    GardenProfileProgressReferenceView(step: .fertilizer, onContinue: {})
        .frame(width: 402).background(KropsTheme.surfaceBackground)
}
#Preview("Harvest Step", traits: .sizeThatFitsLayout) {
    GardenProfileProgressReferenceView(step: .harvest, onContinue: {})
        .frame(width: 402).background(KropsTheme.surfaceBackground)
}

#endif
