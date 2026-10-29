import SwiftUI

struct FertilizerAllocationSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let period: FertilizerAllocationPeriod
    let areaID: String
    @Binding var selectedOptionIDs: [String: String]

    private var usesLargeLayout: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(period.title)
                    .font(.title3.weight(.bold))
                Text(period.dateRange)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let choices = period.choices, !choices.isEmpty {
                Text("Pilih satu jenis pupuk untuk setiap unsur hara.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                ForEach(choices) { choice in
                    choiceCard(choice)
                }
            } else {
                legacyLines
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private func choiceCard(_ choice: FertilizerAllocationChoice) -> some View {
        let selectionKey = "\(areaID)-\(choice.id)"
        let defaultOption = choice.options.first(where: \.isLowerCost) ?? choice.options.first
        let selectedID = selectedOptionIDs[selectionKey] ?? defaultOption?.id

        return VStack(alignment: .leading, spacing: 12) {
            Text(choice.title)
                .font(.title3.weight(.bold))
            ForEach(choice.options) { option in
                let isSelected = selectedID == option.id
                Button {
                    selectedOptionIDs[selectionKey] = option.id
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 5) {
                            optionHeading(option)
                            Text(option.dosage)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Total: \(option.total)")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: usesLargeLayout ? 96 : 88, alignment: .leading)
                    .background(
                        isSelected ? Color.accentColor.opacity(0.12) : KropsTheme.tertiaryFill,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.name), \(option.priceDescription), \(option.dosage)")
                .accessibilityValue(isSelected ? "Dipilih" : "Belum dipilih")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(14)
        .background(KropsTheme.tertiaryFill.opacity(0.55), in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func optionHeading(_ option: FertilizerAllocationOption) -> some View {
        if usesLargeLayout {
            VStack(alignment: .leading, spacing: 3) {
                Text(option.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(option.priceDescription)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(option.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(option.priceDescription)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var legacyLines: some View {
        VStack(spacing: 0) {
            ForEach(period.lines.indices, id: \.self) { index in
                let line = period.lines[index]
                VStack(alignment: .leading, spacing: 6) {
                    Text(line.name).font(.headline)
                    Text(line.dosage).font(.body.weight(.semibold))
                    Text(line.total).font(.body).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                .padding(.vertical, 10)
                if index < period.lines.count - 1 { Divider() }
            }
        }
        .padding(.horizontal, 16)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 22))
    }
}
