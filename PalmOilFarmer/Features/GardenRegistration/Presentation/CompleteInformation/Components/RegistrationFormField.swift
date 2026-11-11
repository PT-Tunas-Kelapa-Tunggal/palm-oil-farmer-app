import SwiftUI

/// Titled input container for form fields.
struct RegistrationFormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.compact) {
            Text(title).font(.body.weight(.semibold)).foregroundStyle(.secondary)
            content()
                .font(KropsTheme.Typography.body)
                .frame(minHeight: 52)
                .padding(.horizontal, KropsTheme.Spacing.field)
                .background(KropsTheme.secondaryFill, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("Kolom formulir", traits: .sizeThatFitsLayout) {
    VStack(spacing: 0) {
        RegistrationFormField(title: "Nama Kebun") {
            Text("Pinggir jalan").frame(maxWidth: .infinity, alignment: .leading)
        }
        RegistrationFormField(title: "Tahun Tanam") {
            Text("Pilih tahun tanam").foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding(16)
    .frame(width: 402)
    .background(RegistrationStyle.surface)
}
#endif
