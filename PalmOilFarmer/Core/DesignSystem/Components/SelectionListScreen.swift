import SwiftUI

struct SelectionListScreen: View {
    let title: String
    let options: [String]
    let selected: String?
    let footer: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: title, systemImage: "chevron.left", onClose: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    VStack(spacing: 0) {
                        ForEach(options.indices, id: \.self) { index in
                            Button {
                                onSelect(options[index])
                                dismiss()
                            } label: {
                                HStack {
                                    Text(options[index])
                                    Spacer()
                                    if selected == options[index] {
                                        Image(systemName: "checkmark").foregroundStyle(.secondary)
                                    }
                                }
                                .font(.body)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selected == options[index] ? .isSelected : [])
                            if index < options.count - 1 { Divider().padding(.horizontal, 16) }
                        }
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 24))
                    Text(footer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 13)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("Jenis Tanah · Selected") {
    SelectionListScreen(title: "Jenis Tanah", options: SoilType.allCases.map(\.displayName),
                      selected: "Tanah Mineral",
                      footer: "Jenis tanah membantu kami memahami kondisi kebun Anda. Pilih yang paling mendekati.",
                      onSelect: { _ in })
}
