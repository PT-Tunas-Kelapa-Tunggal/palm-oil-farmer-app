import SwiftUI

/// Titled input container for form fields.
struct RegistrationFormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.bold())
                .foregroundStyle(KropsTheme.labelSecondary)
                .padding(.horizontal, 8)
            content()
                .font(.title3)
                .frame(minHeight: 52)
                .padding(.horizontal, KropsTheme.Spacing.field)
                .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 8)
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
    .background(KropsTheme.surfaceCard)
}
#endif
