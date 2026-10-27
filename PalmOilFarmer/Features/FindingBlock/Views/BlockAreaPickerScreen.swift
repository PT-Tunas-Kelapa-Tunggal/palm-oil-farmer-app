import SwiftUI

struct BlockAreaPickerScreen: View {
    let blocks: [GardenBlock]
    @Binding var selectedID: Int
    @State private var pendingID: Int
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    init(blocks: [GardenBlock], selectedID: Binding<Int>) {
        self.blocks = blocks
        _selectedID = selectedID
        _pendingID = State(initialValue: selectedID.wrappedValue)
    }

    private var filteredBlocks: [GardenBlock] {
        blocks.filter { query.isEmpty || $0.code.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Area Kebun", confirmationAction: {
                selectedID = pendingID
                dismiss()
            }, onClose: { dismiss() })
            TextField("Cari kode area", text: $query)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(KropsTheme.tertiaryFill, in: Capsule())
                .padding(.horizontal, 16)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredBlocks) { block in
                        Button { pendingID = block.id } label: {
                            HStack(spacing: 16) {
                                BlockAreaThumbnail(block: block)
                                    .frame(width: 68, height: 68)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text("Area " + block.code).font(.title3)
                                Spacer()
                                if pendingID == block.id {
                                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(pendingID == block.id ? .isSelected : [])
                    }
                    if filteredBlocks.isEmpty { ContentUnavailableView.search(text: query) }
                }
                .padding(16)
            }
        }
        .presentationDetents([.large])
    }
}
