import SwiftUI
import UIKit

/// A map with a dark fade at the top for a header. The header itself is `HeroToolbar`,
/// which screens can pin above their scroll view; `showsToolbar` keeps it inside the map instead.
struct MapHeroView<MapContent: View>: View {
    let title: String
    var topInset: CGFloat = 62
    var height: CGFloat = 380
    let onBack: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    /// When set, edit and delete stay visible but disabled, with this explanation in the menu.
    var lockedReason: String? = nil
    var showsToolbar = true
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
                if showsToolbar {
                    HeroToolbar(title: title, onBack: onBack, onEdit: onEdit, onDelete: onDelete,
                                lockedReason: lockedReason)
                        .padding(.top, topInset)
                }
            }
    }
}

/// Back button, title, and options menu. Over the map it is white on the map's dark fade;
/// once the content scrolls under it (`isOverContent`) it switches to a material bar with standard text.
struct HeroToolbar: View {
    let title: String
    var subtitle: String? = nil
    let onBack: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var lockedReason: String? = nil
    var isOverContent = false

    var body: some View {
        ScreenHeader(title: subtitle == nil ? title : "", systemImage: "chevron.left", onClose: onBack)
            .overlay(alignment: .leading) {
                if let subtitle {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.title2.bold()).lineLimit(1)
                        Text(subtitle).font(.caption).lineLimit(2)
                    }
                    .padding(.leading, 76)
                    .padding(.trailing, 64)
                    .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .trailing) {
                if onEdit != nil || onDelete != nil {
                    Menu {
                        if let lockedReason {
                            Text(lockedReason)
                        }
                        Section {
                            if let onEdit {
                                Button("Edit kebun", systemImage: "pencil", action: onEdit)
                            }
                            if let onDelete {
                                Button(role: .destructive, action: onDelete) {
                                    Label {
                                        Text("Hapus kebun")
                                    } icon: {
                                        // System menus tint template icons; a pre-coloured image keeps the trash red.
                                        Image(uiImage: UIImage(systemName: "trash")?
                                            .withTintColor(.systemRed, renderingMode: .alwaysOriginal) ?? UIImage())
                                    }
                                }
                            }
                        }
                        .disabled(lockedReason != nil)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    // Without this, menu icons take the app's green tint; destructive items stay red.
                    .tint(Color(uiColor: .label))
                    .accessibilityLabel("Opsi kebun")
                    .padding(.trailing, 12)
                }
            }
            .foregroundStyle(isOverContent ? Color.primary : Color.white)
            .environment(\.colorScheme, isOverContent ? .light : .dark)
            .animation(.easeOut(duration: 0.2), value: isOverContent)
    }
}

#Preview("Map Hero", traits: .sizeThatFitsLayout) {
    MapHeroView(title: "Belakang rumah", onBack: {}) {
        Image("CodedProfileMap").resizable().scaledToFill()
    }.frame(width: 402)
}
