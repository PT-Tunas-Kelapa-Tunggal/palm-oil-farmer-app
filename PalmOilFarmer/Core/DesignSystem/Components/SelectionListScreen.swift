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

#Preview("Selection List · Selected") {
    SelectionListScreen(title: "Pilihan", options: ["Pilihan pertama", "Pilihan kedua"],
                      selected: "Pilihan pertama",
                      footer: "Pilih opsi yang paling sesuai.",
                      onSelect: { _ in })
}
