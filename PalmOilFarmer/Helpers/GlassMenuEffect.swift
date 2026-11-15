
//
//  GlassMenuEffect.swift
//  Created by Hatami Sugandi on 13/11/26.
//

import SwiftUI



extension Animation {
   
    static let glassMenu: Animation = .bouncy(duration: 0.75, extraBounce: 0.02)
}


struct GlassMenu<Content: View, MenuLabel: View>: View {
    @Binding var isExpanded: Bool
    var alignment: Alignment = .topLeading
    var labelSize: CGSize = CGSize(width: 55, height: 55)
    var cornerRadius: CGFloat = 30
    var animation: Animation = .glassMenu
    @ViewBuilder var content: Content
    @ViewBuilder var label: MenuLabel

    var body: some View {
        ExpandableGlassMenu(
            alignment: alignment,
            progress: isExpanded ? 1 : 0,
            labelSize: labelSize,
            cornerRadius: cornerRadius
        ) {
            content
        } label: {
            Button {
                isExpanded = true
            } label: {
                label
                    .frame(width: labelSize.width, height: labelSize.height)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .animation(animation, value: isExpanded)
    }
}


struct GlassMenuRow: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .symbolVariant(.fill)
                    .frame(width: 45, height: 45)
                    .background(.background, in: .circle)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .fontWeight(.semibold)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                    }
                }
            }
            .padding(10)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}



extension View {
    
    func collapsesGlassMenu(_ isExpanded: Binding<Bool>) -> some View {
        contentShape(.rect)
            .onTapGesture { isExpanded.wrappedValue = false }
    }
}



struct ExpandableGlassMenu<Content: View, MenuLabel: View>: View, Animatable {
    var alignment: Alignment
    var progress: CGFloat
    var labelSize: CGSize
    var cornerRadius: CGFloat
    private let content: Content
    private let label: MenuLabel

    @State private var contentSize: CGSize = .zero

    init(
        alignment: Alignment = .topLeading,
        progress: CGFloat,
        labelSize: CGSize = CGSize(width: 55, height: 55),
        cornerRadius: CGFloat = 30,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> MenuLabel
    ) {
        self.alignment = alignment
        self.progress = progress
        self.labelSize = labelSize
        self.cornerRadius = cornerRadius
        self.content = content()
        self.label = label()
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GlassEffectContainer {
            let widthDiff = contentSize.width - labelSize.width
            let heightDiff = contentSize.height - labelSize.height

            ZStack(alignment: alignment) {
                content
                    .compositingGroup()
                    .scaleEffect(contentScale)
                    .blur(radius: 14 * blurProgress)
                    .opacity(contentOpacity)
                    .onGeometryChange(for: CGSize.self) {
                        $0.size
                    } action: { newValue in
                        contentSize = newValue
                    }
                    .fixedSize()
                    .frame(
                        width: labelSize.width + widthDiff * contentOpacity,
                        height: labelSize.height + heightDiff * contentOpacity
                    )
                    // Isi menu yang masih tersembunyi tidak boleh menangkap ketukan.
                    .allowsHitTesting(progress > 0.5)

                label
                    .compositingGroup()
                    .blur(radius: 14 * blurProgress)
                    .opacity(1 - labelOpacity)
                    .frame(width: labelSize.width, height: labelSize.height)
                    .allowsHitTesting(progress <= 0.5)
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: cornerRadius))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        }
        .scaleEffect(
            x: 1 - (blurProgress * 0.35),
            y: 1 + (blurProgress * 0.45),
            anchor: scaleAnchor
        )
        .offset(y: offset * blurProgress)
    }

    private var labelOpacity: CGFloat {
        min(progress / 0.35, 1)
    }

    private var contentOpacity: CGFloat {
        max(progress - 0.35, 0) / 0.65
    }

    private var contentScale: CGFloat {
        // Sebelum isi menu terukur, ukurannya masih nol: jangan membagi dengan nol.
        guard contentSize.width > 0, contentSize.height > 0 else { return 1 }
        let minAspectScale = min(labelSize.width / contentSize.width,
                                 labelSize.height / contentSize.height)
        return minAspectScale + (1 - minAspectScale) * progress
    }

    /// 0 → 1 → 0 saat progress bergerak 0 → 0,5 → 1.
    private var blurProgress: CGFloat {
        let value = progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5
        return max(value, 0)   // animasi bouncy bisa membuat progress sedikit di atas 1
    }

    private var offset: CGFloat {
        switch alignment {
        case .bottom, .bottomLeading, .bottomTrailing: -75
        case .top, .topLeading, .topTrailing: 75
        default: 0
        }
    }

    private var scaleAnchor: UnitPoint {
        switch alignment {
        case .bottomLeading: .bottomLeading
        case .bottom: .bottom
        case .bottomTrailing: .bottomTrailing
        case .topLeading: .topLeading
        case .top: .top
        case .topTrailing: .topTrailing
        case .leading: .leading
        case .trailing: .trailing
        default: .center
        }
    }
}



#if DEBUG
private struct GlassMenuEffectDemo: View {
    @State private var isMenuOpen = false

    var body: some View {
        List {
            Section("Preview") {
                Rectangle()
                    .foregroundStyle(.clear)
                    .background {
                        Image(.mappingSatelliteSource)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .collapsesGlassMenu($isMenuOpen)
                    }
                    .overlay {
                        GlassMenu(isExpanded: $isMenuOpen) {
                            VStack(alignment: .leading, spacing: 12) {
                                GlassMenuRow(systemImage: "paperplane", title: "Send",
                                             subtitle: "This is a sample text description") {
                                    isMenuOpen = false
                                }
                                GlassMenuRow(systemImage: "arrow.trianglehead.2.counterclockwise", title: "Swap",
                                             subtitle: "This is a sample text description") {
                                    isMenuOpen = false
                                }
                                GlassMenuRow(systemImage: "arrow.down", title: "Receive",
                                             subtitle: "This is a sample text description") {
                                    isMenuOpen = false
                                }
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(15)
                    }
                    .frame(height: 330)
            }
            .listRowInsets(EdgeInsets())

            Section("Properties") {
                Toggle("Menu terbuka", isOn: $isMenuOpen)
            }
        }
    }
}

#Preview("Glass menu") {
    GlassMenuEffectDemo()
}
#endif
