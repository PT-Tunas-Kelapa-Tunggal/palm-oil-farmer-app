#if DEBUG
import SwiftUI

/// A small visual contract for shared controls. Keep business data out of this catalog.
struct DesignSystemCatalog: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KropsTheme.Spacing.section) {
                Text("Komponen Krops").font(.title2.bold())
                PrimaryActionButton(title: "Lanjut", action: {})
                PrimaryActionButton(title: "Simpan", action: {}).disabled(true)
                FormSelectionRow(title: "Pilihan", placeholder: "Pilih opsi",
                                 value: nil, action: {})
                FormSelectionRow(title: "Pilihan", placeholder: "Pilih opsi",
                                 value: "Contoh pilihan dengan teks yang lebih panjang", action: {})
                Text("Teks pendukung").font(KropsTheme.Typography.caption)
                    .foregroundStyle(KropsTheme.secondaryText)
            }
            .padding(KropsTheme.Spacing.screen)
        }
        .background(KropsTheme.background)
    }
}

#Preview("Catalog · Light") {
    DesignSystemCatalog().preferredColorScheme(.light)
}

#Preview("Catalog · Dark") {
    DesignSystemCatalog().preferredColorScheme(.dark)
}

#Preview("Catalog · Accessibility") {
    DesignSystemCatalog().dynamicTypeSize(.accessibility3)
}
#endif
