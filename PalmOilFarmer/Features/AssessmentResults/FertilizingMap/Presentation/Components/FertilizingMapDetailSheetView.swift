import SwiftUI

public struct FertilizingMapDetailSheetView: View {
    public let mode: AreaDivisionMode
    public let selectedFertilizer: FertilizerPeriodOption?
    public let isInPeriod: Bool
    public let totalZones: Int
    public let totalDoseKg: Double
    public let selectedZone: FertilizingZoneDetail?
    public let isMarkedDone: Bool
    public let onToggleDone: () -> Void

    public init(
        mode: AreaDivisionMode,
        selectedFertilizer: FertilizerPeriodOption?,
        isInPeriod: Bool,
        totalZones: Int,
        totalDoseKg: Double,
        selectedZone: FertilizingZoneDetail?,
        isMarkedDone: Bool,
        onToggleDone: @escaping () -> Void
    ) {
        self.mode = mode
        self.selectedFertilizer = selectedFertilizer
        self.isInPeriod = isInPeriod
        self.totalZones = totalZones
        self.totalDoseKg = totalDoseKg
        self.selectedZone = selectedZone
        self.isMarkedDone = isMarkedDone
        self.onToggleDone = onToggleDone
    }

    private var titleText: String {
        switch mode {
        case .perZona:
            if let selectedZone {
                return selectedZone.name
            }
            return "Total \(totalZones) zona"
        case .perPohon:
            return selectedFertilizer?.name ?? "Dolomit"
        case .wholeFarm:
            return "Dosis setiap pohon"
        }
    }

    private var doseText: String {
        switch mode {
        case .perZona:
            if let selectedZone {
                return "\(selectedZone.doseKg.formatted(.number.precision(.fractionLength(0...1)))) kg"
            }
            return selectedFertilizer?.totalDose ?? "\(totalDoseKg.formatted(.number.precision(.fractionLength(0...1)))) kg"
        case .perPohon:
            return selectedFertilizer?.perTreeDose ?? "3,5 kg"
        case .wholeFarm:
            return selectedFertilizer?.perTreeDose ?? "0,5 kg"
        }
    }

    public var body: some View {
        Group {
            if mode == .wholeFarm {
                wholeFarmDoseCard
            } else {
                standardDetailSheet
            }
        }
    }

    private var wholeFarmDoseCard: some View {
        VStack(spacing: 3) {
            Text("Dosis setiap pohon")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Text(doseText)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var standardDetailSheet: some View {
        VStack(spacing: 16) {
            // Grabber Handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Info Header Row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    if mode == .perZona && selectedZone != nil {
                        Text("Dosis anjuran zona")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                Spacer()

                Text(doseText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)

            // Action Button: Shown ONLY when in active period
            if isInPeriod {
                Button(action: onToggleDone) {
                    HStack(spacing: 8) {
                        if isMarkedDone {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.green)
                        }

                        Text(isMarkedDone ? "Sudah Dipupuk" : "Tandai Sudah Dipupuk")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isMarkedDone ? .white : .black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(isMarkedDone ? Color(white: 0.2) : Color.white)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 4)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255).opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
