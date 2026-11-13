import SwiftUI

/// The six states drawn in Sketch (Pemupukan / Mode Pemupukan / …).
enum SpreaderModePanelState: Equatable {
    case notConnected, searching, found, ready, dispensing, disconnected

    init(_ spreader: SpreaderBLEManager) {
        switch spreader.connection {
        case .ready:
            self = spreader.isRunning ? .dispensing : .ready
        case .scanning:
            self = spreader.discovered.isEmpty ? .searching : .found
        case .connecting:
            // Picking from the list keeps the list visible; a reconnect shows the search animation.
            self = spreader.discovered.contains { $0.id == spreader.connectingID } ? .found : .searching
        case .disconnected:
            self = .disconnected
        case .idle, .notFound, .bluetoothOff, .unauthorized, .unsupported:
            self = .notConnected
        }
    }
}

/// Bottom panel: device row, zone and dose, then the state-specific action.
struct SpreaderModePanel: View {
    let spreader: SpreaderBLEManager
    let zoneID: Int?
    let plan: SpreaderZonePlan?
    let fertilizedTrees: Int
    /// Clock from the screen's TimelineView, for the dispensing progress ring.
    let now: Date
    let onDispense: () -> Void

    private var state: SpreaderModePanelState { SpreaderModePanelState(spreader) }

    var body: some View {
        VStack(spacing: 20) {
            deviceRow
            statsRow
            main
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.25), value: state)
            footer
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16))
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 26, trailing: 8))
        .frame(maxWidth: .infinity)
        .background(SpreaderPalette.panel,
                    in: UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32))
        .foregroundStyle(SpreaderPalette.ink)
    }

    // MARK: Rows

    private var deviceRow: some View {
        HStack(spacing: 12) {
            SpreaderIconBadge(isBrand: state == .ready || state == .dispensing,
                                 slashed: state == .disconnected)
            VStack(alignment: .leading, spacing: 0) {
                Text(deviceTitle).font(.headline)
                Text(deviceSubtitle)
                    .font(.footnote)
                    .foregroundStyle(SpreaderPalette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var deviceTitle: String {
        switch state {
        case .notConnected, .searching:
            return spreader.connection == .connecting ? "Menghubungkan ulang" : "Alat belum terhubung"
        case .found:
            return "\(spreader.discovered.count) alat ditemukan"
        case .ready, .dispensing:
            return SpreaderFormat.headerName(spreader.deviceName ?? "Alat pemupuk")
        case .disconnected:
            return "Koneksi alat terputus"
        }
    }

    private var deviceSubtitle: String {
        switch state {
        case .notConnected:
            return spreader.message ?? "Pastikan alat menyala dan dekat dengan iPhone"
        case .searching:
            return "Pastikan alat menyala dan dekat dengan iPhone"
        case .found:
            return spreader.isScanning ? "Masih mencari alat lain di sekitar" : "Pilih alat untuk dihubungkan"
        case .ready, .dispensing:
            return "Terhubung lewat Bluetooth"
        case .disconnected:
            return spreader.message ?? "Alat berhenti otomatis. Dekatkan iPhone ke alat."
        }
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            stat(label: "Zona saat ini", value: zoneID.map { "Zona \($0)" } ?? "–")
            stat(label: "Dosis per pohon", value: plan.map { SpreaderFormat.kilograms($0.dosePerTreeKg) } ?? "–")
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.footnote).foregroundStyle(SpreaderPalette.inkSecondary)
            Text(value).font(.title.weight(.bold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Main area

    @ViewBuilder
    private var main: some View {
        switch state {
        case .notConnected:
            RoundActionButton(kind: .light(title: "Hubungkan Alat", hint: "Cari alat lewat Bluetooth", slashed: false)) {
                spreader.startScan()
            }
        case .searching:
            SearchingCard(title: spreader.connection == .connecting ? "Menghubungkan ke alat" : "Mencari alat pemupuk")
        case .found:
            DeviceList(spreader: spreader)
        case .ready:
            RoundActionButton(kind: .dispense, action: onDispense)
                .disabled(zoneID == nil || plan == nil)
        case .dispensing:
            RoundActionButton(kind: .dispensing(progress: spreader.run?.progress(at: now) ?? 0)) {
                spreader.stop()
            }
        case .disconnected:
            RoundActionButton(kind: .light(title: "Hubungkan Ulang", hint: nil, slashed: true)) {
                spreader.reconnect()
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch state {
        case .notConnected:
            VStack(spacing: 2) {
                Text("Alat belum terhubung").font(.subheadline.weight(.semibold))
                Text("Nyalakan alat pemupuk di dekat Anda")
                    .font(.footnote).foregroundStyle(SpreaderPalette.inkSecondary)
            }
            .multilineTextAlignment(.center)
        case .ready, .dispensing, .disconnected:
            if state == .ready, let message = spreader.message {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(SpreaderPalette.brandDeep)
                    .multilineTextAlignment(.center)
            } else if zoneID == nil {
                Text("Masuk ke salah satu zona untuk mulai memupuk")
                    .font(.footnote)
                    .foregroundStyle(SpreaderPalette.inkSecondary)
                    .multilineTextAlignment(.center)
            } else if let zoneID, let plan {
                Text("\(fertilizedTrees) dari \(plan.treeCount) pohon di Zona \(zoneID) sudah dipupuk")
                    .font(.footnote)
                    .foregroundStyle(SpreaderPalette.inkSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
            }
        case .searching, .found:
            EmptyView()
        }
    }
}

// MARK: - Round button (Dispense Button: 256 ring, 232 fill)

private struct RoundActionButton: View {
    enum Kind {
        case light(title: String, hint: String?, slashed: Bool)
        case dispense
        case dispensing(progress: Double)
    }

    let kind: Kind
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(ringColor)
                if case .dispensing(let progress) = kind {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(SpreaderPalette.brand.opacity(0.55),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(3)
                        .animation(.linear(duration: 0.5), value: progress)
                }
                fill
                    .frame(width: 232, height: 232)
                    .overlay { label }
            }
            .frame(width: 256, height: 256)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(accessibilityText)
    }

    private var ringColor: Color {
        switch kind {
        case .light: SpreaderPalette.ink.opacity(0.04)
        case .dispense: SpreaderPalette.ink.opacity(0.08)
        case .dispensing: SpreaderPalette.brandSoft
        }
    }

    @ViewBuilder
    private var fill: some View {
        switch kind {
        case .light:
            Circle().fill(.white)
                .overlay(Circle().stroke(SpreaderPalette.ink.opacity(0.12), lineWidth: 1.5))
                .shadow(color: SpreaderPalette.ink.opacity(0.12), radius: 10, y: 8)
        case .dispense:
            Circle().fill(LinearGradient(colors: [SpreaderPalette.darkTop, SpreaderPalette.ink],
                                         startPoint: .top, endPoint: .bottom))
                .shadow(color: SpreaderPalette.ink.opacity(0.35), radius: 12, y: 14)
        case .dispensing:
            Circle().fill(LinearGradient(colors: [SpreaderPalette.brand, SpreaderPalette.brandDeep],
                                         startPoint: .top, endPoint: .bottom))
                .shadow(color: SpreaderPalette.brandDeep.opacity(0.25), radius: 5, y: 4)
        }
    }

    @ViewBuilder
    private var label: some View {
        switch kind {
        case .light(let title, let hint, let slashed):
            VStack(spacing: 6) {
                BluetoothGlyph(slashed: slashed).frame(height: 38).frame(height: 48)
                Text(title).font(.title2.weight(.bold)).foregroundStyle(SpreaderPalette.ink)
                if let hint {
                    Text(hint).font(.footnote).foregroundStyle(SpreaderPalette.inkSecondary)
                }
            }
        case .dispense:
            VStack(spacing: 6) {
                Image(systemName: "arrow.down.to.line.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(SpreaderPalette.brand)
                    .frame(height: 48)
                Text("Keluarkan Pupuk").font(.title2.weight(.bold)).foregroundStyle(.white)
            }
        case .dispensing:
            VStack(spacing: 6) {
                Image(systemName: "arrow.down.to.line.circle")
                    .font(.system(size: 40))
                    .symbolEffect(.pulse)
                    .frame(height: 48)
                Text("Pupuk Keluar").font(.title2.weight(.bold))
                Text("Ketuk untuk berhenti").font(.footnote).opacity(0.85)
            }
            .foregroundStyle(.white)
        }
    }

    private var accessibilityText: String {
        switch kind {
        case .light(let title, _, _): title
        case .dispense: "Keluarkan pupuk untuk satu pohon"
        case .dispensing: "Pupuk keluar. Ketuk untuk berhenti"
        }
    }
}

// MARK: - Searching (Search Indicator: 354×316 card, pulsing rings)

private struct SearchingCard: View {
    let title: String
    @State private var pulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().fill(SpreaderPalette.brandSoft.opacity(0.35)).frame(width: 132, height: 132)
                    .scaleEffect(pulsing ? 1.08 : 0.9)
                Circle().fill(SpreaderPalette.brandSoft.opacity(0.6)).frame(width: 104, height: 104)
                    .scaleEffect(pulsing ? 1.05 : 0.94)
                Circle().fill(SpreaderPalette.brandSoft).frame(width: 76, height: 76)
                Circle()
                    .fill(LinearGradient(colors: [SpreaderPalette.darkTop, SpreaderPalette.ink],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 52, height: 52)
                    .shadow(color: SpreaderPalette.ink.opacity(0.25), radius: 5, y: 6)
                    .overlay { BluetoothGlyph(color: SpreaderPalette.brand).frame(height: 22) }
            }
            .frame(width: 140, height: 140)
            VStack(spacing: 2) {
                Text(title).font(.headline)
                Text("Biasanya hanya butuh beberapa detik")
                    .font(.footnote).foregroundStyle(SpreaderPalette.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 316)
        .background(SpreaderPalette.searchCard, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulsing = true }
        }
    }
}

// MARK: - Device list (Found)

private struct DeviceList: View {
    let spreader: SpreaderBLEManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pilih alat yang ingin dihubungkan").font(.headline)
            VStack(spacing: 10) {
                ForEach(spreader.discovered) { device in
                    Button {
                        spreader.connect(to: device.id)
                    } label: {
                        row(for: device)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .disabled(spreader.connectingID != nil)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .top)
    }

    private func row(for device: DiscoveredSpreader) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [SpreaderPalette.brandSoft, SpreaderPalette.panel],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 52, height: 52)
                .overlay {
                    // Loose PNG (@2x/@3x) exported from Sketch: Atom / Icon Badge / Spreader.
                    Image(uiImage: UIImage(named: "SpreaderDeviceIcon") ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
            Text(SpreaderFormat.deviceName(device.name))
                .font(.headline)
                .foregroundStyle(SpreaderPalette.ink)
            Spacer()
            if spreader.connectingID == device.id {
                ProgressView()
            } else {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SpreaderPalette.inkTertiary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 76)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Hubungkan ke alat ini")
    }
}
