import SwiftUI

struct MapHeroView<MapContent: View>: View {
    let title: String
    var topInset: CGFloat = 62
    var height: CGFloat = 380
    let onBack: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @ViewBuilder let map: () -> MapContent

    var body: some View {
        map()
            .frame(height: height)
            .clipped()
            .overlay(alignment: .top) {
                Rectangle().fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(height: 185)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                ScreenHeader(title: title, systemImage: "chevron.left", buttonSize: 44, height: 68, onClose: onBack)
                    .foregroundStyle(.white)
                    .environment(\.colorScheme, .dark)
                    .padding(.top, topInset)
            }
            .overlay(alignment: .topTrailing) {
                if onEdit != nil || onDelete != nil {
                    Menu {
                        if let onEdit {
                            Button("Edit kebun", systemImage: "pencil", action: onEdit)
                        }
                        if let onDelete {
                            Button("Hapus kebun", systemImage: "trash", role: .destructive, action: onDelete)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .foregroundStyle(.white)
                    .environment(\.colorScheme, .dark)
                    .accessibilityLabel("Opsi kebun")
                    .padding(.top, topInset + 12)
                    .padding(.trailing, 12)
                }
            }
    }
}

#Preview("Map Hero", traits: .sizeThatFitsLayout) {
    MapHeroView(title: "Belakang rumah", onBack: {}) {
        Image("CodedProfileMap").resizable().scaledToFill()
    }.frame(width: 402)
}
