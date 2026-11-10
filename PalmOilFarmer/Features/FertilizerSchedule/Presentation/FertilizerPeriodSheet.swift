import SwiftUI

struct FertilizerPeriodSheet: View {
    let sheet: FertilizerSchedulePresentation.PeriodSheet
    let onClose: () -> Void
    let onSelectStep: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Text(sheet.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 52)
                HStack {
                    GardenProfileIconButton(symbol: "xmark", label: "Tutup", action: onClose)
                    Spacer()
                }
            }

            Text(sheet.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            FertilizerTimelineList(rows: sheet.rows, isCard: true, onSelectStep: onSelectStep)

            HStack {
                Text("Total pupuk").foregroundStyle(.secondary)
                Spacer()
                Text(sheet.total).fontWeight(.bold)
            }
            .font(.subheadline)
            .padding(.horizontal, 4)
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .fittedSheetHeight()
        .presentationDragIndicator(.hidden)
    }
}
