import SwiftUI

struct FertilizerCostTable: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let lines: [FertilizerCostLine]
    let total: String

    var body: some View {
        VStack(spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                HStack {
                    tableCell("Jenis pupuk", alignment: .leading)
                    tableCell("Jumlah (kg)", alignment: .center)
                    tableCell("Biaya", alignment: .trailing)
                }
                .fontWeight(.semibold)
                .background(Color(uiColor: .systemGray4).opacity(0.6))
            }
            ForEach(lines) { line in
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(line.name).font(.headline)
                        HistoryValueRow(title: "Jumlah (kg)", value: line.quantity)
                        HistoryValueRow(title: "Biaya", value: line.cost)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    Divider()
                } else {
                    HStack {
                        tableCell(line.name, alignment: .leading)
                        tableCell(line.quantity, alignment: .center)
                        tableCell(line.cost, alignment: .trailing)
                    }
                }
            }
            HStack {
                Text("Total")
                Spacer()
                Text(total)
            }
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
        }
        .font(.subheadline)
        .background(KropsTheme.tertiaryFill.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func tableCell(_ text: String, alignment: Alignment) -> some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(8)
            .frame(minHeight: 32)
    }
}
